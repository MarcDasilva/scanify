import SwiftUI

struct SephoraScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/sephora/scan"
    static let clipName = "Scanify — Sephora"
    static let clipDescription = "Scan cosmetics for virtual try-on, shades, and checkout."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ScanifyScannerView(
            storeBranding: StoreBranding.forStoreId("sephora"),
            allowedCategory: .cosmetics
        )
    }
}
