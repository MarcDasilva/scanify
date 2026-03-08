//  NikeStyleProductPageView.swift
//  ReactivChallengeKit
//
//  Nike-style product detail page: hero image, size/color, availability, deliver or pickup.

import SwiftUI

struct NikeStyleProductPageView: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    var heroNamespace: Namespace.ID
    let onBack: () -> Void

    @State private var selectedSize: String?
    @State private var selectedColor: ColorVariant?
    @State private var showSizeSheet = false
    @State private var showOrderSuccess = false
    @State private var selectedImageIndex = 0
    @State private var isFavourite = false

    private var apparelData: ApparelData? {
        guard case .apparel(let data) = product.categoryData else { return nil }
        return data
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

    private var categoryLabel: String {
        product.name.contains("P-6000") ? "MEN'S SHOES" : "APPAREL"
    }

    private var priceFormatted: String {
        "\(product.currency) \(String(format: "%.2f", product.price))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image (hero transition target)
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
                        Text(priceFormatted)
                            .font(.system(size: 18, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("4.0 /251")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Select size row
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
                        // Add to bag
                        showOrderSuccess = true
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

                    Button {
                        isFavourite.toggle()
                    } label: {
                        HStack {
                            Text("Favourite")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: isFavourite ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isFavourite ? .red : .primary)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if let data = apparelData {
                        if let size = selectedSize,
                           let sizeData = data.sizes.first(where: { $0.size == size }),
                           sizeData.stockStatus == .outOfStock {
                            shipToMeSection(size: size)
                        }

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
        .sheet(isPresented: $showSizeSheet) {
            if let data = apparelData {
                SizeInventorySheet(
                    product: product,
                    data: data,
                    selectedSize: $selectedSize,
                    onAddToBag: {
                        showSizeSheet = false
                        showOrderSuccess = true
                    }
                )
            }
        }
        .overlay {
            if showOrderSuccess {
                orderSuccessOverlay
            }
        }
        .onAppear { setDefaults() }
    }

    // MARK: - Hero image (matched geometry for transition)

    private var heroImageSection: some View {
        let heroId = "product-hero-\(product.id)"
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.secondarySystemFill))
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(storeBranding.accentColor.opacity(0.4))
                )
                .frame(height: 400)
                .frame(maxWidth: .infinity)
                .matchedGeometryEffect(id: heroId, in: heroNamespace)

            // Carousel dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(selectedImageIndex == i ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: selectedImageIndex == i ? 8 : 6, height: 6)
                }
            }
            .padding(.bottom, 12)

            // Thumbnails row (placeholder)
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedImageIndex == i ? Color.primary : .clear, lineWidth: 2)
                        )
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            // Logo placeholder
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                // Search
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private func shipToMeSection(size: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("Material")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                Spacer()
                if let data = apparelData {
                    Text(data.material)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Size \(size) is not available at this location")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Button {
                showOrderSuccess = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 16))
                    Text("Ship \(size) to Me")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func colorSection(data: ApparelData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                ForEach(data.colors) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(scanifyHex: color.hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectedColor?.id == color.id ? Color.blue : .clear, lineWidth: 2)
                                )
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
                .foregroundStyle(.primary)

            HStack {
                Label("Fit", systemImage: "ruler")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.fit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
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
                    .foregroundStyle(.primary)
            }
            .padding(14)
            .background(Color(.secondarySystemFill).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func nearbyStoresSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nearby Stores")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yorkdale Mall")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.primary)
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

    private var orderSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Added to Bag")
                    .font(.system(size: 20, weight: .bold))
                Text("Pick up at cashier or get it delivered")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
        .onTapGesture {
            showOrderSuccess = false
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showOrderSuccess = false
            }
        }
    }
}

// MARK: - Size & Inventory Sheet (Nike-style modal)

struct SizeInventorySheet: View {
    let product: ScannedProduct
    let data: ApparelData
    @Binding var selectedSize: String?
    let onAddToBag: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Product summary
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemFill))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.brand)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(product.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("\(product.currency) \(String(format: "%.2f", product.price))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
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
                        Button("Size Guide") {
                            // Size guide
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(data.sizes) { item in
                            sizeButton(item)
                        }
                    }

                    HStack(spacing: 16) {
                        legendDot(.green, "In Stock")
                        legendDot(.yellow, "Low Stock")
                        legendDot(.red, "Unavailable")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "ruler")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("Fit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(data.fit)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
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
                    Button {
                        dismiss()
                    } label: {
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

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }
}
