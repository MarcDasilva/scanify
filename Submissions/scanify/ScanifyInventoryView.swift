import SwiftUI

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

                if !data.colors.isEmpty {
                    colorSection
                }

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

    // MARK: - Sections

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
            withAnimation(.spring(duration: 0.25)) {
                selectedSize = item.size
            }
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
                    Button {
                        selectedColor = color
                    } label: {
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
