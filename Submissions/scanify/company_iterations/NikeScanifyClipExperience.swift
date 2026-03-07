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

// MARK: - Nike flow (scanner + sheet + success)

private struct NikeScanifyFlowView: View {
    let storeBranding: StoreBranding
    var allowedCategory: ProductCategory?

    @State private var scannedProduct: ScannedProduct?
    @State private var showSuccess = false
    @State private var showProductNotFound = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []

    private var demoProducts: [ScannedProduct] {
        if let cat = allowedCategory {
            return ScanifyMockData.allProducts.filter { $0.category == cat }
        }
        return ScanifyMockData.allProducts
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
            NikeScanifySheet(
                product: product,
                storeBranding: storeBranding,
                onDismiss: { scannedProduct = nil },
                onOrderComplete: {
                    scannedProduct = nil
                    withAnimation(.spring(duration: 0.4)) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showSuccess = false }
                    }
                }
            )
        }
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

    private var cameraScanner: some View {
        ZStack {
            ScanifyBarcodeScannerView(
                onBarcodeScanned: { barcode in handleBarcode(barcode) },
                isActive: scannedProduct == nil && !showSuccess && !showProductNotFound
            )
            .ignoresSafeArea()

            ScannerOverlayView(storeBranding: storeBranding)
                .ignoresSafeArea()

            VStack {
                if !scanHistory.isEmpty {
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
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("Demo Products")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(demoProducts) { product in
                                Button { handleBarcode(product.barcode) } label: {
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
        scannedProduct = product
        withAnimation(.spring(duration: 0.3)) {
            scanHistory.removeAll { $0.barcode == product.barcode }
            scanHistory.insert(product, at: 0)
            if scanHistory.count > 5 { scanHistory = Array(scanHistory.prefix(5)) }
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

// MARK: - Nike sheet (apparel → InventoryView + checkout)

private struct NikeScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
    @State private var showShareSheet = false

    private var shareText: String {
        "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .apparel(let data) = product.categoryData {
                    ScanifyInventoryView(product: product, data: data, accentColor: storeBranding.accentColor) { size in
                        checkoutVariant = "Size \(size)"
                        showCheckout = true
                    }
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showShareSheet = true } label: {
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

// MARK: - Nike category view (apparel: size & inventory)

struct ScanifyInventoryView: View {
    let product: ScannedProduct
    let data: ApparelData
    var accentColor: Color = .blue
    let onBuyOnline: (String) -> Void

    @State private var selectedSize: String?
    @State private var selectedColor: ColorVariant?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                productHeader
                sizeSection
                if !data.colors.isEmpty { colorSection }
                detailsSection
                if let size = selectedSize,
                   let sizeData = data.sizes.first(where: { $0.size == size }),
                   sizeData.stockStatus == .outOfStock {
                    buyOnlineSection(size: size)
                }
                nearbySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Size & Inventory")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var productHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 48))
                .foregroundStyle(accentColor.opacity(0.6))
                .frame(width: 80, height: 80)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22))

            Text(product.brand)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(product.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            Text(String(format: "$%.2f %@", product.price, product.currency))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accentColor)
        }
        .padding(.top, 8)
    }

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Size")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(data.fit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(data.sizes) { sizeItem in
                    sizeButton(sizeItem)
                }
            }

            HStack(spacing: 16) {
                legendDot(color: .green, label: "In Stock")
                legendDot(color: .yellow, label: "Low Stock")
                legendDot(color: .red, label: "Unavailable")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
    }

    private func sizeButton(_ item: SizeInventory) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { selectedSize = item.size }
        } label: {
            VStack(spacing: 4) {
                Text(item.size)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.stockStatus == .outOfStock ? .secondary : .primary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(item.stockStatus.color)
                        .frame(width: 6, height: 6)
                    Text(item.inStock == 0 ? "Out" : "\(item.inStock) left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedSize == item.size ? item.stockStatus.color : .clear, lineWidth: 2)
            )
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                ForEach(data.colors) { color in
                    Button { selectedColor = color } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(scanifyHex: color.hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor?.id == color.id ? Color.primary : .clear, lineWidth: 2)
                                        .padding(-3)
                                )
                            Text(color.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            HStack {
                Label("Fit", systemImage: "ruler")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.fit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Label("Material", systemImage: "leaf.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.material)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func buyOnlineSection(size: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Size \(size) is not available at this location")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ClipActionButton(title: "Ship \(size) to Me", icon: "shippingbox.fill") {
                onBuyOnline(size)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Stores")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yorkdale Mall")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Size M available")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
                Spacer()
                Text("4.2 km")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Eaton Centre")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Size M — Low stock (2 left)")
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text("6.1 km")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
