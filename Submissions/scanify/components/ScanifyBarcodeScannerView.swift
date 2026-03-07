import SwiftUI
import AVFoundation

// MARK: - Camera Barcode Scanner (UIKit bridge)

struct ScanifyBarcodeScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void
    var isActive: Bool = true

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onBarcodeScanned = onBarcodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        if isActive {
            uiViewController.resetScanner()
        }
    }
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .upce, .code128]
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = object.stringValue else { return }

        hasScanned = true

        #if !targetEnvironment(simulator)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        onBarcodeScanned?(barcode)
    }

    func resetScanner() {
        hasScanned = false
    }
}

// MARK: - Scanner Overlay (SwiftUI)

struct ScannerOverlayView: View {
    let storeBranding: StoreBranding
    @State private var animateScanLine = false

    var body: some View {
        ZStack {
            // Dimmed edges
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Clear cutout in center
            VStack {
                Spacer()

                ZStack {
                    // Scan window
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.clear)
                        .frame(width: 280, height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(storeBranding.accentColor.opacity(0.6), lineWidth: 2)
                        )

                    // Corner brackets
                    ScanCorners(color: storeBranding.accentColor)
                        .frame(width: 280, height: 280)

                    // Scan line
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [.clear, storeBranding.accentColor, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240, height: 2)
                        .offset(y: animateScanLine ? 120 : -120)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: animateScanLine
                        )
                }

                Spacer()
            }
            .compositingGroup()
            .blendMode(.destinationOut)

            // Top bar
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: storeBranding.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(storeBranding.accentColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Scanify")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text(storeBranding.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Instruction
                Text("Point at a barcode to scan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            animateScanLine = true
        }
    }
}

// MARK: - Corner Brackets

struct ScanCorners: View {
    let color: Color
    private let length: CGFloat = 30
    private let lineWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Top-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: length))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: length, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: w - length, y: 0))
                p.addLine(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: length))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: h - length))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: length, y: h))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: w - length, y: h))
                p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: w, y: h - length))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}
