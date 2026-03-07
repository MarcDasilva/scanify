import SwiftUI

struct ScanifyCosmeticsView: View {
    let product: ScannedProduct
    let data: CosmeticsData
    let onBuyNow: (String) -> Void

    @State private var selectedShade: Shade?
    @State private var showCamera = true

    private var currentShade: Shade {
        selectedShade ?? data.shades[0]
    }

    private var shadeUIColor: UIColor {
        let hex = currentShade.hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        return UIColor(
            red: CGFloat((int >> 16) & 0xFF) / 255.0,
            green: CGFloat((int >> 8) & 0xFF) / 255.0,
            blue: CGFloat(int & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Product header
                VStack(spacing: 4) {
                    Text(product.brand)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(String(format: "$%.2f", product.price))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.pink)
                }
                .padding(.top, 4)

                // AR Camera Preview
                ZStack {
                    if showCamera {
                        ScanifyFaceCameraView(shadeColor: shadeUIColor)
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        // Fallback for simulator
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(scanifyHex: currentShade.hex).opacity(0.2),
                                        Color(scanifyHex: currentShade.hex).opacity(0.05),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 360)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 64, weight: .ultraLight))
                                        .foregroundStyle(Color(scanifyHex: currentShade.hex).opacity(0.5))
                                    Text("Camera not available")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }

                    // Live badge
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.5), in: .capsule)
                            .padding(12)
                        }
                        Spacer()
                    }

                    // Current shade label
                    VStack {
                        Spacer()
                        HStack {
                            Circle()
                                .fill(Color(scanifyHex: currentShade.hex))
                                .frame(width: 14, height: 14)
                            Text(currentShade.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.5), in: .capsule)
                        .padding(12)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: currentShade.id)

                // Shade picker
                shadePicker

                // Product details
                detailsSection

                // Buy Now
                ClipActionButton(title: "Buy Now — \(currentShade.name)", icon: "bag.fill") {
                    onBuyNow(currentShade.name)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Virtual Try-On")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check if camera is available
            showCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        }
    }

    // MARK: - Shade Picker

    private var shadePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a shade to try it on")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.shades) { shade in
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedShade = shade
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color(scanifyHex: shade.hex))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color(scanifyHex: shade.hex).opacity(0.4), radius: 4)
                                    .overlay(
                                        Circle()
                                            .stroke(currentShade.id == shade.id ? Color.primary : .clear, lineWidth: 2)
                                            .padding(-3)
                                    )
                                Text(shade.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(currentShade.id == shade.id ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)

            HStack {
                Label("Skin Type", systemImage: "drop.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.skinTypes.joined(separator: ", "))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Label("Volume", systemImage: "drop.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.volume)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
