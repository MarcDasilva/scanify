//  ConstraintBanner.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

/// Non-dismissible banner replicating the real App Clip "Get the full app" bar.
/// Shows Nike-specific content only when the current clip is the Nike clip.
struct ConstraintBanner: View {
    /// URL pattern of the currently active clip (e.g. "scanify.app/nike/scan"). When this is the Nike clip, Nike branding is shown; otherwise a generic bar is shown.
    var urlPattern: String = ""

    @Environment(\.openURL) private var openURL

    private var isNikeClip: Bool {
        urlPattern.lowercased().contains("nike")
    }

    var body: some View {
        HStack(spacing: 10) {
            if isNikeClip {
                Image("nike_swoosh")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Nike App")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Get the full Nike app experience")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "square.dashed")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("App Clip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Get the full app experience")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                if isNikeClip {
                    openURL(URL(string: "https://apps.apple.com/app/id387649656")!)
                } else {
                    openURL(URL(string: "https://apps.apple.com/app-clips")!)
                }
            } label: {
                Text("GET")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}
