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
    
    var body: some View {
        PresenceDegradationView(ditto: DittoManager.shared.ditto!) { totalPeers in
            print("Total Peers: \(totalPeers)")
        }
    }
}

