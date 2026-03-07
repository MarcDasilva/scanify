import SwiftUI
import AVFoundation

// MARK: - Camera Preview

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func setSession(_ session: AVCaptureSession) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.setSession(session)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

// MARK: - Barcode Scanner Manager

@Observable
final class BarcodeScannerManager: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var scannedCode: String?
    var isRunning = false
    private var hasConfigured = false

    func configure() {
        guard !hasConfigured else { return }
        hasConfigured = true

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .upce, .code128, .code39, .code93,
                .itf14, .pdf417, .qr, .dataMatrix, .aztec
            ]
        }
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isRunning = true }
        }
    }

    func stop() {
        session.stopRunning()
        isRunning = false
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard scannedCode == nil,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }

        #if !targetEnvironment(simulator)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        withAnimation(.spring(duration: 0.3)) {
            scannedCode = value
        }
        stop()
    }
}

// MARK: - Scanning Line Animation

struct ScanningLineView: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let lineY = (offset + 1) / 2 * geo.size.height
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0), .blue.opacity(0.9), .blue.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .shadow(color: .blue.opacity(0.7), radius: 8, y: 0)
                .offset(y: lineY)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
            ) {
                offset = 1
            }
        }
    }
}

// MARK: - Viewfinder Overlay

struct ViewfinderOverlay: View {
    let width: CGFloat
    let height: CGFloat
    private let cornerLength: CGFloat = 34
    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .reverseMask {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: width, height: height)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
                .ignoresSafeArea()

            ZStack {
                ViewfinderCorners(
                    width: width,
                    height: height,
                    cornerLength: cornerLength,
                    lineWidth: lineWidth
                )

                ScanningLineView()
                    .frame(width: width - 20, height: height - 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ViewfinderCorners: View {
    let width: CGFloat
    let height: CGFloat
    let cornerLength: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        let halfW = width / 2
        let halfH = height / 2
        ZStack {
            ForEach(0..<4) { i in
                CornerShape(length: cornerLength)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: cornerLength, height: cornerLength)
                    .rotationEffect(.degrees(Double(i) * 90))
                    .offset(
                        x: (i == 0 || i == 3) ? -halfW + cornerLength / 2 : halfW - cornerLength / 2,
                        y: (i == 0 || i == 1) ? -halfH + cornerLength / 2 : halfH - cornerLength / 2
                    )
            }
        }
    }
}

private struct CornerShape: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        }
    }
}

private extension View {
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

// MARK: - Clip Experience

struct ScanifyClipExperience: ClipExperience {
    static let urlPattern = "example.com/scanify/:param"
    static let clipName = "Scanify"
    static let clipDescription = "General use case BarCode scanner"
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

    var body: some View {
        ZStack {
            CameraPreviewView(session: scanner.session)
                .ignoresSafeArea()

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
