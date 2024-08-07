//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 3/6/24.
//

import SwiftUI
import DittoHeartbeat

@available(iOS 15, *)
struct HeartBeatViewer: View {
    var body: some View {
        HeartbeatView(ditto: DittoManager.shared.ditto!)
    }
}

