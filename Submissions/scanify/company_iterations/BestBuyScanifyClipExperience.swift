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
                successView
                    .transition(.scale.combined(with: .opacity))
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

// MARK: - Best Buy sheet (electronics → ElectronicsView)

private struct BestBuyScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
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
                    ScanifyElectronicsView(product: product, data: data, accentColor: storeBranding.accentColor)
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Buy") {
                        checkoutVariant = product.name
                        showCheckout = true
                    }
                    .font(.system(size: 14, weight: .semibold))
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

// MARK: - Best Buy category view (electronics: specs, warranty, accessories)

struct ScanifyElectronicsView: View {
    let product: ScannedProduct
    let data: ElectronicsData
    var accentColor: Color = .purple

    @State private var showWarrantyDetails = false
    @State private var showBoxContents = false
    @State private var warrantyRegistered = false
    @State private var emailInput: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.system(size: 36))
                        .foregroundStyle(accentColor.opacity(0.6))
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18))

                    Text(product.brand)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(String(format: "$%.2f %@", product.price, product.currency))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 8)

                compatibilitySection
                specsSection
                warrantySection
                accessoriesSection
                boxSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Product Intelligence")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var compatibilitySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(data.compatibleWith, id: \.self) { device in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(device)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
        }
    }

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
                            .foregroundStyle(accentColor)
                        Text(category.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        ForEach(category.specs) { spec in
                            HStack {
                                Text(spec.key)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(spec.value)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showWarrantyDetails.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(.blue)
                        Text("Warranty")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text("\(data.warranty.months)-Month \(data.warranty.type)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: showWarrantyDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            if showWarrantyDetails {
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Covers")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)
                        ForEach(data.warranty.covers, id: \.self) { item in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.green)
                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Does Not Cover")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.red)
                        ForEach(data.warranty.excludes, id: \.self) { item in
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                    if let extPrice = data.warranty.extendedPrice,
                       let extMonths = data.warranty.extendedMonths {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Extend to \(extMonths / 12) years")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Full coverage including accidental damage")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", extPrice))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                    }

                    if warrantyRegistered {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Warranty registered!")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.green)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            TextField("Enter email to register", text: $emailInput)
                                .font(.system(size: 14))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

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
                                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var accessoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compatible Accessories — In Stock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            ForEach(data.compatibleAccessories) { accessory in
                HStack(spacing: 12) {
                    Image(systemName: accessory.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(accentColor)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accessory.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(String(format: "$%.2f", accessory.price))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text(accessory.aisle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .padding(10)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var boxSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { showBoxContents.toggle() }
            } label: {
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
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(12)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
