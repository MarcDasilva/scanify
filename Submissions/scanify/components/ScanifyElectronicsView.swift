import SwiftUI

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
                // Product header
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
