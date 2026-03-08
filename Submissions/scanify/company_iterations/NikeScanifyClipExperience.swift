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
                Image("nike_swoosh")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 130, height: 48)
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
                ForEach([("magnifyingglass", "Shop", true), ("heart", "Favorites", false), ("bag", "Bag", false), ("person", "Profile", false)], id: \.1) { icon, label, active in
                    VStack(spacing: 4) {
                        Image(systemName: icon).font(.system(size: 20, weight: .medium))
                        Text(label).font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(active ? Color.black : Color(white: 0.6))
                    .frame(maxWidth: .infinity)
                }
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

            // Full-screen corner brackets (within safe area so they don't overlap status bar)
            GeometryReader { geo in
                let inset: CGFloat = 20
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
            // No .ignoresSafeArea() — coordinates respect safe area so corners stay below status bar

            // Crosshair in center
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundStyle(Color.white.opacity(0.75))

            // Top: centered Nike logo
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image("nike_swoosh")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 110, height: 40)
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

// MARK: - Shared nav tab

private enum NikeTab { case shop, favorites, bag, profile }

private struct NikeSharedBottomBar: View {
    let active: NikeTab
    let bagCount: Int
    let hasFavorites: Bool
    let onShop: () -> Void
    let onFavorites: () -> Void
    let onBag: () -> Void
    let onProfile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.black.opacity(0.1)).frame(height: 0.5)
            HStack(spacing: 0) {
                Button(action: onShop) {
                    barItem(icon: "magnifyingglass", label: "Shop", isActive: active == .shop)
                }.buttonStyle(.plain)

                Button(action: onFavorites) {
                    barItem(
                        icon: hasFavorites ? "heart.fill" : "heart",
                        label: "Favorites",
                        isActive: active == .favorites,
                        tint: hasFavorites ? Color.red : nil
                    )
                }.buttonStyle(.plain)

                Button(action: onBag) {
                    ZStack(alignment: .topTrailing) {
                        barItem(icon: active == .bag ? "bag.fill" : "bag", label: "Bag", isActive: active == .bag)
                        if bagCount > 0 {
                            Text("\(bagCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 15, minHeight: 15)
                                .background(Color.red, in: Circle())
                                .offset(x: 2, y: -2)
                        }
                    }
                }.buttonStyle(.plain)

                Button(action: onProfile) {
                    barItem(icon: active == .profile ? "person.fill" : "person", label: "Profile", isActive: active == .profile)
                }.buttonStyle(.plain)
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(Color.white)
        }
        .background(Color.white)
    }

    private func barItem(icon: String, label: String, isActive: Bool, tint: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 20, weight: .medium))
            Text(label).font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(tint ?? (isActive ? Color.black : Color(white: 0.6)))
        .frame(maxWidth: .infinity)
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
    @State private var favoritedProducts: [ScannedProduct] = []
    @State private var showBag = false
    @State private var showFavorites = false
    @State private var showProfile = false
    @State private var showCheckout = false
    @State private var showSuccess = false
    @State private var showProductNotFound = false
    @State private var showNikeSplash = false
    @State private var showNikeLoading = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []

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
            } else if showProfile {
                NikeProfileView(
                    bagCount: bagItems.count,
                    hasFavorites: !favoritedProducts.isEmpty,
                    favoritedProducts: favoritedProducts,
                    onViewShop: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showProfile = false } },
                    onViewFavorites: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showProfile = false; showFavorites = true } },
                    onViewBag: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showProfile = false; showBag = true } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            } else if showFavorites {
                NikeFavoritesView(
                    favoritedProducts: favoritedProducts,
                    bagCount: bagItems.count,
                    onRemoveFavorite: { p in withAnimation { favoritedProducts.removeAll { $0.id == p.id } } },
                    onViewProduct: { p in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            showFavorites = false
                            scannedProduct = p
                        }
                    },
                    onViewShop: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showFavorites = false } },
                    onViewBag: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showFavorites = false; showBag = true } },
                    onViewProfile: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showFavorites = false; showProfile = true } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            } else if showBag {
                NikeBagView(
                    items: bagItems,
                    hasFavorites: !favoritedProducts.isEmpty,
                    onCheckout: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showCheckout = true }
                    },
                    onViewShop: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = false } },
                    onViewFavorites: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = false; showFavorites = true } },
                    onViewProfile: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = false; showProfile = true } }
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
                    isFavorited: favoritedProducts.contains(where: { $0.id == product.id }),
                    onBack: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { scannedProduct = nil } },
                    onAddToBag: { item in
                        bagItems.append(item)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = true }
                    },
                    onViewBag: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showBag = true } },
                    onToggleFavorite: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                            if favoritedProducts.contains(where: { $0.id == product.id }) {
                                favoritedProducts.removeAll { $0.id == product.id }
                            } else {
                                favoritedProducts.append(product)
                            }
                        }
                    },
                    onViewFavorites: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showFavorites = true } },
                    onViewProfile: { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { showProfile = true } }
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
                    isActive: scannedProduct == nil && !showBag && !showFavorites && !showProfile && !showSuccess && !showProductNotFound && !showNikeSplash && !showNikeLoading
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

                if storeBranding.storeId != "nike" {
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
                }

            }
            .zIndex(0)
        }
        .animation(.spring(response: 0.75, dampingFraction: 0.85), value: scannedProduct?.id)
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
                    withAnimation(.spring(duration: 0.75, bounce: 0.18)) {
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
    let isFavorited: Bool
    let onBack: () -> Void
    let onAddToBag: (NikeBagItem) -> Void
    let onViewBag: () -> Void
    let onToggleFavorite: () -> Void
    let onViewFavorites: () -> Void
    let onViewProfile: () -> Void

    @State private var selectedSize: String?
    @State private var selectedColor: ColorVariant?
    @State private var showSizeSheet = false
    @State private var heroPage = 0
    @State private var shipFromStore: (name: String, address: String, distance: String)?

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
                                    sizeChip(
                                        size: item.size,
                                        inStock: item.inStock > 0,
                                        stockCount: item.inStock,
                                        selected: selectedSize == item.size
                                    ) { selectedSize = item.size }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Stock indicator for selected size
                    if let data = apparelData, let sel = selectedSize,
                       let item = data.sizes.first(where: { $0.size == sel }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.inStock == 0 ? Color.red : item.stockStatus.color)
                                .frame(width: 7, height: 7)
                            Text(item.inStock == 0 ? "Out of stock at this location — ship from a nearby store" : item.inStock <= 3 ? "Only \(item.inStock) left in store" : "\(item.inStock) in stock at this location")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(item.inStock == 0 ? Color.red : item.inStock <= 3 ? Color.orange : Color(white: 0.35))
                        }
                    }

                    Button {
                        addToBag()
                    } label: {
                        Text("Ship to Me")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedSize == nil || (apparelData?.sizes.first(where: { $0.size == selectedSize })?.inStock ?? 1) == 0)

                    Button(action: onToggleFavorite) {
                        HStack {
                            Text(isFavorited ? "Favorited" : "Favorite")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isFavorited ? Color.red : Color.black)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isFavorited ? Color.red.opacity(0.4) : Color.black.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    if let data = apparelData {
                        colorSection(data: data)
                        detailsSection(data: data)
                        nearbyStoresSection(selectedSize: selectedSize, data: data)
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
        .overlay(alignment: .bottom) {
            NikeSharedBottomBar(
                active: .shop,
                bagCount: 0,
                hasFavorites: isFavorited,
                onShop: { },
                onFavorites: onViewFavorites,
                onBag: onViewBag,
                onProfile: onViewProfile
            )
        }
        .onAppear { setDefaults() }
        .sheet(item: Binding(
            get: { shipFromStore.map { NikeStoreShipOption(name: $0.name, address: $0.address, distance: $0.distance) } },
            set: { shipFromStore = $0.map { ($0.name, $0.address, $0.distance) } }
        )) { store in
            NikeShipFromStoreSheet(
                store: store,
                product: product,
                selectedSize: selectedSize ?? "",
                onShip: {
                    shipFromStore = nil
                    addToBag()
                }
            )
        }
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
            ShareLink(item: "\(product.name) — \(product.currency)$\(Int(product.price))\nShop Nike at nike.com") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .background(Color.white)
    }

    private func sizeChip(size: String, inStock: Bool, stockCount: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(size)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(selected ? (inStock ? Color.white : Color.black) : (inStock ? Color.black : Color(white: 0.5)))
                if inStock {
                    Text(stockCount <= 3 ? "Low" : "\(stockCount) left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(selected ? Color.white.opacity(0.75) : (stockCount <= 3 ? Color.orange : Color(white: 0.5)))
                } else {
                    Text("Out")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(selected ? Color(white: 0.5) : Color(white: 0.6))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            selected ? (inStock ? Color.black : Color.white) : Color.white,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected && !inStock ? Color.black.opacity(0.4) : Color.black.opacity(0.2), lineWidth: selected && !inStock ? 1.5 : 1)
        )
        .buttonStyle(.plain)
    }

    private func colorSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            HStack(alignment: .top, spacing: 16) {
                ForEach(data.colors) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(scanifyHex: color.hex))
                                .frame(width: 44, height: 44)
                                .overlay(Circle().strokeBorder(selectedColor?.id == color.id ? Color.black : Color.black.opacity(0.2), lineWidth: selectedColor?.id == color.id ? 2 : 1))
                            Text(color.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(white: 0.45))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(height: 30, alignment: .top)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private static let nearbyStores: [(name: String, address: String, distance: String)] = [
        ("Eaton Centre", "220 Yonge St, Toronto, ON", "1.2 km"),
        ("Yorkdale Mall", "3401 Dufferin St, Toronto, ON", "8.4 km"),
        ("Square One", "100 City Centre Dr, Mississauga, ON", "22.1 km"),
    ]

    private func detailsSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            VStack(spacing: 0) {
                detailRow(icon: "arrow.left.and.right.square", label: "Fit", value: data.fit)
                Rectangle().fill(Color.black.opacity(0.07)).frame(height: 0.5).padding(.leading, 44)
                detailRow(icon: "leaf", label: "Material", value: data.material)
            }
            .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.55))
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.45))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func nearbyStoresSection(selectedSize: String?, data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nearby Stores")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            VStack(spacing: 0) {
                ForEach(Array(Self.nearbyStores.enumerated()), id: \.offset) { index, store in
                    let outHere = selectedSize.map { sz in
                        (data.sizes.first(where: { $0.size == sz })?.inStock ?? 0) == 0
                    } ?? false
                    let statusText = selectedSize.map { "Size \($0) available" } ?? "In stock"
                    let row = HStack(spacing: 12) {
                        Image(systemName: "storefront")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(white: 0.55))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)
                            Text(statusText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.green)
                        }
                        Spacer()
                        Text(store.distance)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.5))
                        if outHere {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(white: 0.55))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if outHere {
                        Button {
                            shipFromStore = (store.name, store.address, store.distance)
                        } label: {
                            row
                        }
                        .buttonStyle(.plain)
                    } else {
                        row
                    }

                    if index < Self.nearbyStores.count - 1 {
                        Rectangle().fill(Color.black.opacity(0.07)).frame(height: 0.5).padding(.leading, 50)
                    }
                }
            }
            .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 10))
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
                    .foregroundStyle(isOut ? Color.secondary : (isSelected ? Color.white : Color.primary))
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.stockStatus.color)
                        .frame(width: 6, height: 6)
                    Text(item.inStock == 0 ? "Out" : "\(item.inStock) left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
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

// MARK: - Nike Profile View

private struct NikeProfileView: View {
    let bagCount: Int
    let hasFavorites: Bool
    let favoritedProducts: [ScannedProduct]
    let onViewShop: () -> Void
    let onViewFavorites: () -> Void
    let onViewBag: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 14) {
                        Circle()
                            .fill(Color(white: 0.88))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(white: 0.55))
                            )
                        Text("Aidan Jeon")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)
                        Button { } label: {
                            Text("Edit Profile")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 10)
                                .overlay(Capsule().stroke(Color.black.opacity(0.28), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                    Divider()

                    // 4-grid quicklinks
                    HStack(spacing: 0) {
                        profileGridItem(icon: "shippingbox.fill", label: "Orders")
                        Rectangle().fill(Color.black.opacity(0.1)).frame(width: 0.5, height: 52)
                        profileGridItem(icon: "qrcode", label: "Pass")
                        Rectangle().fill(Color.black.opacity(0.1)).frame(width: 0.5, height: 52)
                        profileGridItem(icon: "calendar", label: "Events")
                        Rectangle().fill(Color.black.opacity(0.1)).frame(width: 0.5, height: 52)
                        profileGridItem(icon: "gearshape.fill", label: "Settings")
                    }
                    .padding(.vertical, 8)

                    Divider()

                    // Inbox
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Inbox")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                            Text("View messages")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(white: 0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider()

                    // Following
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Following (3)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                            Spacer()
                            Text("Edit")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 10) {
                            ForEach(["basketball", "person.2.fill", "figure.run"], id: \.self) { icon in
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(white: 0.92))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 110)
                                    .overlay(
                                        Image(systemName: icon)
                                            .font(.system(size: 26))
                                            .foregroundStyle(Color(white: 0.55))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider()

                    Text("Member Since June 2021")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.white)

            NikeSharedBottomBar(
                active: .profile,
                bagCount: bagCount,
                hasFavorites: hasFavorites,
                onShop: onViewShop,
                onFavorites: onViewFavorites,
                onBag: onViewBag,
                onProfile: { }
            )
        }
        .background(Color.white)
    }

    private func profileGridItem(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.black)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Ship from store helpers

private struct NikeStoreShipOption: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let distance: String
}

private struct NikeShipFromStoreSheet: View {
    let store: NikeStoreShipOption
    let product: ScannedProduct
    let selectedSize: String
    let onShip: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Store header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.95))
                        .frame(width: 52, height: 52)
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(white: 0.45))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                    Text(store.address)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(store.distance + " away")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.green)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Divider()

            // Order summary
            VStack(spacing: 0) {
                summaryRow(label: "Item", value: product.name)
                summaryRow(label: "Size", value: selectedSize)
                summaryRow(label: "Shipping from", value: store.name)
                summaryRow(label: "Ship to", value: "42 Wellington St W, Toronto ON")
                summaryRow(label: "Estimated delivery", value: "3–5 business days")
                summaryRow(label: "Shipping", value: "CA$10.95")
            }
            .padding(.vertical, 8)

            Divider()

            Spacer()

            Button {
                dismiss()
                onShip()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 15))
                    Text("Ship from \(store.name)")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Color.white)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }
}

// MARK: - Nike Favorites View

private struct NikeFavoritesView: View {
    let favoritedProducts: [ScannedProduct]
    let bagCount: Int
    let onRemoveFavorite: (ScannedProduct) -> Void
    let onViewProduct: (ScannedProduct) -> Void
    let onViewShop: () -> Void
    let onViewBag: () -> Void
    let onViewProfile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Favorites")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if favoritedProducts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "heart")
                        .font(.system(size: 52))
                        .foregroundStyle(Color(white: 0.82))
                    Text("No favorites yet")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                    Text("Heart items on the product page to save them here.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(favoritedProducts) { product in
                            favoriteCard(product)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }

            NikeSharedBottomBar(
                active: .favorites,
                bagCount: bagCount,
                hasFavorites: !favoritedProducts.isEmpty,
                onShop: onViewShop,
                onFavorites: { },
                onBag: onViewBag,
                onProfile: onViewProfile
            )
        }
        .background(Color.white)
    }

    private func favoriteCard(_ product: ScannedProduct) -> some View {
        Button(action: { onViewProduct(product) }) {
            HStack(spacing: 14) {
                Group {
                    if product.name.contains("P-6000") {
                        Image("NIKEP-6000").resizable().scaledToFit()
                    } else {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(white: 0.65))
                            .frame(width: 90, height: 90)
                    }
                }
                .frame(width: 90, height: 90)
                .background(Color(white: 0.95), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                    Text(product.name.contains("P-6000") ? "Older Kids' Shoes" : "Men's Workout Shoes")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("CA$\(Int(product.price))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { onRemoveFavorite(product) }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nike Bag View (Nike branded white style)

private struct NikeBagView: View {
    let items: [NikeBagItem]
    let hasFavorites: Bool
    let onCheckout: () -> Void
    let onViewShop: () -> Void
    let onViewFavorites: () -> Void
    let onViewProfile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Bag")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.top, 16)

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

            NikeSharedBottomBar(
                active: .bag,
                bagCount: items.count,
                hasFavorites: hasFavorites,
                onShop: onViewShop,
                onFavorites: onViewFavorites,
                onBag: { },
                onProfile: onViewProfile
            )
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
                            Text("42 Wellington St W, Unit 8").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("Toronto, ON  M5V 1E3").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("aidanjeon07@gmail.com").font(.system(size: 15)).foregroundStyle(.secondary)
                            Text("(416) 555-0192").font(.system(size: 15)).foregroundStyle(.secondary)
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
