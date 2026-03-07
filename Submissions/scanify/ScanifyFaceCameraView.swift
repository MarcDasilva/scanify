import SwiftUI
import AVFoundation
import Vision

// MARK: - Front Camera with Lip Overlay

struct ScanifyFaceCameraView: UIViewControllerRepresentable {
    let shadeColor: UIColor

    func makeUIViewController(context: Context) -> FaceCameraViewController {
        let vc = FaceCameraViewController()
        vc.shadeColor = shadeColor
        return vc
    }

    func updateUIViewController(_ uiViewController: FaceCameraViewController, context: Context) {
        uiViewController.shadeColor = shadeColor
        uiViewController.updateOverlayColor()
    }
}

final class FaceCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var shadeColor: UIColor = .red

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayLayer = CAShapeLayer()
    private let sequenceHandler = VNSequenceRequestHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        overlayLayer.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    func updateOverlayColor() {
        overlayLayer.fillColor = shadeColor.withAlphaComponent(0.55).cgColor
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.sessionPreset = .high
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "scanify.face.camera"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Mirror the front camera
        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            connection.isVideoMirrored = true
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview
    }

    private func setupOverlay() {
        overlayLayer.fillColor = shadeColor.withAlphaComponent(0.55).cgColor
        overlayLayer.strokeColor = UIColor.clear.cgColor
        overlayLayer.frame = view.bounds
        view.layer.addSublayer(overlayLayer)
    }

    // MARK: - Vision Face Detection

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self,
                  let results = request.results as? [VNFaceObservation],
                  let face = results.first,
                  let landmarks = face.landmarks else {
                DispatchQueue.main.async { self?.overlayLayer.path = nil }
                return
            }

            let outerLips = landmarks.outerLips
            let innerLips = landmarks.innerLips

            DispatchQueue.main.async {
                self.drawLipOverlay(face: face, outerLips: outerLips, innerLips: innerLips)
            }
        }

        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
    }

    private func drawLipOverlay(face: VNFaceObservation, outerLips: VNFaceLandmarkRegion2D?, innerLips: VNFaceLandmarkRegion2D?) {
        guard let outerLips, let previewLayer else {
            overlayLayer.path = nil
            return
        }

        let boundingBox = face.boundingBox
        let outerPoints = outerLips.pointsInImage(imageSize: CGSize(width: 1, height: 1))

        let path = CGMutablePath()

        // Convert Vision coordinates to view coordinates
        func convert(_ point: CGPoint) -> CGPoint {
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + point.y * boundingBox.height
            // Vision uses bottom-left origin, convert to top-left
            let viewPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: x, y: y))
            return viewPoint
        }

        // Draw outer lip path
        if !outerPoints.isEmpty {
            let first = convert(outerPoints[0])
            path.move(to: first)
            for i in 1..<outerPoints.count {
                path.addLine(to: convert(outerPoints[i]))
            }
            path.closeSubpath()
        }

        // Cut out inner lips for more realistic look
        if let innerLips {
            let innerPoints = innerLips.pointsInImage(imageSize: CGSize(width: 1, height: 1))
            if !innerPoints.isEmpty {
                let first = convert(innerPoints[0])
                path.move(to: first)
                for i in 1..<innerPoints.count {
                    path.addLine(to: convert(innerPoints[i]))
                }
                path.closeSubpath()
            }
        }

        overlayLayer.path = path
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = shadeColor.withAlphaComponent(0.55).cgColor
    }
}
