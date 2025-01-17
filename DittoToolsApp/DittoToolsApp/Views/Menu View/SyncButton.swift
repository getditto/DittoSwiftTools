//
//  SyncButton.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

struct SyncButton: View {
    @ObservedObject var dittoService: DittoService

    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        Button(action: handleSyncButtonTapped) {
            HStack(spacing: 12) {
                Text(dittoService.syncState.rawValue)
                    .font(.subheadline)

                #if !os(tvOS)
                    // The way focus is handled on tvOS can interfere with animation updates, so omit on tvOS.

                    // Only show the image if there is a licence (ie. the engine is active or paused)
                    if dittoService.syncState != .noLicense {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                #endif
            }
        }
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: dittoService.syncState) { _ in
            updateAnimationState()
        }
        .onChange(of: isAnimating) { rotating in
            if rotating {
                startRotation()
            }
        }
        .disabled(dittoService.syncState == .noLicense)
    }

    private func updateAnimationState() {
        isAnimating = dittoService.syncState == .active
        if !isAnimating {
            rotationAngle = 0
        }
    }

    private func handleSyncButtonTapped() {
        switch dittoService.syncState {
        case .active:
            dittoService.stopSyncEngine()
            isAnimating = false
            rotationAngle = 0
        case .inactive:
            try? dittoService.startSyncEngine()
            isAnimating = true
        case .noLicense:
            break  // Can't do anything without a license
        }
    }

    private func startRotation() {
        if isAnimating {
            withAnimation(.linear(duration: 3.4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }

}
