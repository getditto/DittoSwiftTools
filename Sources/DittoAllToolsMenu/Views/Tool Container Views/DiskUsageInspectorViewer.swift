//
//  DiskUsageInspectorViewer.swift
//  DittoSwiftTools
//
//  Container view for the Disk Usage Inspector tool in AllToolsMenu.
//

import DittoSwift
import DittoDiskUsage
import SwiftUI

struct DiskUsageInspectorViewer: View {

    var ditto: Ditto

    var body: some View {
        DiskUsageInspectorView(ditto: ditto)
    }
}
