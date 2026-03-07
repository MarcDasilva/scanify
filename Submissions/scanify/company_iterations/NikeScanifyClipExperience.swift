import SwiftUI

struct NikeScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/nike/scan"
    static let clipName = "Scanify — Nike"
    static let clipDescription = "Scan apparel at Nike for sizing, stock, and checkout."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ScanifyScannerView(
            storeBranding: StoreBranding.forStoreId("nike"),
            allowedCategory: .apparel
        )
    }
}
