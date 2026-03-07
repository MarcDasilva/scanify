import SwiftUI
import AudioToolbox
import AVFoundation
import Vision

struct SephoraScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/sephora/scan"
    static let clipName = "Scanify — Sephora"
    static let clipDescription = "Scan cosmetics for virtual try-on, shades, and checkout."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        SephoraScanifyFlowView(
            storeBranding: StoreBranding.forStoreId("sephora"),
            allowedCategory: .cosmetics
        )
    }
}

// MARK: - Sephora flow

private struct SephoraScanifyFlowView: View {
    let storeBranding: StoreBranding
    var allowedCategory: ProductCategory?

    @State private var scannedProduct: ScannedProduct?
    @State private var showSuccess = false
    @State private var showProductNotFound = false
    @State private var lastUnknownBarcode: String = ""
    @State private var scanHistory: [ScannedProduct] = []

    private var demoProducts: [ScannedProduct] {
        if let cat = allowedCategory {
            return ScanifyMockData.allProducts.filter { $0.category == cat }
        }
        return ScanifyMockData.allProducts
    }

    var body: some View {
        ZStack {
            if showSuccess {
                successView
                    .transition(.scale.combined(with: .opacity))
            } else {
                cameraScanner
            }
        }
        .animation(.spring(duration: 0.35), value: showSuccess)
        .sheet(item: $scannedProduct) { product in
            SephoraScanifySheet(
                product: product,
                storeBranding: storeBranding,
                onDismiss: { scannedProduct = nil },
                onOrderComplete: {
                    scannedProduct = nil
                    withAnimation(.spring(duration: 0.4)) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showSuccess = false }
                    }
                }
            )
        }
        .alert("Product Not Found", isPresented: $showProductNotFound) {
            Button("Scan Again", role: .cancel) {}
        } message: {
            Text(productNotFoundMessage)
        }
    }

    private var productNotFoundMessage: String {
        if lastUnknownBarcode.isEmpty { return "" }
        if allowedCategory != nil {
            return "This product isn't available at \(storeBranding.displayName). Try one of the sample products below."
        }
        return "Barcode \(lastUnknownBarcode) is not in our demo database. Try one of the sample products."
    }

    private var cameraScanner: some View {
        ZStack {
            ScanifyBarcodeScannerView(
                onBarcodeScanned: { barcode in handleBarcode(barcode) },
                isActive: scannedProduct == nil && !showSuccess && !showProductNotFound
            )
            .ignoresSafeArea()

            ScannerOverlayView(storeBranding: storeBranding)
                .ignoresSafeArea()

            VStack {
                if !scanHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(scanHistory) { product in
                                Button { scannedProduct = product } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon)
                                            .font(.system(size: 10))
                                            .foregroundStyle(product.category.accentColor)
                                        Text(product.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.15), in: .capsule)
                                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                VStack(spacing: 8) {
                    Text("Demo Products")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(demoProducts) { product in
                                Button { handleBarcode(product.barcode) } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: product.category.icon)
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
    }

    private func handleBarcode(_ barcode: String) {
        guard let product = ScanifyMockData.lookup(barcode: barcode) else {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        if let allowed = allowedCategory, product.category != allowed {
            lastUnknownBarcode = barcode
            showProductNotFound = true
            return
        }
        AudioServicesPlaySystemSound(1057)
        scannedProduct = product
        withAnimation(.spring(duration: 0.3)) {
            scanHistory.removeAll { $0.barcode == product.barcode }
            scanHistory.insert(product, at: 0)
            if scanHistory.count > 5 { scanHistory = Array(scanHistory.prefix(5)) }
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            ClipSuccessOverlay(message: "Order placed!\nShipping to your address in 2-3 business days.")
            Spacer()
        }
    }
}

// MARK: - Sephora sheet (cosmetics → CosmeticsView + checkout)

private struct SephoraScanifySheet: View {
    let product: ScannedProduct
    let storeBranding: StoreBranding
    let onDismiss: () -> Void
    let onOrderComplete: () -> Void

    @State private var showCheckout = false
    @State private var checkoutVariant: String = ""
    @State private var showShareSheet = false

    private var shareText: String {
        "Scanify Report: \(product.name) by \(product.brand) — $\(String(format: "%.2f", product.price))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .cosmetics(let data) = product.categoryData {
                    ScanifyCosmeticsView(product: product, data: data) { shade in
                        checkoutVariant = shade
                        showCheckout = true
                    }
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showCheckout) {
            ScanifyCheckoutView(
                product: product,
                variant: checkoutVariant,
                accentColor: storeBranding.accentColor,
                onComplete: {
                    showCheckout = false
                    onOrderComplete()
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ScanifyShareSheet(items: [shareText])
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Sephora category view (cosmetics: virtual try-on)

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

                ZStack {
                    if showCamera {
                        ScanifyFaceCameraView(shadeColor: shadeUIColor)
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
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

                shadePicker
                detailsSection

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
            showCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        }
    }

    private var shadePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a shade to try it on")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.shades) { shade in
                        Button {
                            withAnimation(.spring(duration: 0.25)) { selectedShade = shade }
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

// MARK: - Face camera for virtual try-on (Sephora)

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

        func convert(_ point: CGPoint) -> CGPoint {
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + point.y * boundingBox.height
            let viewPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: x, y: y))
            return viewPoint
        }

        if !outerPoints.isEmpty {
            let first = convert(outerPoints[0])
            path.move(to: first)
            for i in 1..<outerPoints.count {
                path.addLine(to: convert(outerPoints[i]))
            }
            path.closeSubpath()
        }

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
