//
//  DiskUsageViewer.swift
//  DittoToolsApp
//
//  Created by Ben Chatelain on 2023-01-30.
//

import DittoSwift
import DittoDiskUsage
import SwiftUI

struct DiskUsageViewer: View {

    var ditto: Ditto

    var body: some View {
        DittoDiskUsageView(ditto: ditto)
        EmptyView()
    }
}
