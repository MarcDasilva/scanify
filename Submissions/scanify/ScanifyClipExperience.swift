import SwiftUI

struct ScanifyClipExperience: ClipExperience {
    static let urlPattern = "example.com/scanify/:param"
    static let clipName = "Scanify"
    static let clipDescription = "Scan merch and in-store experiences."
    static let teamName = "Scanify"

    static let touchpoint = JourneyTouchpoint(
        id: "scanify",
        title: "Scanify",
        icon: "barcode.viewfinder",
        context: "Scan merch and in-store experiences.",
        notificationHint: "Use the 8h window for follow-up offers.",
        sortOrder: 32
    )
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    var body: some View {
        ZStack {
            ClipBackground()
        }
    }
}
