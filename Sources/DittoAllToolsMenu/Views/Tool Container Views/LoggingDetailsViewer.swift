//
//  LoggingDetailsViewer.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoExportLogs
import DittoSwift
import SwiftUI


struct LoggingDetailsViewer: View {
    
    var ditto: Ditto

    var body: some View {
#if !os(macOS)
        LoggingDetailsView(ditto: ditto)
#endif
    }
}
