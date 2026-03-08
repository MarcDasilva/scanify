//  ReactivChallengeKitApp.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

@main
struct ReactivChallengeKitApp: App {
    @State private var router = ClipRouter()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let match = router.currentMatch {
                    match.makeView()
                        .safeAreaInset(edge: .top, spacing: 0) {
                            HStack {
                                Spacer()
                                Button {
                                    router.dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .glassEffect(.regular.interactive(), in: .circle)
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    LandingView(router: router)
                        .transition(.opacity)
                }
            }
            .animation(.spring(duration: 0.4), value: router.currentMatch?.id)
        }
    }
}
