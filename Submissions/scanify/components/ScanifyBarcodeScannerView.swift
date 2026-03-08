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
            // Dimmed edges with clear cutout (self-contained compositing group)
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .frame(width: 300, height: 180)
                    Spacer()
                }
                .blendMode(.destinationOut)
            }
            .compositingGroup()
            .ignoresSafeArea()

            // Scan window border, corners, and line (outside compositing — renders with true colors)
            VStack {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 300, height: 180)

                    ScanCorners(color: .white)
                        .frame(width: 300, height: 180)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .blue, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 260, height: 2)
                        .offset(y: animateScanLine ? 70 : -70)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: animateScanLine
                        )
                }

                Spacer()
            }

            // Instruction
            VStack {
                Spacer()

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
    private let length: CGFloat = 35
    private let lineWidth: CGFloat = 5

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
