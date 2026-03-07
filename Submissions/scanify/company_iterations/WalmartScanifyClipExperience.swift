import SwiftUI

struct WalmartScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/walmart/scan"
    static let clipName = "Scanify — Walmart"
    static let clipDescription = "Scan grocery items for nutrition, allergens, and alternatives."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        WalmartScanifyFlowView(
            storeBranding: StoreBranding.forStoreId("walmart"),
            allowedCategory: .food
        )
    }
}

// MARK: - Walmart flow

private struct WalmartScanifyFlowView: View {
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
            WalmartScanifySheet(
                product: product,
                storeBranding: storeBranding,
                onDismiss: { scannedProduct = nil },
                onOrderComplete: {
                    scannedProduct = nil
                    withAnimation(.spring(duration: 0.4)) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showSuccess = false } }
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
            ScannerOverlayView(storeBranding: storeBranding).ignoresSafeArea()
            VStack {
                if !scanHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(scanHistory) { product in
                                Button { scannedProduct = product } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon).font(.system(size: 10)).foregroundStyle(product.category.accentColor)
                                        Text(product.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.white.opacity(0.15), in: .capsule)
                                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 56).transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                VStack(spacing: 8) {
                    Text("Demo Products").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
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

// MARK: - Walmart sheet

private struct WalmartScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
    @State private var showShareSheet = false

    private var shareText: String {
        if case .food(let data) = product.categoryData {
            let allergens = data.allergens.isEmpty ? "None" : data.allergens.map(\.rawValue).joined(separator: ", ")
            return "Scanify Report: \(product.name) by \(product.brand)\nAllergens: \(allergens)\nCalories: \(data.calories) per serving"
        }
        return "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .food(let data) = product.categoryData {
                    ScanifyNutritionView(product: product, data: data, accentColor: storeBranding.accentColor)
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showShareSheet = true } label: { Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary) }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Buy") { checkoutVariant = product.name; showCheckout = true }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showCheckout) {
            ScanifyCheckoutView(product: product, variant: checkoutVariant, accentColor: storeBranding.accentColor) {
                showCheckout = false
                onOrderComplete()
            }
        }
        .sheet(isPresented: $showShareSheet) { ScanifyShareSheet(items: [shareText]) }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Walmart category view (food: nutrition & allergens)

struct ScanifyNutritionView: View {
    let product: ScannedProduct
    let data: FoodData
    var accentColor: Color = .green

    @State private var showFullIngredients = false
    private var containsAllergens: Bool { !data.allergens.isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "carrot.fill")
                        .font(.system(size: 36)).foregroundStyle(accentColor.opacity(0.6))
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18))
                    Text(product.brand).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                    Text(product.name).font(.system(size: 20, weight: .bold)).foregroundStyle(.primary).multilineTextAlignment(.center)
                    Text(String(format: "$%.2f", product.price)).font(.system(size: 15, weight: .semibold)).foregroundStyle(accentColor)
                }
                .padding(.top, 8)
                allergenBanner
                allergenGrid
                if !data.dietaryFlags.isEmpty { dietaryFlagRow }
                nutritionSection
                if let alt = data.alternative, containsAllergens { alternativeSection(alt) }
                ingredientSection
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Nutrition & Allergens")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var allergenBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: containsAllergens ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .font(.system(size: 24)).foregroundStyle(containsAllergens ? .red : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(containsAllergens ? "CONTAINS ALLERGENS" : "NO COMMON ALLERGENS")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(containsAllergens ? .red : .green)
                if containsAllergens {
                    Text(data.allergens.map(\.rawValue).joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.primary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(containsAllergens ? Color.red.opacity(0.1) : Color.green.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(containsAllergens ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1))
    }

    private var allergenGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Allergen Screening").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Allergen.allCases) { allergen in
                    let isPresent = data.allergens.contains(allergen)
                    HStack(spacing: 6) {
                        Image(systemName: isPresent ? "xmark.circle.fill" : "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(isPresent ? .red : .green)
                        Text(allergen.rawValue).font(.system(size: 11, weight: .medium)).foregroundStyle(isPresent ? .primary : .secondary).lineLimit(1)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var dietaryFlagRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dietary Info").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
            HStack(spacing: 8) {
                ForEach(data.dietaryFlags) { flag in
                    HStack(spacing: 4) {
                        Image(systemName: flag.icon).font(.system(size: 10))
                        Text(flag.rawValue).font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.green).padding(.horizontal, 10).padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                Spacer()
            }
        }
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nutrition Facts").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
                Spacer()
                Text(data.servingSize).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                nutritionBar(label: "Calories", value: "\(data.calories)", percent: Double(data.calories) / 2000.0, color: .orange)
                nutritionBar(label: "Protein", value: String(format: "%.0fg", data.protein), percent: data.protein / 50.0, color: .blue)
                nutritionBar(label: "Carbs", value: String(format: "%.0fg", data.carbs), percent: data.carbs / 300.0, color: .purple)
                nutritionBar(label: "Fat", value: String(format: "%.0fg", data.fat), percent: data.fat / 65.0, color: .yellow)
                nutritionBar(label: "Sugar", value: String(format: "%.0fg", data.sugar), percent: data.sugar / 50.0, color: .red)
                nutritionBar(label: "Fiber", value: String(format: "%.0fg", data.fiber), percent: data.fiber / 28.0, color: .green)
            }
            .padding(14).glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func nutritionBar(label: String, value: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geo.size.width * min(percent, 1.0), height: 8)
                }
            }
            .frame(height: 8)
            Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(.primary).frame(width: 50, alignment: .trailing)
        }
    }

    private func alternativeSection(_ alt: AlternativeProduct) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.swap").font(.system(size: 14)).foregroundStyle(.green)
                Text("Safer Alternative").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alt.name).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                    Text(alt.reason).font(.system(size: 11)).foregroundStyle(.green)
                }
                Spacer()
                Text(alt.aisle).font(.system(size: 12, weight: .bold)).foregroundStyle(accentColor)
                    .padding(.horizontal, 10).padding(.vertical, 6).glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(14).background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
        }
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { withAnimation { showFullIngredients.toggle() } } label: {
                HStack {
                    Text("Ingredients").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showFullIngredients ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                }
            }
            if showFullIngredients {
                Text(ingredientText).font(.system(size: 12)).foregroundStyle(.secondary)
                    .padding(12).glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var ingredientText: AttributedString {
        let allergenNames = Set(data.allergens.map(\.rawValue).map { $0.lowercased() })
        let fullText = data.ingredients.joined(separator: ", ")
        var attributed = AttributedString(fullText)
        for allergen in allergenNames {
            let searchText = fullText.lowercased()
            var searchStart = searchText.startIndex
            while let range = searchText.range(of: allergen, range: searchStart..<searchText.endIndex) {
                let attrStart = AttributedString.Index(range.lowerBound, within: attributed)
                let attrEnd = AttributedString.Index(range.upperBound, within: attributed)
                if let start = attrStart, let end = attrEnd {
                    attributed[start..<end].foregroundColor = .red
                    attributed[start..<end].font = .system(size: 12, weight: .bold)
                }
                searchStart = range.upperBound
            }
        }
        return attributed
    }
}
