//
//  DiskUsageViewer.swift
//  DittoToolsApp
//
//  Created by Ben Chatelain on 2023-01-30.
//

import DittoDiskUsage
import SwiftUI

struct DiskUsageViewer: View {

    var body: some View {
        DittoDiskUsageView(ditto: DittoManager.shared.ditto!)
        EmptyView()
    }
}
