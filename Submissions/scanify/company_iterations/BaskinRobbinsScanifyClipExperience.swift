import SwiftUI
import SceneKit
import AVFoundation
import AudioToolbox

struct BaskinRobbinsScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/baskin-robbins/ar"
    static let clipName = "Scanify — Baskin-Robbins AR"
    static let clipDescription = "Scan a Baskin-Robbins barcode to reveal a birthday cake in AR."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        BaskinRobbinsARFlowView()
    }
}

// MARK: - Brand constants

private enum BRBrand {
    static let pink = Color(red: 1.0, green: 0.22, blue: 0.51)
    static let blue = Color(red: 0.0, green: 0.45, blue: 0.81)
    static let brown = Color(red: 0.29, green: 0.15, blue: 0.07)

    static let uiPink = UIColor(red: 1.0, green: 0.22, blue: 0.51, alpha: 1)
    static let uiBlue = UIColor(red: 0.0, green: 0.45, blue: 0.81, alpha: 1)
    static let uiBrown = UIColor(red: 0.29, green: 0.15, blue: 0.07, alpha: 1)
    static let uiVanilla = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
    static let uiMint = UIColor(red: 0.6, green: 0.95, blue: 0.85, alpha: 1)
    static let uiStrawberry = UIColor(red: 1.0, green: 0.7, blue: 0.78, alpha: 1)
}

// MARK: - Main flow

private struct BaskinRobbinsARFlowView: View {
    @State private var cakeRevealed = false
    @State private var celebrationText = false

    var body: some View {
        ZStack {
            if cakeRevealed {
                cakeRevealView
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                scanningView
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.2), value: cakeRevealed)
    }

    // MARK: - Scanning phase

    private var scanningView: some View {
        ZStack {
            BRBarcodeScannerView { code in
                let normalized = code.lowercased().replacingOccurrences(of: " ", with: "")
                if normalized.contains("baskinrobbins") || normalized.contains("baskin-robbins") || normalized.contains("baskin") {
                    AudioServicesPlaySystemSound(1057)
                    #if !targetEnvironment(simulator)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    #endif
                    withAnimation { cakeRevealed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(duration: 0.5)) { celebrationText = true }
                    }
                }
            }
            .ignoresSafeArea()

            scannerOverlay
        }
    }

    private var scannerOverlay: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [BRBrand.pink.opacity(0.85), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .ignoresSafeArea(edges: .top)

                Spacer()

                LinearGradient(
                    colors: [.clear, BRBrand.brown.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .ignoresSafeArea(edges: .bottom)
            }

            VStack(spacing: 0) {
                Image("baskinrobbins_logo", bundle: .main)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 70)
                    .padding(.top, 56)

                Text("AR Cake Experience")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.top, 6)

                Spacer()

                BRBarcodeScanFrame()
                    .frame(width: 300, height: 180)

                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: true)

                    Text("Scan Baskin-Robbins Barcode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Point at the barcode to reveal your cake")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Cake reveal phase

    private var cakeRevealView: some View {
        ZStack {
            BRCakeSceneView()
                .ignoresSafeArea()

            BRConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Button {
                        withAnimation {
                            cakeRevealed = false
                            celebrationText = false
                        }
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    Spacer()
                    Image("baskinrobbins_logo", bundle: .main)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 58)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                if celebrationText {
                    celebrationOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var celebrationOverlay: some View {
        VStack(spacing: 14) {
            Text("Your Birthday Cake")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BRBrand.pink, BRBrand.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Baskin-Robbins · Made to Celebrate")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button {
                // Order action placeholder
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14))
                    Text("Order This Cake")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [BRBrand.pink, Color(red: 0.85, green: 0.1, blue: 0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 4)

            Button {
                // Customize action placeholder
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 14))
                    Text("Customize")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(BRBrand.pink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(BRBrand.pink, lineWidth: 2)
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 6)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 28)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
    }
}

// MARK: - Barcode Scanner

private struct BRBarcodeScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BRBarcodeScannerViewController {
        let vc = BRBarcodeScannerViewController()
        vc.onBarcodeScanned = onBarcodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BRBarcodeScannerViewController, context: Context) {}
}

private final class BRBarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private var isSessionConfigured = false

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
        guard isSessionConfigured else { return }
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning { captureSession.stopRunning() }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if captureSession.canAddInput(input) { captureSession.addInput(input) }

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
        previewLayer = preview

        isSessionConfigured = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        hasScanned = true
        onBarcodeScanned?(value)
    }
}

// MARK: - Barcode Scan Frame

private struct BRBarcodeScanFrame: View {
    @State private var animateScan = false
    @State private var pulseCorners = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.25), lineWidth: 1.5)

            BRCorners(color: BRBrand.pink)
                .scaleEffect(pulseCorners ? 1.02 : 0.98)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseCorners
                )

            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [.clear, BRBrand.pink, BRBrand.blue, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.horizontal, 24)
                .offset(y: animateScan ? 70 : -70)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: animateScan
                )
        }
        .onAppear {
            animateScan = true
            pulseCorners = true
        }
    }
}

private struct BRCorners: View {
    let color: Color
    private let length: CGFloat = 40
    private let lineWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: 0, y: length))
                p.addLine(to: CGPoint(x: 0, y: 8))
                p.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: length, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: w - length, y: 0))
                p.addLine(to: CGPoint(x: w - 8, y: 0))
                p.addQuadCurve(to: CGPoint(x: w, y: 8), control: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: length))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: 0, y: h - length))
                p.addLine(to: CGPoint(x: 0, y: h - 8))
                p.addQuadCurve(to: CGPoint(x: 8, y: h), control: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: length, y: h))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: w - length, y: h))
                p.addLine(to: CGPoint(x: w - 8, y: h))
                p.addQuadCurve(to: CGPoint(x: w, y: h - 8), control: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: w, y: h - length))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - GLB Loader (minimal parser for cake.glb — supports baseColorTexture + TEXCOORD_0)

private enum BRGLBLoader {
    static func load(url: URL) -> SCNNode? {
        guard let data = try? Data(contentsOf: url),
              data.count >= 20 else { return nil }
        let header = data.prefix(12)
        guard header.prefix(4).elementsEqual([0x67, 0x6C, 0x54, 0x46]) else { return nil } // "glTF"
        var offset = 12
        var jsonData: Data?
        var binData: Data?
        while offset + 8 <= data.count {
            let chunkLen = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }.littleEndian
            let chunkType = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }.littleEndian
            offset += 8
            guard offset + Int(chunkLen) <= data.count else { break }
            let chunk = data.subdata(in: offset..<(offset + Int(chunkLen)))
            offset += Int(chunkLen)
            if chunkType == 0x4E4F534A { jsonData = chunk }
            else if chunkType == 0x004E4942 { binData = chunk }
        }
        guard let json = jsonData,
              let bin = binData,
              let jsonObj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let meshes = jsonObj["meshes"] as? [[String: Any]],
              let accessors = jsonObj["accessors"] as? [[String: Any]],
              let bufferViews = jsonObj["bufferViews"] as? [[String: Any]] else { return nil }
        let materials = (jsonObj["materials"] as? [[String: Any]]) ?? []
        let textures = (jsonObj["textures"] as? [[String: Any]]) ?? []
        let images = (jsonObj["images"] as? [[String: Any]]) ?? []
        let container = SCNNode()
        for meshObj in meshes {
            guard let primitives = meshObj["primitives"] as? [[String: Any]] else { continue }
            for prim in primitives {
                guard let attrs = prim["attributes"] as? [String: Any],
                      let posIdx = attrs["POSITION"] as? Int,
                      posIdx < accessors.count else { continue }
                let posAcc = accessors[posIdx]
                guard let bvIdx = posAcc["bufferView"] as? Int,
                      let count = posAcc["count"] as? Int,
                      let compType = posAcc["componentType"] as? Int,
                      bvIdx < bufferViews.count,
                      compType == 5126 else { continue } // FLOAT
                let bv = bufferViews[bvIdx]
                let bvOffset = (bv["byteOffset"] as? Int) ?? 0
                guard let bvLen = bv["byteLength"] as? Int else { continue }
                let accOffset = (posAcc["byteOffset"] as? Int) ?? 0
                let start = bvOffset + accOffset
                guard start + bvLen <= bin.count, bvLen >= count * 12 else { continue }
                var verts: [SCNVector3] = []
                bin.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
                    let base = ptr.baseAddress!.advanced(by: start).assumingMemoryBound(to: Float.self)
                    for i in 0..<count {
                        verts.append(SCNVector3(base[i*3], base[i*3+1], base[i*3+2]))
                    }
                }
                // TEXCOORD_0 for texture mapping
                var uvs: [CGPoint]?
                if let tcIdx = attrs["TEXCOORD_0"] as? Int, tcIdx < accessors.count {
                    let tcAcc = accessors[tcIdx]
                    let tcbvIdx = tcAcc["bufferView"] as? Int
                    let tcCount = tcAcc["count"] as? Int
                    let tcComp = tcAcc["componentType"] as? Int
                    if let tbv = tcbvIdx, let tc = tcCount, let comp = tcComp,
                       tbv < bufferViews.count, comp == 5126, tc == count {
                        let tcbv = bufferViews[tbv]
                        let tcbvOff = (tcbv["byteOffset"] as? Int) ?? 0
                        let tcAccOff = (tcAcc["byteOffset"] as? Int) ?? 0
                        let tcStart = tcbvOff + tcAccOff
                        if tcStart + tc * 8 <= bin.count {
                            var uvList: [CGPoint] = []
                            uvList.reserveCapacity(tc)
                            bin.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
                                let base = p.baseAddress!.advanced(by: tcStart).assumingMemoryBound(to: Float.self)
                                for i in 0..<tc {
                                    uvList.append(CGPoint(x: CGFloat(base[i*2]), y: CGFloat(base[i*2+1])))
                                }
                            }
                            uvs = uvList
                        }
                    }
                }
                if uvs == nil {
                    uvs = (0..<count).map { _ in CGPoint(x: 0, y: 0) }
                }

                let indices: [Int32]?
                if let idxAccIdx = prim["indices"] as? Int, idxAccIdx < accessors.count {
                    let idxAcc = accessors[idxAccIdx]
                    guard let idxBv = idxAcc["bufferView"] as? Int,
                          let idxCount = idxAcc["count"] as? Int,
                          let idxComp = idxAcc["componentType"] as? Int,
                          idxBv < bufferViews.count else { indices = nil; break }
                    let idxBvObj = bufferViews[idxBv]
                    let idxOffset = (idxBvObj["byteOffset"] as? Int) ?? 0
                    let idxAccOff = (idxAcc["byteOffset"] as? Int) ?? 0
                    let idxStart = idxOffset + idxAccOff
                    let compSize = idxComp == 5125 ? 4 : 2
                    guard idxStart + idxCount * compSize <= bin.count else { indices = nil; break }
                    var idxList: [Int32] = []
                    bin.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
                        if compSize == 4 {
                            let base = p.baseAddress!.advanced(by: idxStart).assumingMemoryBound(to: UInt32.self)
                            for i in 0..<idxCount { idxList.append(Int32(bitPattern: base[i].littleEndian)) }
                        } else {
                            let base = p.baseAddress!.advanced(by: idxStart).assumingMemoryBound(to: UInt16.self)
                            for i in 0..<idxCount { idxList.append(Int32(base[i].littleEndian)) }
                        }
                    }
                    indices = idxList
                } else {
                    indices = nil
                }

                let diffuseImage = materialBaseColorTexture(
                    prim["material"] as? Int,
                    materials: materials,
                    textures: textures,
                    images: images,
                    bufferViews: bufferViews,
                    bin: bin
                )
                let baseColor = materialBaseColor(for: prim["material"] as? Int, materials: materials)
                let geo = makeGeometry(
                    vertices: verts,
                    texcoords: uvs ?? (0..<verts.count).map { _ in CGPoint(x: 0, y: 0) },
                    indices: indices,
                    diffuseImage: diffuseImage,
                    baseColor: baseColor
                )
                let node = SCNNode(geometry: geo)
                container.addChildNode(node)
            }
        }
        guard !container.childNodes.isEmpty else { return nil }
        return container
    }

    /// Extract base color texture (JPEG/PNG) from GLB for the given material.
    private static func materialBaseColorTexture(
        _ matIndex: Int?,
        materials: [[String: Any]],
        textures: [[String: Any]],
        images: [[String: Any]],
        bufferViews: [[String: Any]],
        bin: Data
    ) -> UIImage? {
        guard let mi = matIndex, mi >= 0, mi < materials.count else { return nil }
        let mat = materials[mi]
        guard let pbr = mat["pbrMetallicRoughness"] as? [String: Any],
              let texObj = pbr["baseColorTexture"] as? [String: Any],
              let texIdx = texObj["index"] as? Int,
              texIdx >= 0, texIdx < textures.count else { return nil }
        let tex = textures[texIdx]
        guard let srcIdx = tex["source"] as? Int, srcIdx >= 0, srcIdx < images.count else { return nil }
        let imgObj = images[srcIdx]
        guard let bvIdx = imgObj["bufferView"] as? Int, bvIdx < bufferViews.count else { return nil }
        let bv = bufferViews[bvIdx]
        let offset = (bv["byteOffset"] as? Int) ?? 0
        guard let len = bv["byteLength"] as? Int, offset + len <= bin.count else { return nil }
        let imageData = bin.subdata(in: offset..<(offset + len))
        return UIImage(data: imageData)
    }

    /// Read PBR baseColorFactor [r,g,b,a] from materials[matIndex]; return nil to use default.
    private static func materialBaseColor(for matIndex: Int?, materials: [[String: Any]]) -> UIColor? {
        guard let i = matIndex, i >= 0, i < materials.count else { return nil }
        let mat = materials[i]
        guard let pbr = mat["pbrMetallicRoughness"] as? [String: Any],
              let factor = pbr["baseColorFactor"] as? [Any],
              factor.count >= 4 else { return nil }
        func f(_ x: Any) -> CGFloat {
            if let n = x as? NSNumber { return CGFloat(n.doubleValue) }
            return 1
        }
        return UIColor(red: f(factor[0]), green: f(factor[1]), blue: f(factor[2]), alpha: f(factor[3]))
    }

    private static func makeGeometry(
        vertices: [SCNVector3],
        texcoords: [CGPoint],
        indices: [Int32]?,
        diffuseImage: UIImage?,
        baseColor: UIColor?
    ) -> SCNGeometry {
        let vertData = Data(bytes: vertices, count: vertices.count * MemoryLayout<SCNVector3>.size)
        let vertexSource = SCNGeometrySource(
            data: vertData,
            semantic: .vertex,
            vectorCount: vertices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )
        var uvFloats: [Float] = []
        uvFloats.reserveCapacity(texcoords.count * 2)
        for p in texcoords {
            uvFloats.append(Float(p.x))
            uvFloats.append(Float(p.y))
        }
        let uvData = Data(bytes: uvFloats, count: uvFloats.count * MemoryLayout<Float>.size)
        let uvSource = SCNGeometrySource(
            data: uvData,
            semantic: .texcoord,
            vectorCount: texcoords.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 2
        )
        let element: SCNGeometryElement
        if let idx = indices, !idx.isEmpty {
            var idxData = idx
            element = SCNGeometryElement(
                data: Data(bytes: &idxData, count: idx.count * MemoryLayout<Int32>.size),
                primitiveType: .triangles,
                primitiveCount: idx.count / 3,
                bytesPerIndex: MemoryLayout<Int32>.size
            )
        } else {
            var seq = (0..<vertices.count).map { Int32($0) }
            element = SCNGeometryElement(
                data: Data(bytes: &seq, count: seq.count * MemoryLayout<Int32>.size),
                primitiveType: .triangles,
                primitiveCount: max(0, vertices.count / 3),
                bytesPerIndex: MemoryLayout<Int32>.size
            )
        }
        let geo = SCNGeometry(sources: [vertexSource, uvSource], elements: [element])
        let mat = SCNMaterial()
        if let img = diffuseImage {
            mat.diffuse.contents = img
        } else {
            mat.diffuse.contents = baseColor ?? UIColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 1)
        }
        mat.roughness.contents = 0.8
        mat.metalness.contents = 0.0
        mat.lightingModel = .physicallyBased
        mat.locksAmbientWithDiffuse = true
        geo.materials = [mat]
        return geo
    }
}

// MARK: - 3D Cake Scene

private struct BRCakeSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = BRCakeBuilder.buildScene()
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        DispatchQueue.main.async {
            guard let cakeNode = scnView.scene?.rootNode.childNodes.first else { return }
            let finalPos = cakeNode.simdPosition
            let startPos = SIMD3<Float>(finalPos.x, finalPos.y - 1.4, finalPos.z)
            cakeNode.simdPosition = startPos
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)
            cakeNode.simdPosition = finalPos
            SCNTransaction.commit()
        }
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

private enum BRCakeBuilder {
    static func buildScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let cakeRoot: SCNNode
        if let loadedRoot = loadCakeFromBundle() {
            cakeRoot = loadedRoot
        } else {
            cakeRoot = SCNNode()
            addPlatform(to: cakeRoot)
            addBottomTier(to: cakeRoot)
            addMiddleTier(to: cakeRoot)
            addTopTier(to: cakeRoot)
            addIceCreamScoops(to: cakeRoot)
            addCandles(to: cakeRoot)
            addSprinkles(to: cakeRoot)
        }

        scene.rootNode.addChildNode(cakeRoot)
        addLighting(to: scene)
        addCamera(to: scene)
        addRotation(to: cakeRoot)
        addSparkleParticles(to: scene)

        return scene
    }

    /// Loads the cake from bundle: tries cake.glb (parsed) then cake.usdz. Only from Submissions/scanify (public or Resources).
    private static func loadCakeFromBundle() -> SCNNode? {
        let bundle = Bundle.main

        // 1) GLB from Submissions/scanify/public (canonical location)
        if let glbURL = bundle.url(forResource: "cake", withExtension: "glb", subdirectory: "Submissions/scanify/public")
            ?? bundle.url(forResource: "cake", withExtension: "glb") {
            if let node = BRGLBLoader.load(url: glbURL) {
                scaleAndCenterCake(node)
                return node
            }
        }

        // 2) USDZ if present under scanify
        if let usdzURL = bundle.url(forResource: "cake", withExtension: "usdz", subdirectory: "Submissions/scanify/public")
            ?? bundle.url(forResource: "cake", withExtension: "usdz") {
            if let node = loadUSDZ(url: usdzURL) { return node }
        }

        return nil
    }

    private static func loadGLB(url: URL) -> SCNNode? {
        guard let node = BRGLBLoader.load(url: url) else { return nil }
        scaleAndCenterCake(node)
        return node
    }

    private static func loadUSDZ(url: URL) -> SCNNode? {
        guard let scene = try? SCNScene(url: url) else { return nil }
        let container = SCNNode()
        for child in scene.rootNode.childNodes {
            container.addChildNode(child.clone())
        }
        scaleAndCenterCake(container)
        return container
    }

    /// Scale and center the loaded model for viewing (GLB/USDZ can have arbitrary units).
    private static func scaleAndCenterCake(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let size = SCNVector3(
            max.x - min.x,
            max.y - min.y,
            max.z - min.z
        )
        let maxDim = Swift.max(size.x, Swift.max(size.y, size.z))
        guard maxDim > 0 else { return }
        let scale = 2.5 / Float(maxDim)
        node.simdScale = SIMD3<Float>(scale, scale, scale)
        node.simdPosition = SIMD3<Float>(
            -0.5 * (min.x + max.x) * scale,
            -0.5 * (min.y + max.y) * scale,
            -0.5 * (min.z + max.z) * scale
        )
        // Shift cake upward so it sits higher in frame
        node.simdPosition.y += 1.65
    }

    // MARK: Platform

    private static func addPlatform(to root: SCNNode) {
        let plate = SCNCylinder(radius: 2.2, height: 0.08)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 0.92, alpha: 1)
        mat.metalness.contents = 0.6
        mat.roughness.contents = 0.15
        plate.materials = [mat]
        let node = SCNNode(geometry: plate)
        node.position = SCNVector3(0, -0.04, 0)
        root.addChildNode(node)

        let rim = SCNTorus(ringRadius: 2.2, pipeRadius: 0.04)
        let rimMat = SCNMaterial()
        rimMat.diffuse.contents = UIColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 1)
        rimMat.metalness.contents = 0.8
        rimMat.roughness.contents = 0.1
        rim.materials = [rimMat]
        let rimNode = SCNNode(geometry: rim)
        rimNode.position = SCNVector3(0, 0, 0)
        root.addChildNode(rimNode)
    }

    // MARK: Cake tiers

    private static func addBottomTier(to root: SCNNode) {
        let tier = makeTier(radius: 1.8, height: 0.7, color: BRBrand.uiBrown)
        tier.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(tier)

        let frosting = SCNTorus(ringRadius: 1.8, pipeRadius: 0.1)
        let fMat = SCNMaterial()
        fMat.diffuse.contents = BRBrand.uiPink
        fMat.roughness.contents = 0.7
        frosting.materials = [fMat]
        let fNode = SCNNode(geometry: frosting)
        fNode.position = SCNVector3(0, 0.7, 0)
        root.addChildNode(fNode)
    }

    private static func addMiddleTier(to root: SCNNode) {
        let tier = makeTier(radius: 1.3, height: 0.6, color: BRBrand.uiStrawberry)
        tier.position = SCNVector3(0, 1.0, 0)
        root.addChildNode(tier)

        let frosting = SCNTorus(ringRadius: 1.3, pipeRadius: 0.08)
        let fMat = SCNMaterial()
        fMat.diffuse.contents = BRBrand.uiBlue
        fMat.roughness.contents = 0.7
        frosting.materials = [fMat]
        let fNode = SCNNode(geometry: frosting)
        fNode.position = SCNVector3(0, 1.3, 0)
        root.addChildNode(fNode)
    }

    private static func addTopTier(to root: SCNNode) {
        let tier = makeTier(radius: 0.85, height: 0.5, color: BRBrand.uiVanilla)
        tier.position = SCNVector3(0, 1.55, 0)
        root.addChildNode(tier)

        let frosting = SCNTorus(ringRadius: 0.85, pipeRadius: 0.07)
        let fMat = SCNMaterial()
        fMat.diffuse.contents = BRBrand.uiPink.withAlphaComponent(0.9)
        fMat.roughness.contents = 0.7
        frosting.materials = [fMat]
        let fNode = SCNNode(geometry: frosting)
        fNode.position = SCNVector3(0, 1.8, 0)
        root.addChildNode(fNode)
    }

    private static func makeTier(radius: CGFloat, height: CGFloat, color: UIColor) -> SCNNode {
        let geo = SCNCylinder(radius: radius, height: height)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.roughness.contents = 0.8
        mat.lightingModel = .physicallyBased
        geo.materials = [mat]
        return SCNNode(geometry: geo)
    }

    // MARK: Ice cream scoops

    private static func addIceCreamScoops(to root: SCNNode) {
        let scoopColors: [UIColor] = [
            BRBrand.uiPink,
            BRBrand.uiMint,
            BRBrand.uiVanilla,
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
            UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 1),
        ]

        let scoopRadius: CGFloat = 0.32
        let centerY: Float = 2.1
        let ringRadius: Float = 0.45

        for (i, color) in scoopColors.enumerated() {
            let sphere = SCNSphere(radius: scoopRadius)
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            mat.roughness.contents = 0.85
            mat.lightingModel = .physicallyBased
            sphere.materials = [mat]
            let node = SCNNode(geometry: sphere)
            let angle = Float(i) * (2 * .pi / Float(scoopColors.count))
            node.position = SCNVector3(
                ringRadius * cos(angle),
                centerY,
                ringRadius * sin(angle)
            )
            root.addChildNode(node)
        }

        let topScoop = SCNSphere(radius: 0.25)
        let topMat = SCNMaterial()
        topMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.9, alpha: 1)
        topMat.roughness.contents = 0.85
        topMat.lightingModel = .physicallyBased
        topScoop.materials = [topMat]
        let topNode = SCNNode(geometry: topScoop)
        topNode.position = SCNVector3(0, 2.45, 0)
        root.addChildNode(topNode)
    }

    // MARK: Candles

    private static func addCandles(to root: SCNNode) {
        let candlePositions: [(Float, Float)] = [
            (-0.3, -0.3), (0.3, -0.3), (0.0, 0.35), (-0.35, 0.15), (0.35, 0.15)
        ]
        let candleColors: [UIColor] = [.systemPink, .systemBlue, .systemYellow, .systemPink, .systemBlue]

        for (i, (x, z)) in candlePositions.enumerated() {
            let stick = SCNCylinder(radius: 0.03, height: 0.5)
            let sMat = SCNMaterial()
            sMat.diffuse.contents = candleColors[i]
            sMat.roughness.contents = 0.3
            stick.materials = [sMat]
            let sNode = SCNNode(geometry: stick)
            sNode.position = SCNVector3(x, 2.55, z)
            root.addChildNode(sNode)

            let stripe = SCNCylinder(radius: 0.035, height: 0.06)
            let stripeMat = SCNMaterial()
            stripeMat.diffuse.contents = UIColor.white
            stripe.materials = [stripeMat]
            for j in 0..<3 {
                let stripeNode = SCNNode(geometry: stripe)
                stripeNode.position = SCNVector3(x, 2.38 + Float(j) * 0.14, z)
                root.addChildNode(stripeNode)
            }

            let flame = SCNSphere(radius: 0.045)
            let fMat = SCNMaterial()
            fMat.diffuse.contents = UIColor.orange
            fMat.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
            fMat.emission.intensity = 2.0
            fMat.lightingModel = .constant
            flame.materials = [fMat]
            let fNode = SCNNode(geometry: flame)
            fNode.position = SCNVector3(x, 2.85, z)
            root.addChildNode(fNode)

            let glow = SCNLight()
            glow.type = .omni
            glow.color = UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
            glow.intensity = 60
            glow.attenuationStartDistance = 0
            glow.attenuationEndDistance = 1.0
            fNode.light = glow
        }
    }

    // MARK: Sprinkles

    private static func addSprinkles(to root: SCNNode) {
        let sprinkleColors: [UIColor] = [
            .systemPink, .systemBlue, .systemYellow, .systemGreen,
            .systemOrange, .systemPurple, .white
        ]

        for tier in 0..<3 {
            let (radius, baseY, tierHeight): (Float, Float, Float) = [
                (1.8, 0.0, 0.7),
                (1.3, 0.7, 0.6),
                (0.85, 1.3, 0.5),
            ][tier]

            for _ in 0..<20 {
                let sprinkle = SCNCapsule(capRadius: 0.015, height: 0.08)
                let mat = SCNMaterial()
                mat.diffuse.contents = sprinkleColors.randomElement()!
                mat.roughness.contents = 0.3
                sprinkle.materials = [mat]
                let node = SCNNode(geometry: sprinkle)

                let angle = Float.random(in: 0...(2 * .pi))
                let r = Float(radius) * Float.random(in: 0.85...1.0)
                let y = baseY + Float.random(in: 0.05...(tierHeight - 0.05))

                node.position = SCNVector3(r * cos(angle), y, r * sin(angle))
                node.eulerAngles = SCNVector3(
                    Float.random(in: 0...(2 * .pi)),
                    Float.random(in: 0...(2 * .pi)),
                    Float.random(in: 0...(2 * .pi))
                )
                root.addChildNode(node)
            }
        }
    }

    // MARK: Lighting

    private static func addLighting(to scene: SCNScene) {
        let keyLight = SCNLight()
        keyLight.type = .spot
        keyLight.color = UIColor(white: 1.0, alpha: 1)
        keyLight.intensity = 1200
        keyLight.spotInnerAngle = 30
        keyLight.spotOuterAngle = 60
        keyLight.castsShadow = true
        keyLight.shadowRadius = 8
        keyLight.shadowColor = UIColor(white: 0, alpha: 0.4)
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(3, 6, 4)
        keyNode.look(at: SCNVector3(0, 1.2, 0))
        scene.rootNode.addChildNode(keyNode)

        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.color = UIColor(red: 1.0, green: 0.9, blue: 0.95, alpha: 1)
        fillLight.intensity = 300
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-3, 3, 2)
        scene.rootNode.addChildNode(fillNode)

        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.color = UIColor(red: 0.8, green: 0.85, blue: 1.0, alpha: 1)
        rimLight.intensity = 200
        let rimNode = SCNNode()
        rimNode.light = rimLight
        rimNode.position = SCNVector3(0, 2, -4)
        scene.rootNode.addChildNode(rimNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.25, alpha: 1)
        ambient.intensity = 400
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }

    // MARK: Camera

    private static func addCamera(to scene: SCNScene) {
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 100
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 3.5, 7)
        cameraNode.look(at: SCNVector3(0, 1.2, 0))
        scene.rootNode.addChildNode(cameraNode)
    }

    // MARK: Rotation animation

    private static func addRotation(to node: SCNNode) {
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 12
        rotation.repeatCount = .infinity
        node.addAnimation(rotation, forKey: "spin")
    }

    // MARK: Sparkle particles

    private static func addSparkleParticles(to scene: SCNScene) {
        let particle = SCNParticleSystem()
        particle.emitterShape = SCNCylinder(radius: 2.5, height: 3.5)
        particle.birthRate = 15
        particle.particleLifeSpan = 3.0
        particle.particleLifeSpanVariation = 1.5
        particle.particleSize = 0.04
        particle.particleSizeVariation = 0.02
        particle.particleColor = .white
        particle.particleColorVariation = SCNVector4(0.3, 0.3, 0.3, 0)
        particle.blendMode = .additive
        particle.emittingDirection = SCNVector3(0, 1, 0)
        particle.spreadingAngle = 180
        particle.particleVelocity = 0.3
        particle.particleVelocityVariation = 0.2
        particle.particleAngularVelocity = 90
        particle.particleAngularVelocityVariation = 45

        let sparkleNode = SCNNode()
        sparkleNode.position = SCNVector3(0, 1.5, 0)
        sparkleNode.addParticleSystem(particle)
        scene.rootNode.addChildNode(sparkleNode)
    }
}

// MARK: - Confetti Effect

private struct BRConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -20)
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitter.emitterShape = .line
        emitter.renderMode = .additive

        let colors: [UIColor] = [
            BRBrand.uiPink, BRBrand.uiBlue, .systemYellow,
            .systemGreen, .systemOrange, .white, BRBrand.uiStrawberry
        ]

        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 6
            cell.velocity = 120
            cell.velocityRange = 40
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 4
            cell.scale = 0.06
            cell.scaleRange = 0.03
            cell.contents = confettiImage(color: color)
            cell.alphaSpeed = -0.15
            cell.yAcceleration = 60
            return cell
        }

        view.layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            emitter.birthRate = 0
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func confettiImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 12, height: 6)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 1.5).fill()
        return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    }
}
