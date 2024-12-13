// 
//  SyncButton.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI


struct SyncButton: View {
    let ditto: Ditto?
    
    @State private var isActive = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Button(action: {
            if let ditto {
                if ditto.isSyncActive {
                    ditto.stopSync()
                    isActive = false
                } else {
                    try? ditto.startSync()
                    isActive = true
                }
            }
        }) {
            Group {
                if let ditto, ditto.activated {
                    HStack {
                        Text(ditto.isSyncActive ? "Ditto is active." : "Ditto is not running.")
                            .font(.subheadline)

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .rotationEffect(.degrees(rotationAngle))
                            .animation(.default, value: isActive)
                    }
                } else {
                    Text("No license found.")
                }
            }
        }
        .onAppear {
            if let ditto {
                isActive = ditto.isSyncActive
            }
        }
        .onChange(of: isActive) { rotating in
            if rotating {
                startRotation()
            }
        }
    }
    
    private func startRotation() {
        // Increment rotation angle in a loop while isRotating is true
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if isActive {
                rotationAngle += 2
                if rotationAngle >= 360 { rotationAngle = 0 }
            } else {
                timer.invalidate()
            }
        }
    }
}
