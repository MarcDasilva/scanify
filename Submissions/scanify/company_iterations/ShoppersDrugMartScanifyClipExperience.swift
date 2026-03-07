import SwiftUI

struct ShoppersDrugMartScanifyClipExperience: ClipExperience {
    static let urlPattern = "scanify.app/shoppers-drug-mart/scan"
    static let clipName = "Scanify — Shoppers Drug Mart"
    static let clipDescription = "Scan pharmacy products for dosage, interactions, and generic alternatives."
    static let teamName = "Scanify"
    static let touchpoint: JourneyTouchpoint = .scanify
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ScanifyScannerView(
            storeBranding: StoreBranding.forStoreId("shoppers-drug-mart"),
            allowedCategory: .pharmacy
        )
    }
}
