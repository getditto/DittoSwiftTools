//
//  DiskUsageInspectorViewer.swift
//  DittoToolsApp
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI
import DittoSwift
import DittoDiskUsage

struct DiskUsageInspectorViewer: View {
    let ditto: Ditto

    var body: some View {
        DiskUsageInspectorView(ditto: ditto)
    }
}
