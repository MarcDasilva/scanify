//  ConstraintBanner.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

/// Non-dismissible banner replicating the real App Clip "Get the full app" bar.
struct ConstraintBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 10) {
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

            Spacer()

            Button {
                openURL(URL(string: "itms-apps://itunes.apple.com/app/id387649656")!)
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
