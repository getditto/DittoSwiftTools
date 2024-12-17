// 
//  SyncButton.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI


struct SyncButton: View {
    var dittoService: DittoService?
    
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Button(action: {
            if let dittoService, let ditto = dittoService.ditto {
                if ditto.isSyncActive {
                    dittoService.stopSyncEngine()
                    isAnimating = false
                    rotationAngle = 0
                } else {
                    try? ditto.startSync()
                    isAnimating = true
                }
            }
        }) {
            if let ditto = dittoService?.ditto, ditto.activated {
                HStack(spacing: 12) {
                    Text(ditto.isSyncActive ? "Ditto is active." : "Ditto is not running.")
                        .font(.subheadline)
                    
                    #if !os(tvOS)
                    // The way focus is handled on tvOS can interfere with animation updates, so omit on tvOS.
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .rotationEffect(.degrees(rotationAngle))
                    #endif
                }
            } else {
                Text("No license found.")
            }
        }
        .onAppear {
            if let ditto = dittoService?.ditto {
                isAnimating = ditto.isSyncActive
            }
        }
        .onChange(of: isAnimating) { rotating in
            if rotating {
                startRotation()
            }
        }
        .disabled(dittoService?.ditto == nil)
    }
    
    private func startRotation() {
        if isAnimating {
            withAnimation(.linear(duration: 3.4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}
