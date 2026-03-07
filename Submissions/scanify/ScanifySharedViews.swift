import SwiftUI

/// Shared checkout and share UI used by all Scanify company clips (single definition to avoid duplicate types when concatenating).
struct ScanifyCheckoutView: View {
    let product: ScannedProduct
    let variant: String
    var accentColor: Color = .blue
    let onComplete: () -> Void

    @State private var processing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: product.category.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(product.category.accentColor)
                        .frame(width: 72, height: 72)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))

                    Text(product.brand)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(variant)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }

                VStack(spacing: 6) {
                    orderRow(label: "Subtotal", value: String(format: "$%.2f", product.price))
                    orderRow(label: "Shipping", value: "Free")
                    orderRow(label: "Tax (est.)", value: String(format: "$%.2f", product.price * 0.13))

                    Divider().padding(.vertical, 4)

                    HStack {
                        Text("Total")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(String(format: "$%.2f", product.price * 1.13))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .padding(14)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 20)

                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.blue)
                    Text("Estimated delivery: 2-3 business days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if processing {
                    ProgressView()
                        .padding(.bottom, 32)
                } else {
                    Button {
                        processing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            onComplete()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text("Pay")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.black, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func orderRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct ScanifyShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
