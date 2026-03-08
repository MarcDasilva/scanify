import SwiftUI
import AudioToolbox

struct NikeScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/nike/scan"
    static let clipName = "Scanify — Nike"
    static let clipDescription = "Scan apparel at Nike for sizing, stock, and checkout."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        NikeScanifyFlowView(
            storeBranding: StoreBranding.forStoreId("nike"),
            allowedCategory: .apparel
        )
    }
}

// MARK: - Nike splash (Hero-style landing: black + swoosh)

private struct NikeSplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay {
                NikeSwooshShape()
                    .fill(Color.white)
                    .frame(width: 120, height: 44)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

// MARK: - Nike swoosh (simplified Path)

private struct NikeSwooshShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.02, y: h * 0.72))
        p.addCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.08),
            control1: CGPoint(x: w * 0.18, y: h * 0.95),
            control2: CGPoint(x: w * 0.45, y: h * 0.35)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.98, y: h * 0.28),
            control1: CGPoint(x: w * 0.82, y: h * 0.02),
            control2: CGPoint(x: w * 0.95, y: h * 0.18)
        )
        p.addLine(to: CGPoint(x: w * 0.92, y: h * 0.38))
        p.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.88),
            control1: CGPoint(x: w * 0.78, y: h * 0.22),
            control2: CGPoint(x: w * 0.62, y: h * 0.65)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Nike loading (white Shop screen with spinner)

private struct NikeLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    NikeSwooshShape()
                        .fill(Color.black)
                        .frame(width: 24, height: 9)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .overlay(Image(systemName: "figure.run").font(.system(size: 14)).foregroundStyle(.black))
                        .frame(width: 44, height: 32)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(0.15), lineWidth: 1))
                Spacer()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            HStack {
                Text("Shop")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(.black)
            Spacer()

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "house")
                        .font(.system(size: 20, weight: .medium))
                    Text("Home").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color(white: 0.6))
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                    Text("Shop").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 20, weight: .medium))
                    Text("Favorites").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color(white: 0.6))
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Image(systemName: "bag")
                        .font(.system(size: 20, weight: .medium))
                    Text("Bag").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color(white: 0.6))
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 20, weight: .medium))
                    Text("Profile").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color(white: 0.6))
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}

// MARK: - Nike scanner overlay (full-screen, centered logo, corner brackets)

private struct NikeScannerOverlay: View {
    var body: some View {
        ZStack {
            // Subtle dark tint over camera
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Full-screen corner brackets
            GeometryReader { geo in
                let inset: CGFloat = 28
                let len: CGFloat = 44
                let thick: CGFloat = 3.5
                let color = Color.white

                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: inset, y: inset + len))
                    p.addLine(to: CGPoint(x: inset, y: inset))
                    p.addLine(to: CGPoint(x: inset + len, y: inset))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thick, lineCap: .round, lineJoin: .round))

                // Top-right
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width - inset - len, y: inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: inset + len))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thick, lineCap: .round, lineJoin: .round))

                // Bottom-left
                Path { p in
                    p.move(to: CGPoint(x: inset, y: geo.size.height - inset - len))
                    p.addLine(to: CGPoint(x: inset, y: geo.size.height - inset))
                    p.addLine(to: CGPoint(x: inset + len, y: geo.size.height - inset))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thick, lineCap: .round, lineJoin: .round))

                // Bottom-right
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width - inset - len, y: geo.size.height - inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: geo.size.height - inset))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: geo.size.height - inset - len))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thick, lineCap: .round, lineJoin: .round))
            }
            .ignoresSafeArea()

            // Crosshair in center
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundStyle(Color.white.opacity(0.75))

            // Top: centered Nike logo
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    NikeSwooshShape()
                        .fill(Color.white)
                        .frame(width: 96, height: 35)
                    Text("NIKE")
                        .font(.system(size: 38, weight: .black))
                        .tracking(4)
                        .foregroundStyle(.white)
                }
                .padding(.top, 64)
                Spacer()

                // Bottom hint
                Text("Point at a barcode to scan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Bag item for Nike flow

struct NikeBagItem: Identifiable {
    let id = UUID()
    let product: ScannedProduct
    var size: String
    var colorName: String
    var quantity: Int
    var price: Double { product.price * Double(quantity) }
}

// MARK: - Nike flow (scanner → product page → Bag → checkout)

private struct NikeScanifyFlowView: View {
    let storeBranding: StoreBranding
    var allowedCategory: ProductCategory?

    @State private var scannedProduct: ScannedProduct?
    @State private var bagItems: [NikeBagItem] = []
    @State private var showBag = false
    @State private var showCheckout = false
    @State private var showSuccess = false
    @State private var showProductNotFound = false
    @State private var showNikeSplash = false
    @State private var showNikeLoading = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []
    @Namespace private var heroNamespace

    private var demoProducts: [ScannedProduct] {
        ScanifyMockData.products(for: storeBranding.storeId)
            .filter { storeBranding.storeId != "nike" || $0.name.contains("P-6000") }
    }

    var body: some View {
        ZStack {
            if showSuccess {
                successView
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(3)
            } else if showNikeSplash {
                NikeSplashView()
                    .transition(.opacity)
                    .zIndex(2)
            } else if showNikeLoading {
                NikeLoadingView()
                    .transition(.opacity)
                    .zIndex(2)
            } else if showCheckout {
                NikeCheckoutView(
                    items: bagItems,
                    onPlaceOrder: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            showCheckout = false
                            showBag = false
                        }
                        bagItems.removeAll()
                        scannedProduct = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(duration: 0.4)) { showSuccess = true }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSuccess = false }
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showCheckout = false }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            } else if showBag && !bagItems.isEmpty {
                NikeBagView(
                    items: bagItems,
                    onCheckout: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showCheckout = true }
                    },
                    onBackToProduct: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = false }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(1)
            } else if let product = scannedProduct {
                NikeProductPageView(
                    product: product,
                    storeBranding: storeBranding,
                    heroNamespace: heroNamespace,
                    onBack: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { scannedProduct = nil } },
                    onAddToBag: { item in
                        bagItems.append(item)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = true }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1)
            }

            // Scanner (with hero source when transitioning)
            ZStack {
                ScanifyBarcodeScannerView(
                    onBarcodeScanned: { handleBarcode($0) },
                    isActive: scannedProduct == nil && !showBag && !showSuccess && !showProductNotFound && !showNikeSplash && !showNikeLoading
                )
                .ignoresSafeArea()

                NikeScannerOverlay()
                    .ignoresSafeArea()

                if !scanHistory.isEmpty {
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(scanHistory) { product in
                                    Button { scannedProduct = product } label: {
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
                        Spacer()
                    }
                }

                Spacer().frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 8) {
                    Text("Demo Products")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(demoProducts) { product in
                                Button { handleBarcode(product.barcode) } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: storeBranding.icon)
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

                if let product = scannedProduct, case .apparel = product.categoryData {
                    Group {
                        if product.name.contains("P-6000") {
                            Image("NIKEP-6000")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.black.opacity(0.35))
                        }
                    }
                    .frame(width: 120, height: 120)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 16))
                    .matchedGeometryEffect(id: "product-hero-\(product.id)", in: heroNamespace)
                }
            }
            .zIndex(0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: scannedProduct?.id)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showBag)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showCheckout)
        .animation(.easeOut(duration: 0.22), value: showNikeSplash)
        .animation(.easeOut(duration: 0.22), value: showNikeLoading)
        .alert("Product Not Found", isPresented: $showProductNotFound) {
            Button("Scan Again", role: .cancel) {}
        } message: {
            Text(productNotFoundMessage)
        }
    }

    private var productNotFoundMessage: String {
        if lastUnknownBarcode.isEmpty { return "" }
        if allowedCategory != nil {
            return "This product isn't available at \(storeBranding.displayName). Try one of the sample products below."
        }
        return "Barcode \(lastUnknownBarcode) is not in our demo database. Try one of the sample products."
    }

    private func handleBarcode(_ barcode: String) {
        guard let product = ScanifyMockData.lookup(barcode: barcode) else {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        if let allowed = allowedCategory, product.category != allowed {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        AudioServicesPlaySystemSound(1057)
        scanHistory.removeAll { $0.barcode == product.barcode }
        scanHistory.insert(product, at: 0)
        if scanHistory.count > 5 { scanHistory = Array(scanHistory.prefix(5)) }
        showNikeSplash = true
        let productToShow = product
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.easeOut(duration: 0.2)) {
                showNikeSplash = false
                showNikeLoading = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showNikeLoading = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        scannedProduct = productToShow
                    }
                }
            }
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

// MARK: - Nike Product Page (full-screen PDP with hero transition)

private struct NikeProductPageView: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    var heroNamespace: Namespace.ID
    let onBack: () -> Void
    let onAddToBag: (NikeBagItem) -> Void

    @State private var selectedSize: String?
    @State private var selectedColor: ColorVariant?
    @State private var showSizeSheet = false
    @State private var heroPage = 0

    private var apparelData: ApparelData? {
        guard case .apparel(let data) = product.categoryData else { return nil }
        return data
    }

    private var categoryLabel: String {
        product.name.contains("P-6000") ? "Older Kids' Shoes" : "Men's Workout Shoes"
    }

    private var priceText: String {
        "CA$\(Int(product.price))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImageSection
                VStack(alignment: .leading, spacing: 16) {
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                    Text(categoryLabel)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.45))

                    Text(priceText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)

                    // Select Size + Size Guide (Nike white style)
                    HStack {
                        Text("Select Size")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                        Spacer()
                        Button { } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "ruler")
                                    .font(.system(size: 12))
                                Text("Size Guide")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.black)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if let data = apparelData {
                                ForEach(data.sizes) { item in
                                    sizeChip(size: item.size, inStock: item.inStock > 0, selected: selectedSize == item.size) {
                                        selectedSize = item.size
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        addToBag()
                    } label: {
                        Text("Add to Bag")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedSize == nil)

                    Button { } label: {
                        HStack {
                            Text("Favorite")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "heart")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    if let data = apparelData {
                        colorSection(data: data)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.white)
        .overlay(alignment: .topLeading) { topBar }
        .overlay(alignment: .bottom) { nikeBottomNav(active: .shop) }
        .onAppear { setDefaults() }
        .sheet(isPresented: $showSizeSheet) {
            if let data = apparelData {
                NikeSizeSheet(
                    product: product,
                    data: data,
                    selectedSize: $selectedSize,
                    onAddToBag: {
                        showSizeSheet = false
                        addToBag()
                    }
                )
            }
        }
    }

    private static let nikeP6000Images = ["NIKEP-6000", "NIKEP-60001", "NIKEP-60002", "NIKEP-60003", "NIKEP-60004"]

    private var heroImages: [String] {
        product.name.contains("P-6000") ? Self.nikeP6000Images : []
    }

    private var heroImageSection: some View {
        ZStack(alignment: .bottom) {
            if heroImages.isEmpty {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(white: 0.96))
                    .overlay(
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.black.opacity(0.12))
                    )
                    .frame(height: 380)
                    .frame(maxWidth: .infinity)
                    .matchedGeometryEffect(id: "product-hero-\(product.id)", in: heroNamespace)
            } else {
                TabView(selection: $heroPage) {
                    ForEach(Array(heroImages.enumerated()), id: \.offset) { index, name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.96))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.96))
                .matchedGeometryEffect(id: "product-hero-\(product.id)", in: heroNamespace)
            }

            HStack(spacing: 6) {
                ForEach(0..<(heroImages.isEmpty ? 3 : heroImages.count), id: \.self) { i in
                    Circle()
                        .fill(i == heroPage ? Color.black : Color.black.opacity(0.2))
                        .frame(width: i == heroPage ? 8 : 6, height: 6)
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.top, 8)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(product.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
            Spacer()
            HStack(spacing: 20) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.black)
                }
                Button { } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
            .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .background(Color.white)
    }

    private func sizeChip(size: String, inStock: Bool, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(size)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(inStock ? (selected ? .white : .black) : Color(white: 0.7))
        }
        .disabled(!inStock)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            inStock && selected ? Color.black : Color.white,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .buttonStyle(.plain)
    }

    private enum NikeTab { case home, shop, favorites, bag, profile }
    private func nikeBottomNav(active: NikeTab) -> some View {
        HStack(spacing: 0) {
            navItem(icon: "house", label: "Home", isActive: active == .home)
            navItem(icon: "magnifyingglass", label: "Shop", isActive: active == .shop)
            navItem(icon: "heart", label: "Favorites", isActive: active == .favorites)
            navItem(icon: "bag", label: "Bag", isActive: active == .bag)
            navItem(icon: "person", label: "Profile", isActive: active == .profile)
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(Color.white)
    }

    private func navItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(isActive ? .black : Color(white: 0.6))
        .frame(maxWidth: .infinity)
    }

    private func colorSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            HStack(spacing: 16) {
                ForEach(data.colors) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(scanifyHex: color.hex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().strokeBorder(selectedColor?.id == color.id ? Color.black : Color.black.opacity(0.2), lineWidth: selectedColor?.id == color.id ? 2 : 1))
                            Text(color.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(white: 0.45))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func setDefaults() {
        guard let data = apparelData else { return }
        if selectedColor == nil, let first = data.colors.first {
            selectedColor = first
        }
        if selectedSize == nil {
            selectedSize = data.sizes.first(where: { $0.size == "US 2Y" })?.size
                ?? data.sizes.first(where: { $0.size == "US 9" })?.size
                ?? data.sizes.first(where: { $0.inStock > 0 })?.size
        }
    }

    private func addToBag() {
        guard let size = selectedSize else { return }
        let colorName = selectedColor?.name ?? apparelData?.colors.first?.name ?? "—"
        onAddToBag(NikeBagItem(product: product, size: size, colorName: colorName, quantity: 1))
    }
}

// MARK: - Size sheet

private struct NikeSizeSheet: View {
    let product: ScannedProduct
    let data: ApparelData
    @Binding var selectedSize: String?
    let onAddToBag: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Group {
                        if product.name.contains("P-6000") {
                            Image("NIKEP-6000")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 72, height: 72)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.brand)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(product.name)
                            .font(.system(size: 17, weight: .bold))
                        Text("\(product.currency) \(String(format: "%.2f", product.price))")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Select Size")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button("Size Guide") { }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(data.sizes) { item in
                            sizeButton(item)
                        }
                    }
                    HStack(spacing: 16) {
                        HStack(spacing: 4) { Circle().fill(.green).frame(width: 6, height: 6); Text("In Stock") }
                        HStack(spacing: 4) { Circle().fill(.yellow).frame(width: 6, height: 6); Text("Low Stock") }
                        HStack(spacing: 4) { Circle().fill(.red).frame(width: 6, height: 6); Text("Unavailable") }
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 24)

                Button {
                    onAddToBag()
                } label: {
                    Text("Add to Bag")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(selectedSize == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Size & Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sizeButton(_ item: SizeInventory) -> some View {
        let isSelected = selectedSize == item.size
        let isOut = item.stockStatus == .outOfStock
        return Button {
            guard !isOut else { return }
            selectedSize = item.size
        } label: {
            VStack(spacing: 4) {
                Text(item.size)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isOut ? .secondary : (isSelected ? .white : .primary))
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.stockStatus.color)
                        .frame(width: 6, height: 6)
                    Text(item.inStock == 0 ? "Out" : "\(item.inStock) left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.black : (isOut ? Color.clear : Color(.secondarySystemFill)),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .disabled(isOut)
    }
}

// MARK: - Nike Bag View (Nike branded white style)

private struct NikeBagView: View {
    let items: [NikeBagItem]
    let onCheckout: () -> Void
    let onBackToProduct: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        Button(action: onBackToProduct) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                        }
                        Text("Bag")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                    }
                    .padding(.top, 8)

                    ForEach(items) { item in
                        bagProductCard(item)
                    }

                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 1)

                    HStack {
                        Text("Subtotal")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                        Spacer()
                        Text(String(format: "CA$%.2f", itemSubtotal))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                    }
                    HStack {
                        Text("Shipping")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                        Spacer()
                        Text("CA$10.95")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                    }
                    HStack {
                        Text("Estimated Total")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                        Text(String(format: "CA$%.2f", itemSubtotal + 10.95))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    Text("(Import taxes added at checkout)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(white: 0.5))
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.white)

            Button(action: onCheckout) {
                Text("Checkout")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            HStack(spacing: 0) {
                bagNavItem(icon: "house", label: "Home")
                bagNavItem(icon: "magnifyingglass", label: "Shop")
                bagNavItem(icon: "heart", label: "Favorites")
                ZStack(alignment: .topTrailing) {
                    bagNavItem(icon: "bag.fill", label: "Bag", active: true)
                    Text("\(items.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.red, in: Circle())
                        .offset(x: 12, y: -6)
                }
                bagNavItem(icon: "person", label: "Profile")
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(Color.white)
        }
        .background(Color.white)
    }

    private var itemSubtotal: Double {
        items.reduce(0) { $0 + $1.price }
    }

    private func bagProductCard(_ item: NikeBagItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if item.product.name.contains("P-6000") {
                    Image("NIKEP-6000")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(white: 0.7))
                        .frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
            .background(Color(white: 0.94), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                Text(productCategoryLabel(item.product))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
                Text(item.colorName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
                Text(sizeLabel(item))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
                Text("Just a few left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
                HStack {
                    Text("Qty \(item.quantity)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(white: 0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: "CA$%.2f", item.price))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
    }

    private func bagNavItem(icon: String, label: String, active: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(active ? .black : Color(white: 0.6))
        .frame(maxWidth: .infinity)
    }

    private func productCategoryLabel(_ product: ScannedProduct) -> String {
        product.name.contains("P-6000") ? "Older Kids' Shoes" : "Men's Workout Shoes"
    }

    private func sizeLabel(_ item: NikeBagItem) -> String {
        if item.size.hasPrefix("US ") {
            let rest = String(item.size.dropFirst(3))
            if rest.hasSuffix("Y") { return rest }
            if let n = Double(rest) { return "M \(rest) / W \(n + 1.5)" }
        }
        return item.size
    }
}

// MARK: - Nike Checkout View (Wealthsimple-inspired)

private struct NikeCheckoutView: View {
    let items: [NikeBagItem]
    let onPlaceOrder: () -> Void
    let onBack: () -> Void

    @State private var selectedShipping = 0
    @State private var summaryExpanded = false

    private let freeShippingThreshold = 190.0
    private let shippingOptions: [(date: String, price: Double)] = [
        ("Thu, Mar 12 – Wed, Mar 18", 10.95),
        ("Tue, Mar 10 – Wed, Mar 12", 40.00),
    ]

    var subtotal: Double { items.reduce(0) { $0 + $1.price } }
    var shippingCost: Double { shippingOptions[selectedShipping].price }
    var total: Double { subtotal + shippingCost }
    var toFreeShipping: Double { max(freeShippingThreshold - subtotal, 0) }
    var freeShippingProgress: Double { min(subtotal / freeShippingThreshold, 1.0) }

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text("Checkout")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 4)
            .background(Color.white)

            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Summary header
                    HStack(alignment: .center) {
                        Text("Summary")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                summaryExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(String(format: "CA$%.2f (%d item%@)", total, items.count, items.count == 1 ? "" : "s"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.black)
                                Image(systemName: summaryExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                    if summaryExpanded {
                        ForEach(items) { item in summaryItemRow(item) }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Free shipping progress
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            if toFreeShipping > 0 {
                                Text("Add **CA$\(String(format: "%.2f", toFreeShipping))** more to earn Free Shipping!")
                            } else {
                                Text("You've earned **Free Shipping!**")
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(.black)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(white: 0.88))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * freeShippingProgress, height: 8)
                                    .animation(.spring(response: 0.6), value: freeShippingProgress)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Spacer()
                            Text("CA$\(String(format: "%.2f", freeShippingThreshold))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    checkoutDivider

                    // Delivery
                    sectionHeader(title: "Delivery") {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Aidan Jeon").font(.system(size: 15, weight: .medium))
                            Text("#107-15388 101 Ave").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("Surrey, BC  V3R 0N4").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("aidanjeon07@gmail.com").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("(236) 668-4714").font(.system(size: 15)).foregroundStyle(.secondary)
                        }
                    }

                    checkoutDivider

                    // Billing
                    sectionHeader(title: "Billing") {
                        Text("Same as delivery")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    checkoutDivider

                    // Shipping options
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Shipping")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)

                        ForEach(shippingOptions.indices, id: \.self) { i in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { selectedShipping = i }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1.5)
                                            .frame(width: 20, height: 20)
                                        if selectedShipping == i {
                                            Circle().fill(Color.black).frame(width: 11, height: 11)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Arrives \(shippingOptions[i].date)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.black)
                                    }
                                    Spacer()
                                    Text(String(format: "CA$%.2f", shippingOptions[i].price))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.black)
                                }
                                .padding(16)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedShipping == i ? Color.black : Color.black.opacity(0.15),
                                                lineWidth: selectedShipping == i ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    checkoutDivider

                    // Payment
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Payment")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.black)

                        // Apple Pay
                        HStack(spacing: 6) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Pay")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))

                        // Card option
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(white: 0.5))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("VISA •••• 4242")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.black)
                                Text("Expires 12/26")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    checkoutDivider

                    // Price breakdown
                    VStack(spacing: 10) {
                        priceRow("Subtotal", String(format: "CA$%.2f", subtotal))
                        priceRow("Shipping", String(format: "CA$%.2f", shippingCost))
                        priceRow("Taxes", "Calculated at checkout")
                        Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
                        HStack {
                            Text("Estimated Total")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                            Spacer()
                            Text(String(format: "CA$%.2f", total))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        Text("(Import taxes added at checkout)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 32)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.white)

            // Place Order
            VStack(spacing: 0) {
                Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
                Button(action: onPlaceOrder) {
                    Text("Place Order")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 30))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
                .background(Color.white)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }

    private var checkoutDivider: some View {
        Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)
    }

    private func summaryItemRow(_ item: NikeBagItem) -> some View {
        HStack(spacing: 12) {
            Image("NIKEP-6000")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .background(Color(white: 0.95), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                Text("\(item.size)  ·  \(item.colorName)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(String(format: "CA$%.2f", item.price))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func sectionHeader(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.25), lineWidth: 1))
            }
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    private func priceRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)
        }
    }
}
