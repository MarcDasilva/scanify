import SwiftUI

// MARK: - Company Header

struct ScanifyCompanyHeader: View {
    let companyName: String
    let subtitle: String
    let icon: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("Scanify")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(companyName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - Instruction Pill

struct ScanifyInstructionPill: View {
    let text: String
    let icon: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.bottom, 16)
    }
}

// MARK: - Demo Product Pills

struct ScanifyDemoPills: View {
    let label: String
    let products: [ScannedProduct]
    let icon: String
    let onSelect: (ScannedProduct) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(products) { product in
                        Button {
                            onSelect(product)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
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

// MARK: - Wrong Category Fallback

struct ScanifyWrongCategoryView: View {
    let expected: String
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Not a \(expected.capitalized) Product")
                .font(.system(size: 18, weight: .bold))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Animated Scan Line

struct ScanifyAnimatedScanLine: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [.clear, color, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 240, height: 2)
            .offset(y: animate ? 120 : -120)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { animate = true }
    }
}

// MARK: - Reverse Mask

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}
