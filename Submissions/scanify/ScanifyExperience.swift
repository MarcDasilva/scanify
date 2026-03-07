import SwiftUI
import AudioToolbox
import AVFoundation

struct ScanifyExperience: ClipExperience {
    static let urlPattern = "scanify.app/store/:storeId/scan"
    static let clipName = "Scanify"
    static let clipDescription = "Scan any product barcode for instant details, sizing, nutrition, AR try-on, specs & more."
    static let teamName = "Scanify"

    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    @State private var scannedProduct: ScannedProduct?
    @State private var showSuccess = false
    @State private var showUnknownBarcode = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []

    private var storeBranding: StoreBranding {
        let storeId = context.pathParameters["storeId"] ?? "store"
        return StoreBranding.forStoreId(storeId)
    }

    var body: some View {
        ZStack {
            if showSuccess {
                successView
                    .transition(.scale.combined(with: .opacity))
            } else {
                cameraScanner
            }
        }
        .animation(.spring(duration: 0.35), value: showSuccess)
        .sheet(item: $scannedProduct) { product in
            ScanifyExperienceSheet(
                product: product,
                storeBranding: storeBranding,
                onDismiss: { scannedProduct = nil },
                onOrderComplete: {
                    scannedProduct = nil
                    withAnimation(.spring(duration: 0.4)) {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showSuccess = false }
                    }
                }
            )
        }
        .alert("Product Not Found", isPresented: $showUnknownBarcode) {
            Button("Scan Again", role: .cancel) {}
        } message: {
            Text("Barcode \(lastUnknownBarcode) is not in our demo database. Try one of the sample products.")
        }
    }

    // MARK: - Camera Scanner

    private var cameraScanner: some View {
        ZStack {
            ScanifyBarcodeScannerView(
                onBarcodeScanned: { barcode in handleBarcode(barcode) },
                isActive: scannedProduct == nil && !showSuccess && !showUnknownBarcode
            )
            .ignoresSafeArea()

            ScannerOverlayView(storeBranding: storeBranding)
                .ignoresSafeArea()

            // Scan history + demo pills
            VStack {
                // Scan history strip
                if !scanHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(scanHistory) { product in
                                Button {
                                    scannedProduct = product
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon)
                                            .font(.system(size: 10))
                                            .foregroundStyle(product.category.accentColor)
                                        Text(product.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.15), in: .capsule)
                                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Demo product pills
                VStack(spacing: 8) {
                    Text("Demo Products")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ScanifyMockData.allProducts) { product in
                                Button {
                                    handleBarcode(product.barcode)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon)
                                            .font(.system(size: 11))
                                        Text(product.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .glassEffect(.regular.interactive(), in: .capsule)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Barcode Handler

    private func handleBarcode(_ barcode: String) {
        if let product = ScanifyMockData.lookup(barcode: barcode) {
            // Play scan chime
            AudioServicesPlaySystemSound(1057)

            scannedProduct = product

            // Add to history (avoid duplicates, max 5)
            withAnimation(.spring(duration: 0.3)) {
                scanHistory.removeAll { $0.barcode == product.barcode }
                scanHistory.insert(product, at: 0)
                if scanHistory.count > 5 {
                    scanHistory = Array(scanHistory.prefix(5))
                }
            }
        } else {
            lastUnknownBarcode = barcode
            showUnknownBarcode = true
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            ClipSuccessOverlay(message: "Order placed!\nShipping to your address in 2-3 business days.")
            Spacer()
        }
    }
}

// MARK: - Experience Sheet (handles checkout internally)

struct ScanifyExperienceSheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
    @State private var showShareSheet = false

    private var shareText: String {
        switch product.categoryData {
        case .food(let data):
            let allergens = data.allergens.isEmpty ? "None" : data.allergens.map(\.rawValue).joined(separator: ", ")
            return "Scanify Report: \(product.name) by \(product.brand)\nAllergens: \(allergens)\nCalories: \(data.calories) per serving"
        case .pharmacy(let data):
            let treats = data.treats.joined(separator: ", ")
            return "Scanify Report: \(product.name) by \(product.brand)\nTreats: \(treats)\nDosage: \(data.dosage)"
        case .electronics(let data):
            return "Scanify Report: \(product.name) by \(product.brand)\nWarranty: \(data.warranty.months)-month \(data.warranty.type)\nPrice: $\(String(format: "%.2f", product.price))"
        default:
            return "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch product.categoryData {
                case .apparel(let data):
                    ScanifyInventoryView(product: product, data: data, accentColor: storeBranding.accentColor) { size in
                        checkoutVariant = "Size \(size)"
                        showCheckout = true
                    }
                case .food(let data):
                    ScanifyNutritionView(product: product, data: data, accentColor: storeBranding.accentColor)
                case .pharmacy(let data):
                    ScanifyMedicineView(product: product, data: data, accentColor: storeBranding.accentColor)
                case .cosmetics(let data):
                    ScanifyCosmeticsView(product: product, data: data) { shade in
                        checkoutVariant = shade
                        showCheckout = true
                    }
                case .electronics(let data):
                    ScanifyElectronicsView(product: product, data: data, accentColor: storeBranding.accentColor)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showCheckout) {
            ScanifyCheckoutView(
                product: product,
                variant: checkoutVariant,
                accentColor: storeBranding.accentColor,
                onComplete: {
                    showCheckout = false
                    onOrderComplete()
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ScanifyShareSheet(items: [shareText])
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Share Sheet

struct ScanifyShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Scanify Background

struct ScanifyBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            LinearGradient(
                colors: [
                    Color(scanifyHex: "#4A90D9").opacity(0.15),
                    Color(scanifyHex: "#7B68EE").opacity(0.1),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}
