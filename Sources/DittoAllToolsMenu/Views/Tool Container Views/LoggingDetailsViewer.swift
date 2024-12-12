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
        LoggingDetailsView(ditto: ditto)
    }
}

//struct LoggingDetailsViewer_Previews: PreviewProvider {
//    static var previews: some View {
//        LoggingDetailsViewer(dittoManager: DittoManager.shared)
//    }
//}
