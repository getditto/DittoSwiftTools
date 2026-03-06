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
    var viewModel: DiskUsageInspectorViewModel?

    var body: some View {
        if let viewModel = viewModel {
            DiskUsageInspectorView(viewModel: viewModel)
        } else {
            DiskUsageInspectorView(ditto: ditto)
        }
    }
}
