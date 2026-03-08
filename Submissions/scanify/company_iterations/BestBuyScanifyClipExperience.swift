import SwiftUI
import AudioToolbox

struct BestBuyScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/best-buy/scan"
    static let clipName = "Scanify — Best Buy"
    static let clipDescription = "Scan electronics for specs, warranty, and compatible accessories."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        BestBuyScanifyFlowView(
            storeBranding: StoreBranding.forStoreId("best-buy"),
            allowedCategory: .electronics
        )
    }
}

// MARK: - Best Buy Colors

private let bbDarkBlue = Color(scanifyHex: "#0046BE")
private let bbBlue = Color(scanifyHex: "#0058A3")
private let bbYellow = Color(scanifyHex: "#FFE000")

// MARK: - Best Buy flow

private struct BestBuyScanifyFlowView: View {
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
                successView.transition(.scale.combined(with: .opacity))
            } else {
                cameraScanner
            }
        }
        .animation(.spring(duration: 0.35), value: showSuccess)
        .sheet(item: $scannedProduct) { product in
            BestBuyScanifySheet(
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
        } message: { Text(productNotFoundMessage) }
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
                onBarcodeScanned: { handleBarcode($0) },
                isActive: scannedProduct == nil && !showSuccess && !showProductNotFound
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top branding
                VStack(spacing: 10) {
                    Spacer().frame(height: 110)
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(bbYellow)
                        Text("Best Buy")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                    }
                    Text("Scan a product barcode")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [bbDarkBlue, bbDarkBlue, bbDarkBlue.opacity(0.9), bbDarkBlue.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ).ignoresSafeArea(edges: .top)
                )

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 280, height: 160)
                    ScanCorners(color: bbYellow)
                        .frame(width: 280, height: 160)
                }

                Spacer()

                // Bottom demo products
                VStack(spacing: 8) {
                    if !scanHistory.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(scanHistory) { product in
                                    Button { scannedProduct = product } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: product.category.icon).font(.system(size: 10)).foregroundStyle(bbYellow)
                                            Text(product.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(.white.opacity(0.15), in: .capsule)
                                        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                    }
                                }
                            }.padding(.horizontal, 16)
                        }
                    }
                    Text("Demo Products").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(demoProducts) { product in
                                Button { handleBarcode(product.barcode) } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon).font(.system(size: 11))
                                        Text(product.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .glassEffect(.regular.interactive(), in: .capsule)
                                }
                            }
                        }.padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [.black.opacity(0), .black.opacity(0.4), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
            }
            .ignoresSafeArea()
        }
    }

    private func handleBarcode(_ barcode: String) {
        guard let product = ScanifyMockData.lookup(barcode: barcode) else {
            lastUnknownBarcode = barcode; showProductNotFound = true; return
        }
        if let allowed = allowedCategory, product.category != allowed {
            lastUnknownBarcode = barcode; showProductNotFound = true; return
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

// MARK: - Best Buy sheet

private struct BestBuyScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var showShareSheet = false

    private var shareText: String {
        if case .electronics(let data) = product.categoryData {
            return "Scanify Report: \(product.name) by \(product.brand)\nWarranty: \(data.warranty.months)-month \(data.warranty.type)\nPrice: $\(String(format: "%.2f", product.price))"
        }
        return "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .electronics(let data) = product.categoryData {
                    BestBuyProductIntelView(product: product, data: data)
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
                        Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Buy") { showCheckout = true }
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showCheckout) {
            ScanifyCheckoutView(product: product, variant: product.name, accentColor: bbDarkBlue) {
                showCheckout = false; onOrderComplete()
            }
        }
        .sheet(isPresented: $showShareSheet) { ScanifyShareSheet(items: [shareText]) }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Product Intelligence View

private struct BestBuyProductIntelView: View {
    let product: ScannedProduct
    let data: ElectronicsData

    @State private var showBoxContents = false
    @State private var warrantyRegistered = false
    @State private var emailInput: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection

                VStack(spacing: 24) {
                    warrantySection
                    compatibilitySection
                    specsSection
                    accessoriesSection
                    boxSection
                    similarProductsSection
                    faqSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Product Intelligence")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(bbYellow)
                    Text("Best Buy")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("Electronics")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Product card
            VStack(spacing: 12) {
                if let imageName = product.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                } else {
                    Image(systemName: "headphones")
                        .font(.system(size: 50))
                        .foregroundStyle(bbDarkBlue.opacity(0.3))
                        .frame(height: 180)
                }

                Text(product.brand.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                Text(product.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(String(format: "$%.2f %@", product.price, product.currency))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [bbDarkBlue, bbBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    // MARK: - Compatibility

    private var compatibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Works With")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(data.compatibleWith, id: \.self) { device in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text(device)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.green.opacity(0.08), in: .capsule)
                    }
                }
            }
        }
    }

    // MARK: - Specs

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specifications")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            ForEach(data.specCategories) { category in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(bbDarkBlue)
                        Text(category.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(category.specs.enumerated()), id: \.element.id) { index, spec in
                            HStack {
                                Text(spec.key)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(spec.value)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            if index < category.specs.count - 1 {
                                Divider().padding(.horizontal, 14)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                }
            }
        }
    }

    // MARK: - Warranty (expanded by default)

    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(bbDarkBlue)
                    Text("Warranty")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Text("\(data.warranty.months)-Month \(data.warranty.type)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Covers
            VStack(alignment: .leading, spacing: 6) {
                Text("COVERED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
                    .tracking(0.5)
                ForEach(data.warranty.covers, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.15), lineWidth: 1))

            // Excludes
            VStack(alignment: .leading, spacing: 6) {
                Text("NOT COVERED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
                    .tracking(0.5)
                ForEach(data.warranty.excludes, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.12), lineWidth: 1))

            // Extended warranty upsell
            if let extPrice = data.warranty.extendedPrice,
               let extMonths = data.warranty.extendedMonths {
                HStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 22))
                        .foregroundStyle(bbDarkBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Extend to \(extMonths / 12) Years")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Includes accidental damage protection")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "+$%.2f", extPrice))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(bbDarkBlue)
                }
                .padding(14)
                .background(bbDarkBlue.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(bbDarkBlue.opacity(0.15), lineWidth: 1))
            }

            // Warranty registration
            if warrantyRegistered {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Warranty registered!").font(.system(size: 13, weight: .semibold)).foregroundStyle(.green)
                    Spacer()
                }
                .padding(12)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    TextField("Enter email to register warranty", text: $emailInput)
                        .font(.system(size: 14))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))

                    Button {
                        withAnimation { warrantyRegistered = true }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.checkered")
                            Text("Register Warranty")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(bbDarkBlue, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Accessories

    private var accessoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compatible Accessories")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            ForEach(data.compatibleAccessories) { accessory in
                HStack(spacing: 12) {
                    Image(systemName: accessory.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(bbDarkBlue)
                        .frame(width: 36, height: 36)
                        .background(bbDarkBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accessory.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(String(format: "$%.2f", accessory.price))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(accessory.aisle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(bbDarkBlue)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(bbDarkBlue.opacity(0.08), in: .capsule)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            }
        }
    }

    // MARK: - Box Contents

    private var boxSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { withAnimation { showBoxContents.toggle() } } label: {
                HStack {
                    Text("What's in the Box")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showBoxContents ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if showBoxContents {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(data.boxContents, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(bbDarkBlue)
                            Text(item).font(.system(size: 13)).foregroundStyle(.primary)
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Similar Products

    private var similarProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customers Also Viewed")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    similarCard(
                        imageName: "bestbuy_xm6",
                        name: "Sony WH-1000XM6",
                        price: "$549.99",
                        badge: "New",
                        scale: 1.8
                    )
                    similarCard(
                        imageName: "bestbuy_airpods_max",
                        name: "Apple AirPods Max",
                        price: "$779.00",
                        badge: nil
                    )
                }
            }
        }
    }

    private func similarCard(imageName: String, name: String, price: String, badge: String?, scale: CGFloat = 1.0) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(12)

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(bbDarkBlue, in: .capsule)
                        .padding(10)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(price)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 180)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            FAQItem(
                question: "Is the WH-1000XM5 worth upgrading from XM4?",
                answer: "Yes — the XM5 features a redesigned lighter build (250g vs 254g), improved call quality with 4 beamforming mics, and the new V1 processor for better ANC. Sound quality and battery life remain best-in-class."
            )
            FAQItem(
                question: "Can I use these wired without battery?",
                answer: "Yes. Using the included 3.5mm cable, you can listen passively even when the battery is dead. However, ANC and other smart features require power."
            )
            FAQItem(
                question: "Are replacement ear pads available?",
                answer: "Yes — Sony sells official replacement pads and they're available in-store at Aisle 7. Third-party options are also compatible."
            )
            FAQItem(
                question: "Do they support multipoint connection?",
                answer: "Yes — the XM5 can connect to 2 devices simultaneously via Bluetooth 5.2 and seamlessly switch audio between them."
            )
        }
    }
}

// MARK: - FAQ Item

private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } } label: {
                HStack(alignment: .top, spacing: 10) {
                    Text(question)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "minus" : "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }

            if isExpanded {
                Text(answer)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }
}
