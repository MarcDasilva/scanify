import SwiftUI
import AudioToolbox
import AVFoundation
import Vision
import ARKit
import SceneKit

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
            return "This product isn't available at \(storeBranding.displayName)."
        }
        return "Barcode \(lastUnknownBarcode) is not in our database."
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

            VStack(spacing: 0) {
                Image("sephora_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 130)
                    .padding(.top, 44)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.white, .white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )

                Spacer()
            }

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

                Spacer()
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

// MARK: - Sephora category view (cosmetics: product page + try-on)

/// Maps shade name to asset name for tint image (berry, rosewood, Satin).
private func tintImageName(for shade: Shade) -> String? {
    let n = shade.name.lowercased()
    if n.contains("berry") { return "berry" }
    if n.contains("rosewood") { return "rosewood" }
    if n.contains("satin") { return "Satin" }
    return nil
}

struct ScanifyCosmeticsView: View {
    let product: ScannedProduct
    let data: CosmeticsData
    let onBuyNow: (String) -> Void

    @State private var selectedShade: Shade?
    @State private var showTryOn = false
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
        Group {
            if showTryOn {
                tryOnView
            } else {
                productPageView
            }
        }
        .navigationTitle(showTryOn ? "Virtual Try-On" : "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        }
    }

    // MARK: - Sephora-style product page

    private var productPageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sephoraHeader
                breadcrumbs
                productTitleBlock
                productImageSection
                priceBlock
                colorAndSpecBlock
                shadePicker
                addToBasketButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var sephoraHeader: some View {
        HStack(spacing: 12) {
            Text("SEPHORA")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            Image(systemName: "heart")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            Image(systemName: "bag")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var breadcrumbs: some View {
        Text("Makeup > Lip > Lipstick")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
    }

    private var productTitleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.brand.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(product.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                    }
                }
                Text("1.6K")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Ask a question")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.blue)
                Spacer()
                Image(systemName: "heart")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("1.7M")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }

    /// Single image for the selected shade (tint from assets or color placeholder).
    private var productImageSection: some View {
        ZStack {
            // Full-width, full-height background (edge to edge, no gap to next section)
            Image("sephora_wallpaper", bundle: .main)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 260)
                .clipped()

            // Lipstick image on top with larger rounded corners
            Group {
                if let name = tintImageName(for: currentShade) {
                    Image(name, bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(scanifyHex: currentShade.hex).opacity(0.5))
                        .frame(height: 180)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 20)
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(String(format: "$%.2f", product.price))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    showTryOn = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Try It On")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.85, green: 0.15, blue: 0.2))
                    .clipShape(Capsule())
                }
            }
            Text("or 4 payments of $\(String(format: "%.2f", product.price / 4)) with Klarna or Afterpay")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Get It For $\(String(format: "%.2f", product.price * 0.95)) (5% Off) With Auto-Replenish")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var colorAndSpecBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("\(currentShade.name) – matte")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            HStack {
                Text("Size")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(data.volume)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            Text("Matte finish – Standard size")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var shadePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a shade")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)

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
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollClipDisabled(true)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private var addToBasketButton: some View {
        Button {
            onBuyNow(currentShade.name)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bag.fill")
                Text("Add to Basket")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(red: 0.85, green: 0.15, blue: 0.2))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Try-on camera view

    private var tryOnView: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                        Spacer()
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

                Button {
                    showTryOn = false
                } label: {
                    Text("Back to Product")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    showTryOn = false
                }
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
// Uses ARKit face tracking when available (Snapchat-style mesh-accurate overlay);
// falls back to Vision-based overlay on simulator or devices without face tracking.

struct ScanifyFaceCameraView: UIViewControllerRepresentable {
    let shadeColor: UIColor

    func makeUIViewController(context: Context) -> UIViewController {
        if ARFaceTrackingConfiguration.isSupported {
            let vc = ARFaceLipOverlayViewController()
            vc.shadeColor = shadeColor
            return vc
        } else {
            let vc = FaceCameraViewController()
            vc.shadeColor = shadeColor
            return vc
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let ar = uiViewController as? ARFaceLipOverlayViewController {
            ar.shadeColor = shadeColor
            ar.updateLipColor()
        } else if let vision = uiViewController as? FaceCameraViewController {
            vision.shadeColor = shadeColor
            vision.updateOverlayColor()
        }
    }
}

// MARK: - ARKit face tracking + lip overlay (Snapchat-style)
// Renders only the lip region of the 3D face mesh with the selected shade;
// mesh follows face exactly via ARFaceTrackingConfiguration.

final class ARFaceLipOverlayViewController: UIViewController, ARSCNViewDelegate {
    var shadeColor: UIColor = .red

    private var sceneView: ARSCNView!
    private var lipNode: SCNNode?
    /// Triangle indices into the face mesh that form the lip region (computed once).
    private var lipTriangleIndices: [Int32] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.antialiasingMode = .multisampling4X
        view.addSubview(sceneView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARFaceTrackingConfiguration()
        config.isWorldTrackingEnabled = false
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func updateLipColor() {
        lipNode?.geometry?.firstMaterial?.diffuse.contents = shadeColor
        lipNode?.geometry?.firstMaterial?.emission.contents = shadeColor.withAlphaComponent(0.15)
    }

    /// Best-practice lip mapping: lips are the *protruding* part of the mouth (highest Z in face space).
    /// We select a loose mouth region (Y,X), then keep only vertices in the *front* of that region (top Z percentile).
    /// This excludes skin around lips (philtrum, chin, perioral) and keeps only the lip surface.
    private func lipTriangleIndices(from geometry: ARFaceGeometry, useFallback: Bool = false) -> [Int32] {
        var vertexCount = 0
        geometry.vertices.withUnsafeBufferPointer { vBuf in
            vertexCount = vBuf.count
        }
        guard vertexCount > 0 else { return [] }

        // Step 1: Mouth region in Y,X only. Tighter on top (no skin above upper lip); wider horizontally (full lip width to corners).
        func inMouthRegion(_ p: SIMD3<Float>) -> Bool {
            let x = p.x, y = p.y
            if useFallback {
                return y > -0.068 && y < -0.022 && x > -0.080 && x < 0.080
            }
            // Upper Y -0.032: trim a bit more above upper lip. X ±0.080: wide enough to reach full lip corners.
            return y > -0.058 && y < -0.032 && x > -0.080 && x < 0.080
        }

        var mouthZValues: [Float] = []
        geometry.vertices.withUnsafeBufferPointer { vBuf in
            for i in 0..<vertexCount {
                if inMouthRegion(vBuf[i]) {
                    mouthZValues.append(vBuf[i].z)
                }
            }
        }
        guard mouthZValues.count >= 3 else {
            return lipTriangleIndicesBoxOnly(from: geometry, useFallback: useFallback)
        }

        // Step 2: Lips = front of mouth. Use 62nd percentile so only the actual lip surface (not skin above).
        mouthZValues.sort(by: <)
        let percentileIndex = Int(Float(mouthZValues.count) * 0.62)
        let zThreshold = mouthZValues[Swift.min(percentileIndex, mouthZValues.count - 1)]

        var lipVertexMask = [Bool](repeating: false, count: vertexCount)
        geometry.vertices.withUnsafeBufferPointer { vBuf in
            for i in 0..<vertexCount {
                lipVertexMask[i] = inMouthRegion(vBuf[i]) && vBuf[i].z >= zThreshold
            }
        }

        var indices: [Int32] = []
        geometry.triangleIndices.withUnsafeBufferPointer { tBuf in
            let triCount = tBuf.count / 3
            for t in 0..<triCount {
                let i0 = Int(tBuf[t * 3 + 0])
                let i1 = Int(tBuf[t * 3 + 1])
                let i2 = Int(tBuf[t * 3 + 2])
                guard i0 < vertexCount, i1 < vertexCount, i2 < vertexCount else { continue }
                if lipVertexMask[i0], lipVertexMask[i1], lipVertexMask[i2] {
                    indices.append(Int32(tBuf[t * 3 + 0]))
                    indices.append(Int32(tBuf[t * 3 + 1]))
                    indices.append(Int32(tBuf[t * 3 + 2]))
                }
            }
        }
        if indices.isEmpty {
            return lipTriangleIndicesBoxOnly(from: geometry, useFallback: useFallback)
        }
        return indices
    }

    /// Fallback when Z-percentile yields no triangles: use simple 3D box (may include area around lips).
    private func lipTriangleIndicesBoxOnly(from geometry: ARFaceGeometry, useFallback: Bool) -> [Int32] {
        var vertexCount = 0
        geometry.vertices.withUnsafeBufferPointer { vBuf in
            vertexCount = vBuf.count
        }
        guard vertexCount > 0 else { return [] }
        func inBox(_ p: SIMD3<Float>) -> Bool {
            let x = p.x, y = p.y, z = p.z
            if useFallback {
                return y > -0.068 && y < -0.022 && x > -0.080 && x < 0.080 && z > -0.04 && z < 0.055
            }
            // Match primary: less upper lip (y < -0.032), wider sides (x ±0.080).
            return y > -0.058 && y < -0.032 && x > -0.080 && x < 0.080 && z > -0.02 && z < 0.05
        }
        var lipVertexMask = [Bool](repeating: false, count: vertexCount)
        geometry.vertices.withUnsafeBufferPointer { vBuf in
            for i in 0..<vertexCount {
                lipVertexMask[i] = inBox(vBuf[i])
            }
        }
        var indices: [Int32] = []
        geometry.triangleIndices.withUnsafeBufferPointer { tBuf in
            let triCount = tBuf.count / 3
            for t in 0..<triCount {
                let i0 = Int(tBuf[t * 3 + 0])
                let i1 = Int(tBuf[t * 3 + 1])
                let i2 = Int(tBuf[t * 3 + 2])
                guard i0 < vertexCount, i1 < vertexCount, i2 < vertexCount else { continue }
                if lipVertexMask[i0], lipVertexMask[i1], lipVertexMask[i2] {
                    indices.append(Int32(tBuf[t * 3 + 0]))
                    indices.append(Int32(tBuf[t * 3 + 1]))
                    indices.append(Int32(tBuf[t * 3 + 2]))
                }
            }
        }
        return indices
    }

    private func makeLipGeometry(from faceGeometry: ARFaceGeometry) -> SCNGeometry? {
        var vertexCount = 0
        faceGeometry.vertices.withUnsafeBufferPointer { buf in
            vertexCount = buf.count
        }
        guard vertexCount > 0 else { return nil }

        var triIndices: [Int32]
        if lipTriangleIndices.isEmpty {
            let primary = lipTriangleIndices(from: faceGeometry, useFallback: false)
            if !primary.isEmpty {
                lipTriangleIndices = primary
                triIndices = primary
            } else {
                let fallback = lipTriangleIndices(from: faceGeometry, useFallback: true)
                lipTriangleIndices = fallback
                triIndices = fallback
            }
        } else {
            triIndices = lipTriangleIndices
        }
        if triIndices.isEmpty { return nil }

        var vertexData = [Float](repeating: 0, count: vertexCount * 3)
        faceGeometry.vertices.withUnsafeBufferPointer { buf in
            for i in 0..<vertexCount {
                vertexData[i * 3 + 0] = buf[i].x
                vertexData[i * 3 + 1] = buf[i].y
                vertexData[i * 3 + 2] = buf[i].z
            }
        }
        let vertexSource = SCNGeometrySource(
            data: Data(bytes: vertexData, count: vertexData.count * MemoryLayout<Float>.size),
            semantic: .vertex,
            vectorCount: vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 3
        )
        var indexData = triIndices
        let element = SCNGeometryElement(
            data: Data(bytes: &indexData, count: indexData.count * MemoryLayout<Int32>.size),
            primitiveType: .triangles,
            primitiveCount: indexData.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        let mat = SCNMaterial()
        mat.diffuse.contents = shadeColor
        mat.emission.contents = shadeColor.withAlphaComponent(0.12)
        mat.transparency = 0.72
        mat.isDoubleSided = true
        mat.fillMode = .fill
        geometry.materials = [mat]
        return geometry
    }
}

extension ARFaceLipOverlayViewController: ARSessionDelegate {}

extension ARFaceLipOverlayViewController {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor else { return nil }
        let container = SCNNode()
        // Mirror the overlay so it matches the front camera's mirrored preview (selfie view).
        container.scale = SCNVector3(-1, 1, 1)
        lipNode = SCNNode()
        container.addChildNode(lipNode!)
        return container
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let lip = lipNode else { return }
        let geometry = faceAnchor.geometry
        if lipTriangleIndices.isEmpty {
            lipTriangleIndices = lipTriangleIndices(from: geometry)
        }
        guard !lipTriangleIndices.isEmpty,
              let lipGeometry = makeLipGeometry(from: geometry) else { return }
        lip.geometry = lipGeometry
    }
}

// MARK: - Vision-based fallback (simulator / no face tracking)

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
        if let previewConnection = preview.connection, previewConnection.isVideoRotationAngleSupported(90) {
            previewConnection.videoRotationAngle = 90
        }
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

        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let imageSize = CGSize(width: imageWidth, height: imageHeight)

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
                self.drawLipOverlay(face: face, outerLips: outerLips, innerLips: innerLips, imageSize: imageSize)
            }
        }

        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
    }

    /// Draws lip overlay by mapping Vision face landmarks exactly to the preview layer.
    /// Vision uses image coordinates with origin bottom-left; AVCaptureVideoPreviewLayer
    /// expects normalized (0–1) capture device coordinates with origin top-left.
    private func drawLipOverlay(face: VNFaceObservation, outerLips: VNFaceLandmarkRegion2D?, innerLips: VNFaceLandmarkRegion2D?, imageSize: CGSize) {
        guard let outerLips, let previewLayer else {
            overlayLayer.path = nil
            return
        }

        let w = imageSize.width
        let h = imageSize.height
        guard w > 0, h > 0 else {
            overlayLayer.path = nil
            return
        }

        // Landmarks in image pixel space (Vision: origin bottom-left, y up).
        let outerPoints = outerLips.pointsInImage(imageSize: imageSize)

        let path = CGMutablePath()

        // Convert Vision image point (bottom-left origin) → normalized capture device (0–1, top-left) → layer point.
        func imageToLayer(_ point: CGPoint) -> CGPoint {
            let normX = point.x / w
            let normY = 1.0 - (point.y / h)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: normX, y: normY))
        }

        if !outerPoints.isEmpty {
            let first = imageToLayer(outerPoints[0])
            path.move(to: first)
            for i in 1..<outerPoints.count {
                path.addLine(to: imageToLayer(outerPoints[i]))
            }
            path.closeSubpath()
        }

        if let innerLips {
            let innerPoints = innerLips.pointsInImage(imageSize: imageSize)
            if !innerPoints.isEmpty {
                let first = imageToLayer(innerPoints[0])
                path.move(to: first)
                for i in 1..<innerPoints.count {
                    path.addLine(to: imageToLayer(innerPoints[i]))
                }
                path.closeSubpath()
            }
        }

        overlayLayer.path = path
        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = shadeColor.withAlphaComponent(0.55).cgColor
    }
}
