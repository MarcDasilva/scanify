import SwiftUI

// Scanify App Clip — Show Day, On-Site, In Store, and Barcode Scanner flows.
// DESIGN NOTES:
// - Use system colors (.primary, .secondary, .tertiary) — they adapt to Liquid Glass
// - ConstraintBanner is added automatically by the simulator — don't add it yourself
// - Wrap content in ScrollView to avoid overlapping with the top bar

struct ScanifyClipExperience: ClipExperience {
    static let urlPattern = "example.com/scanify/:param"
    static let clipName = "Scanify"
    static let clipDescription = "Show day merch, on-site actions, in-store finder, and barcode scan."
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

    enum Tab: String, CaseIterable {
        case showDay = "Show Day"
        case onSite = "On-Site"
        case inStore = "In Store"
        case barcodeScanner = "Barcode"
    }

    @State private var selectedTab: Tab = .showDay
    @State private var cart: [Product] = []
    @State private var checkoutStep: CheckoutStep = .browse
    @State private var scannedProduct: Product?
    @State private var onSiteCheckedIn = false
    @State private var barcodeScanned = false

    private enum CheckoutStep {
        case browse
        case checkout
        case success
    }

    private var artist: Artist {
        ChallengeMockData.artists[0]
    }

    private var venueName: String {
        let venueId = context.pathParameters["venueId"] ?? ""
        return ChallengeMockData.venues.first { $0.name.lowercased().contains(venueId.lowercased()) }?.name
            ?? ChallengeMockData.venues[0].name
    }

    var body: some View {
        ZStack {
            ClipBackground()

            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Group {
                    switch selectedTab {
                    case .showDay:
                        showDayContent
                    case .onSite:
                        onSiteContent
                    case .inStore:
                        inStoreContent
                    case .barcodeScanner:
                        barcodeScannerContent
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
    }

    // MARK: - Show Day

    private var showDayContent: some View {
        Group {
            switch checkoutStep {
            case .browse:
                showDayBrowse
            case .checkout:
                showDayCheckout
            case .success:
                showDaySuccess
            }
        }
        .animation(.spring(duration: 0.35), value: checkoutStep)
    }

    private var showDayBrowse: some View {
        ScrollView {
            VStack(spacing: 12) {
                ArtistBanner(artist: artist, venue: venueName)
                    .padding(.top, 8)

                ClipHeader(
                    title: "Show Day Merch",
                    subtitle: "Pre-order now, pick up at the booth.",
                    systemImage: "music.mic"
                )
                .padding(.horizontal, 24)

                MerchGrid(products: ChallengeMockData.featuredProducts) { product in
                    cart.append(product)
                }

                if !cart.isEmpty {
                    CartSummary(items: cart) {
                        withAnimation(.spring(duration: 0.4)) {
                            checkoutStep = .checkout
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: cart.count)
    }

    private var showDayCheckout: some View {
        ScrollView {
            VStack(spacing: 18) {
                ClipHeader(
                    title: "Checkout",
                    subtitle: "Review and pay — pickup at booth.",
                    systemImage: "creditcard.fill"
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)

                GlassEffectContainer {
                    VStack(spacing: 8) {
                        infoRow(label: "Items", value: "\(cart.count)")
                        infoRow(label: "Subtotal", value: totalPrice)
                        infoRow(label: "Pickup", value: "Booth #3")
                        infoRow(label: "Payment", value: "Apple Pay (Mock)")
                    }
                }
                .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    ClipActionButton(title: "Back", icon: "chevron.left", style: .secondary) {
                        withAnimation(.spring(duration: 0.35)) {
                            checkoutStep = .browse
                        }
                    }
                    ClipActionButton(title: "Pay Now", icon: "checkmark.circle.fill") {
                        withAnimation(.spring(duration: 0.35)) {
                            checkoutStep = .success
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var showDaySuccess: some View {
        VStack(spacing: 20) {
            Spacer()
            ClipSuccessOverlay(
                message: "Order confirmed!\nPick up at \(ChallengeMockData.venues[0].boothLocations[0])."
            )
            ClipActionButton(title: "Browse Again", icon: "bag.fill", style: .secondary) {
                withAnimation(.spring(duration: 0.35)) {
                    cart = []
                    checkoutStep = .browse
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.bottom, 16)
    }

    private var totalPrice: String {
        let total = cart.reduce(0) { $0 + $1.price }
        return String(format: "$%.2f", total)
    }

    // MARK: - On-Site

    private var onSiteContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipHeader(
                    title: "On-Site",
                    subtitle: "You're at the venue — quick actions.",
                    systemImage: "mappin.and.ellipse"
                )
                .padding(.top, 16)
                .padding(.horizontal, 24)

                if onSiteCheckedIn {
                    ClipSuccessOverlay(
                        message: "You're checked in.\nMerch booth and restrooms are on Level 1."
                    )
                    ClipActionButton(title: "Done", icon: "checkmark.circle", style: .secondary) {
                        onSiteCheckedIn = false
                    }
                    .padding(.horizontal, 24)
                } else {
                    GlassEffectContainer {
                        VStack(spacing: 8) {
                            infoRow(icon: "location.fill", label: "Venue", value: venueName)
                            infoRow(icon: "clock.fill", label: "Doors", value: "6:00 PM")
                            infoRow(icon: "tshirt.fill", label: "Merch", value: "Booth #3 & #7")
                        }
                    }
                    .padding(.horizontal, 20)

                    ClipActionButton(title: "Check In Here", icon: "checkmark.seal.fill") {
                        withAnimation(.spring(duration: 0.35)) {
                            onSiteCheckedIn = true
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - In Store

    private var inStoreContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipHeader(
                    title: "In Store",
                    subtitle: "Find items and pickup locations.",
                    systemImage: "storefront.fill"
                )
                .padding(.top, 16)
                .padding(.horizontal, 24)

                GlassEffectContainer {
                    VStack(spacing: 8) {
                        infoRow(icon: "map.fill", label: "Store", value: "Rogers Centre Shop")
                        infoRow(icon: "location.fill", label: "Aisle", value: "Merch Wall A")
                        infoRow(icon: "number", label: "Stock", value: "Available now")
                    }
                }
                .padding(.horizontal, 20)

                Text("Use Barcode Scanner tab to scan a product and see availability.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                ClipActionButton(title: "Open Barcode Scanner", icon: "barcode.viewfinder") {
                    selectedTab = .barcodeScanner
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Barcode Scanner

    private var barcodeScannerContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipHeader(
                    title: "Barcode Scanner",
                    subtitle: "Scan a product to check price and stock.",
                    systemImage: "barcode.viewfinder"
                )
                .padding(.top, 16)
                .padding(.horizontal, 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(height: 220)
                        .overlay {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 60))
                                .foregroundStyle(.tertiary)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .padding(.horizontal, 20)

                    if barcodeScanned, let product = scannedProduct {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.green)
                            Text(product.name)
                                .font(.system(size: 15, weight: .semibold))
                            Text(product.formattedPrice)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(height: 240)

                if barcodeScanned {
                    ClipActionButton(title: "Scan Another", icon: "barcode.viewfinder", style: .secondary) {
                        barcodeScanned = false
                        scannedProduct = nil
                    }
                    .padding(.horizontal, 24)
                } else {
                    ClipActionButton(title: "Simulate Scan", icon: "camera.viewfinder") {
                        withAnimation(.spring(duration: 0.35)) {
                            scannedProduct = ChallengeMockData.featuredProducts[0]
                            barcodeScanned = true
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }
}
