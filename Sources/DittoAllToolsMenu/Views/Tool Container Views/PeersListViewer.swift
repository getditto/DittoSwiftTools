///
//  PeersListViewer.swift
//  
//
//  Created by Eric Turner on 3/17/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoPeersList
import DittoDiskUsage
import SwiftUI
import DittoSwift

struct PeersListViewer: View {

    var ditto: Ditto

    var body: some View {
#if !os(macOS)

        PeersListView(ditto: ditto)
#endif
    }
}
