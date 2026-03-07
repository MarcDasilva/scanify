import SwiftUI
import AVFoundation

struct SephoraScanifyClipExperience: ClipExperience {
    static let urlPattern = "example.com/sephora-scanify/:param"
    static let clipName = "Sephora"
    static let clipDescription = "Sephora in-store barcode scanner"
    static let teamName = "Scanify"

    static let touchpoint = JourneyTouchpoint(
        id: "scanify",
        title: "Scanify",
        icon: "barcode.viewfinder",
        context: "General use case BarCode Scanner",
        notificationHint: "Use the 8h window for follow-up offers.",
        sortOrder: 32
    )
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext
    @State private var scanner = BarcodeScannerManager()

    private let viewfinderWidth: CGFloat = 300
    private let viewfinderHeight: CGFloat = 180

    private var sephoraWallpaper: UIImage? {
        if let path = Bundle.main.path(forResource: "sephora_wallpaper", ofType: "png", inDirectory: "scanify/public") {
            return UIImage(contentsOfFile: path)
        }
        return UIImage(named: "sephora_wallpaper")
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: scanner.session)
                .ignoresSafeArea()

            if let image = sephoraWallpaper {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(1.0)
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: viewfinderWidth, height: viewfinderHeight)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .ignoresSafeArea()
            }

            ViewfinderOverlay(width: viewfinderWidth, height: viewfinderHeight)

            VStack {
                Spacer()

                if let code = scanner.scannedCode {
                    scannedResultView(code)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 40)
            .animation(.spring(duration: 0.35), value: scanner.scannedCode)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            scanner.configure()
            scanner.start()
        }
        .onDisappear {
            scanner.stop()
        }
    }

    private func scannedResultView(_ code: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("Scanned")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(code)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button {
                withAnimation {
                    scanner.scannedCode = nil
                }
                scanner.start()
            } label: {
                Label("Scan Again", systemImage: "barcode.viewfinder")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: 300)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
