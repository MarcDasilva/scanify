import SwiftUI

struct WalmartScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/walmart/scan"
    static let clipName = "Scanify — Walmart"
    static let clipDescription = "Scan grocery items for nutrition, allergens, and alternatives."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ScanifyScannerView(
            storeBranding: StoreBranding.forStoreId("walmart"),
            allowedCategory: .food
        )
    }
}
