import SwiftUI

struct ScanifyNutritionView: View {
    let product: ScannedProduct
    let data: FoodData
    var accentColor: Color = .green

    @State private var showFullIngredients = false

    private var containsAllergens: Bool { !data.allergens.isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product header
                VStack(spacing: 6) {
                    Image(systemName: "carrot.fill")
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
                        .multilineTextAlignment(.center)
                    Text(String(format: "$%.2f", product.price))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .padding(.top, 8)

                allergenBanner
                allergenGrid

                if !data.dietaryFlags.isEmpty {
                    dietaryFlagRow
                }

                nutritionSection

                if let alt = data.alternative, containsAllergens {
                    alternativeSection(alt)
                }

                ingredientSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Nutrition & Allergens")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Allergen Verdict

    private var allergenBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: containsAllergens ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .font(.system(size: 24))
                .foregroundStyle(containsAllergens ? .red : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(containsAllergens ? "CONTAINS ALLERGENS" : "NO COMMON ALLERGENS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(containsAllergens ? .red : .green)
                if containsAllergens {
                    Text(data.allergens.map(\.rawValue).joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(containsAllergens ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(containsAllergens ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Allergen Grid

    private var allergenGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Allergen Screening")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Allergen.allCases) { allergen in
                    let isPresent = data.allergens.contains(allergen)
                    HStack(spacing: 6) {
                        Image(systemName: isPresent ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(isPresent ? .red : .green)
                        Text(allergen.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isPresent ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Dietary Flags

    private var dietaryFlagRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dietary Info")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                ForEach(data.dietaryFlags) { flag in
                    HStack(spacing: 4) {
                        Image(systemName: flag.icon)
                            .font(.system(size: 10))
                        Text(flag.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                Spacer()
            }
        }
    }

    // MARK: - Nutrition

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nutrition Facts")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(data.servingSize)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                nutritionBar(label: "Calories", value: "\(data.calories)", percent: Double(data.calories) / 2000.0, color: .orange)
                nutritionBar(label: "Protein", value: String(format: "%.0fg", data.protein), percent: data.protein / 50.0, color: .blue)
                nutritionBar(label: "Carbs", value: String(format: "%.0fg", data.carbs), percent: data.carbs / 300.0, color: .purple)
                nutritionBar(label: "Fat", value: String(format: "%.0fg", data.fat), percent: data.fat / 65.0, color: .yellow)
                nutritionBar(label: "Sugar", value: String(format: "%.0fg", data.sugar), percent: data.sugar / 50.0, color: .red)
                nutritionBar(label: "Fiber", value: String(format: "%.0fg", data.fiber), percent: data.fiber / 28.0, color: .green)
            }
            .padding(14)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func nutritionBar(label: String, value: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(percent, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .trailing)
        }
    }

    // MARK: - Alternative

    private func alternativeSection(_ alt: AlternativeProduct) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)
                Text("Safer Alternative")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alt.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(alt.reason)
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
                Spacer()
                Text(alt.aisle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(14)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
        }
    }

    // MARK: - Ingredients

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { showFullIngredients.toggle() }
            } label: {
                HStack {
                    Text("Ingredients")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showFullIngredients ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if showFullIngredients {
                Text(ingredientText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
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
