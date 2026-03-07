import SwiftUI
import AudioToolbox

struct ShoppersDrugMartScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/shoppers-drug-mart/scan"
    static let clipName = "Scanify — Shoppers Drug Mart"
    static let clipDescription = "Scan pharmacy products for dosage, interactions, and generic alternatives."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ShoppersScanifyFlowView(
            storeBranding: StoreBranding.forStoreId("shoppers-drug-mart"),
            allowedCategory: .pharmacy
        )
    }
}

// MARK: - Shoppers flow

private struct ShoppersScanifyFlowView: View {
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
            ShoppersScanifySheet(
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

// MARK: - Shoppers sheet (pharmacy → MedicineView)

private struct ShoppersScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
    @State private var showShareSheet = false

    private var shareText: String {
        if case .pharmacy(let data) = product.categoryData {
            let treats = data.treats.joined(separator: ", ")
            return "Scanify Report: \(product.name) by \(product.brand)\nTreats: \(treats)\nDosage: \(data.dosage)"
        }
        return "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .pharmacy(let data) = product.categoryData {
                    ScanifyMedicineView(product: product, data: data, accentColor: storeBranding.accentColor)
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

// MARK: - Shoppers category view (pharmacy: medicine guide)

struct ScanifyMedicineView: View {
    let product: ScannedProduct
    let data: PharmacyData
    var accentColor: Color = .red

    @State private var medicationInput: String = ""
    @State private var interactionResult: InteractionResult?
    @State private var showDosageInfo = false

    enum InteractionResult {
        case safe(String)
        case warning(DrugInteraction)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(product.brand)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text(String(format: "$%.2f", product.price))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 8)

                treatsSection
                doesNotTreatSection
                ingredientsSection
                interactionSection

                if let generic = data.genericEquivalent {
                    genericSection(generic)
                }

                if let age = data.ageRestriction {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.questionmark")
                            .foregroundStyle(.orange)
                        Text(age)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Medicine Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var treatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("What This Treats")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            FlowLayout(spacing: 8) {
                ForEach(data.treats, id: \.self) { symptom in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(symptom)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.1), in: .capsule)
                    .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    private var doesNotTreatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Does NOT Treat")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            FlowLayout(spacing: 8) {
                ForEach(data.doesNotTreat, id: \.self) { symptom in
                    Text(symptom)
                        .font(.system(size: 12, weight: .medium))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showDosageInfo.toggle() }
            } label: {
                HStack {
                    Text("Active Ingredients & Dosage")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showDosageInfo ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if showDosageInfo {
                VStack(spacing: 6) {
                    ForEach(data.activeIngredients, id: \.name) { ingredient in
                        HStack {
                            Text(ingredient.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(ingredient.dose)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                        .padding(10)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(data.dosage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var interactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "pills.fill")
                    .foregroundStyle(.blue)
                Text("Interaction Checker")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {
                TextField("Enter a medication name...", text: $medicationInput)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit { checkInteraction() }

                Button(action: checkInteraction) {
                    Text("Check")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.blue, in: .capsule)
                }
                .disabled(medicationInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 6) {
                Text("Try:")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                ForEach(["Lisinopril", "Vitamin D", "Warfarin"], id: \.self) { med in
                    Button {
                        medicationInput = med
                        checkInteraction()
                    } label: {
                        Text(med)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
            }

            if let result = interactionResult {
                interactionResultView(result)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func checkInteraction() {
        let input = medicationInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !input.isEmpty else { return }

        withAnimation(.spring(duration: 0.3)) {
            if let interaction = data.interactions.first(where: { $0.drugName.lowercased() == input }) {
                interactionResult = .warning(interaction)
            } else {
                interactionResult = .safe(medicationInput)
            }
        }
    }

    @ViewBuilder
    private func interactionResultView(_ result: InteractionResult) -> some View {
        switch result {
        case .safe(let drugName):
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Interactions Found")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Safe to take with \(drugName).")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.25), lineWidth: 1))

        case .warning(let interaction):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(interaction.severity.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(interaction.severity.rawValue.uppercased()) INTERACTION")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(interaction.severity.color)
                        Text("with \(interaction.drugName)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }

                Text(interaction.reason)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(interaction.severity.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(interaction.severity.color.opacity(0.25), lineWidth: 1))
        }
    }

    private func genericSection(_ generic: GenericEquivalent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                Text("Save Money")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(generic.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Same active ingredients")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(String(format: "$%.2f", generic.price))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green)
                        Text(String(format: "(save $%.2f)", generic.savings))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                Text(generic.aisle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(14)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Flow Layout (used by MedicineView)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
