//  StoreCheckoutExperience.swift
//  ReactivChallengeKit
//
//  Store checkout: scan barcode → hero transition → Nike-style product page
//  with size/color, availability, deliver or pick up at cashier.

import SwiftUI

struct StoreCheckoutExperience: ClipExperience {
    static let urlPattern = "scanify.app/store/scan"
    static let clipName = "Store Checkout — Scan & Buy"
    static let clipDescription = "Scan a product barcode, then view availability and checkout with delivery or pickup."
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        StoreCheckoutFlowView()
    }
}

// MARK: - Flow: Scanner ↔ Product Page (Hero-style transition)

private struct StoreCheckoutFlowView: View {
    @State private var scannedProduct: ScannedProduct?
    @State private var showProductNotFound = false
    @State private var lastUnknownBarcode = ""
    @Namespace private var heroNamespace

    private let storeBranding = StoreBranding.forStoreId("nike")
    private var demoProducts: [ScannedProduct] {
        ScanifyMockData.products(for: storeBranding.storeId)
    }

    var body: some View {
        ZStack {
            if let product = scannedProduct {
                // Full-screen product page (destination of hero transition)
                NikeStyleProductPageView(
                    product: product,
                    storeBranding: storeBranding,
                    heroNamespace: heroNamespace,
                    onBack: { withAnimation(.spring(duration: 0.4)) { scannedProduct = nil } }
                )
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))
                .zIndex(1)
            }

            // Scanner (with hero source when transitioning)
            ZStack {
                ScanifyBarcodeScannerView(
                    onBarcodeScanned: { handleBarcode($0) },
                    isActive: scannedProduct == nil && !showProductNotFound
                )
                .ignoresSafeArea()

                StoreCheckoutScannerOverlay(
                    storeBranding: storeBranding,
                    demoProducts: demoProducts,
                    onDemoProduct: { handleBarcode($0.barcode) }
                )
                .ignoresSafeArea()

                // Hero source: small product image that morphs into PDP hero (stays in tree for transition)
                if let product = scannedProduct {
                    heroSourceView(product: product)
                }
            }
            .zIndex(0)
        }
        .animation(.spring(duration: 0.5), value: scannedProduct?.id)
        .alert("Product Not Found", isPresented: $showProductNotFound) {
            Button("Scan Again", role: .cancel) {}
        } message: {
            Text(lastUnknownBarcode.isEmpty ? "" : "Barcode \"\(lastUnknownBarcode)\" isn’t in the demo. Try a demo product below.")
        }
    }

    private func heroSourceView(product: ScannedProduct) -> some View {
        let heroId = "product-hero-\(product.id)"
        return Group {
            if case .apparel = product.categoryData {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(storeBranding.accentColor.opacity(0.8))
                    )
                    .frame(width: 120, height: 120)
                    .matchedGeometryEffect(id: heroId, in: heroNamespace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleBarcode(_ barcode: String) {
        guard let product = ScanifyMockData.lookup(barcode: barcode) else {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        guard product.category == .apparel else {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        withAnimation(.spring(duration: 0.5)) {
            scannedProduct = product
        }
    }
}

// MARK: - Scanner Overlay

private struct StoreCheckoutScannerOverlay: View {
    let storeBranding: StoreBranding
    let demoProducts: [ScannedProduct]
    let onDemoProduct: (ScannedProduct) -> Void

    @State private var animateScanLine = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(storeBranding.accentColor.opacity(0.6), lineWidth: 2)
                        )
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [.clear, storeBranding.accentColor, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240, height: 2)
                        .offset(y: animateScanLine ? 120 : -120)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateScanLine)
                }

                Spacer()

                Text("Point at a barcode to scan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)

                Text("Demo products")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(demoProducts) { product in
                            Button { onDemoProduct(product) } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: storeBranding.icon)
                                        .font(.system(size: 11))
                                    Text(product.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { animateScanLine = true }
    }
}
