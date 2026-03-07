import SwiftUI

struct BestBuyScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/best-buy/scan"
    static let clipName = "Scanify — Best Buy"
    static let clipDescription = "Scan electronics for specs, warranty, and compatible accessories."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ScanifyScannerView(
            storeBranding: StoreBranding.forStoreId("best-buy"),
            allowedCategory: .electronics
        )
    }
}
