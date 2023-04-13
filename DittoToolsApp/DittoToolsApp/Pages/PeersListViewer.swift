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

struct PeersListViewer: View {

    var body: some View {
        PeersListView(ditto: DittoManager.shared.ditto!)
    }
}
