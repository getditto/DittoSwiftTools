//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import SwiftUI
import DittoSwift
import DittoPresenceDegradation

struct PresenceDegradationViewer: View {
    
    var ditto: Ditto
    
    var body: some View {
#if !os(macOS)

        PresenceDegradationView(ditto: ditto) { expectedPeers, remotePeers, settings in
            print("expected Peers: \(expectedPeers)")
            
            if let remotePeers = remotePeers {
                print("remotePeers: \(remotePeers)")
            }
            if let settings = settings {
                print("settings: \(settings)")
            }

        }
        #endif
    }
}

