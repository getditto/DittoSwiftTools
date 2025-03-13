//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 3/6/24.
//

import SwiftUI
import DittoHeartbeat
import DittoSwift

struct HeartBeatViewer: View {
    
    var ditto: Ditto

    var body: some View {
#if !os(macOS)
        HeartbeatView(ditto: ditto)
#endif
    }
}

