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

// MARK: - Nike scanner overlay (black/white, Nike branding)

private struct NikeScannerOverlay: View {
    @State private var animateScanLine = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        )
                    ScanCorners(color: .white)
                        .frame(width: 280, height: 280)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240, height: 2)
                        .offset(y: animateScanLine ? 120 : -120)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateScanLine)
                }
                Spacer()
            }
            .compositingGroup()
            .blendMode(.destinationOut)

            VStack {
                HStack(spacing: 10) {
                    NikeSwooshShape()
                        .fill(Color.white)
                        .frame(width: 28, height: 10)
                    Text("NIKE")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                Text("Point at a barcode to scan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
            }
        }
        .onAppear { animateScanLine = true }
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
    @State private var showSuccess = false
    @State private var showProductNotFound = false
    @State private var showNikeSplash = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []
    @Namespace private var heroNamespace

    private var demoProducts: [ScannedProduct] {
        if let cat = allowedCategory {
            return ScanifyMockData.products(for: storeBranding.storeId)
        }
        return ScanifyMockData.allProducts.filter { $0.category == .apparel }
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
            } else if showBag && !bagItems.isEmpty {
                NikeBagView(
                    items: bagItems,
                    onCheckout: {
                        showBag = false
                        bagItems.removeAll()
                        scannedProduct = nil
                        withAnimation(.spring(duration: 0.4)) { showSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSuccess = false }
                        }
                    },
                    onBackToProduct: {
                        showBag = false
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
            } else if let product = scannedProduct {
                NikeProductPageView(
                    product: product,
                    storeBranding: storeBranding,
                    heroNamespace: heroNamespace,
                    onBack: { withAnimation(.spring(duration: 0.4)) { scannedProduct = nil } },
                    onAddToBag: { item in
                        bagItems.append(item)
                        withAnimation(.spring(duration: 0.4)) { showBag = true }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeOut(duration: 0.35)),
                    removal: .opacity.animation(.easeIn(duration: 0.25))
                ))
                .zIndex(1)
            }

            // Scanner (with hero source when transitioning)
            ZStack {
                ScanifyBarcodeScannerView(
                    onBarcodeScanned: { handleBarcode($0) },
                    isActive: scannedProduct == nil && !showBag && !showSuccess && !showProductNotFound
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemFill))
                        .overlay(
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.black.opacity(0.35))
                        )
                        .frame(width: 120, height: 120)
                        .matchedGeometryEffect(id: "product-hero-\(product.id)", in: heroNamespace)
                }
            }
            .zIndex(0)
        }
        .animation(.spring(duration: 0.55, bounce: 0.32), value: scannedProduct?.id)
        .animation(.spring(duration: 0.4), value: showBag)
        .animation(.easeOut(duration: 0.25), value: showNikeSplash)
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
            withAnimation(.easeOut(duration: 0.22)) {
                showNikeSplash = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(duration: 0.52, bounce: 0.32)) {
                    scannedProduct = productToShow
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

    private var apparelData: ApparelData? {
        guard case .apparel(let data) = product.categoryData else { return nil }
        return data
    }

    private var categoryLabel: String {
        product.name.contains("P-6000") ? "MEN'S SHOES" : "MEN'S WORKOUT SHOES"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImageSection
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoryLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(product.name.uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(product.currency) \(String(format: "%.2f", product.price))")
                            .font(.system(size: 18, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("4.0 /251")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showSizeSheet = true
                    } label: {
                        HStack {
                            Text("Select size")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            if let s = selectedSize {
                                Text(s)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

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

                    if let data = apparelData {
                        colorSection(data: data)
                        detailsSection(data: data)
                        nearbyStoresSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .overlay(alignment: .topLeading) { topBar }
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

    private var heroImageSection: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.secondarySystemFill))
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.black.opacity(0.2))
                )
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .matchedGeometryEffect(id: "product-hero-\(product.id)", in: heroNamespace)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? Color.black : Color.black.opacity(0.25))
                        .frame(width: i == 0 ? 8 : 6, height: 6)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.top, 8)
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            HStack(spacing: 8) {
                NikeSwooshShape()
                    .fill(Color.primary)
                    .frame(width: 24, height: 9)
                Text("NIKE")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button { } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    private func colorSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 16, weight: .semibold))
            HStack(spacing: 16) {
                ForEach(data.colors) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(scanifyHex: color.hex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().strokeBorder(selectedColor?.id == color.id ? Color.blue : .clear, lineWidth: 2))
                            Text(color.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(selectedColor?.id == color.id ? .blue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func detailsSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.system(size: 16, weight: .semibold))
            HStack {
                Label("Fit", systemImage: "ruler")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.fit)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(14)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Label("Material", systemImage: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.material)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(14)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func nearbyStoresSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Stores")
                .font(.system(size: 16, weight: .semibold))
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yorkdale Mall")
                        .font(.system(size: 14, weight: .medium))
                    Text("Size \(selectedSize ?? "M") available")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                Spacer()
                Text("4.2 km")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Eaton Centre")
                        .font(.system(size: 14, weight: .medium))
                    Text("Size \(selectedSize ?? "M") — Low stock (2 left)")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
                Spacer()
                Text("6.1 km")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func setDefaults() {
        guard let data = apparelData else { return }
        if selectedColor == nil, let first = data.colors.first {
            selectedColor = first
        }
        if selectedSize == nil {
            selectedSize = data.sizes.first(where: { $0.size == "US 9" })?.size
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemFill))
                        .frame(width: 72, height: 72)
                        .overlay(Image(systemName: "tshirt.fill").font(.system(size: 28)).foregroundStyle(.secondary))
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

// MARK: - Nike Bag View (matches Nike app Bag screen)

private struct NikeBagView: View {
    let items: [NikeBagItem]
    let onCheckout: () -> Void
    let onBackToProduct: () -> Void

    @State private var showPromoCode = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        Button(action: onBackToProduct) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 44, height: 44)
                        }
                        Text("Bag")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Promo banner
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gear Up for the Fall Event")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Use code FALL25 for 25% off select styles.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemFill).opacity(0.8), in: RoundedRectangle(cornerRadius: 12))

                    // Product card(s)
                    ForEach(items) { item in
                        bagProductCard(item)
                    }

                    // Shipping
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Shipping")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        HStack(spacing: 4) {
                            Text("Arrives by Tue, Aug 20 to ")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                            Text("94085")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.blue)
                                .underline()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Pickup
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pickup")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Button { } label: {
                            Text("Find a Store")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.blue)
                                .underline()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Promo code
                    Button {
                        showPromoCode.toggle()
                    } label: {
                        HStack {
                            Text("Have a Promo Code?")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: showPromoCode ? "minus" : "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Free shipping
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                        Text("You've earned Free Shipping!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)

            // Checkout button
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

            // Bottom nav (Nike-style)
            HStack(spacing: 0) {
                navItem(icon: "house", label: "Home")
                navItem(icon: "magnifyingglass", label: "Shop")
                navItem(icon: "heart", label: "Favorites")
                ZStack(alignment: .topTrailing) {
                    navItem(icon: "bag.fill", label: "Bag", active: true)
                    Text("\(items.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.red, in: Circle())
                        .offset(x: 12, y: -6)
                }
                navItem(icon: "person", label: "Profile")
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
    }

    private func bagProductCard(_ item: NikeBagItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemFill))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                Text(productCategoryLabel(item.product))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(item.colorName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(sizeLabel(item))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Qty \(item.quantity)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: "$%.2f", item.price))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func productCategoryLabel(_ product: ScannedProduct) -> String {
        product.name.contains("P-6000") ? "Men's Shoes" : "Men's Workout Shoes"
    }

    private func sizeLabel(_ item: NikeBagItem) -> String {
        if item.size.hasPrefix("US ") {
            let num = item.size.replacingOccurrences(of: "US ", with: "")
            return "M \(num) / W \((Double(num) ?? 0) + 1.5)"
        }
        return item.size
    }

    private func navItem(icon: String, label: String, active: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(active ? .primary : .secondary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(active ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
