///
//  LoggingDetailsViewer.swift
//  DittoToolsApp
//
//  Created by Eric Turner on 6/1/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoExportLogs
import DittoSwift
import SwiftUI

struct LoggingDetailsViewer: View {
    
    @ObservedObject var dittoManager = DittoService.shared
    
    var body: some View {
        LoggingDetailsView(loggingOption: $dittoManager.loggingOption)
    }
}

//struct LoggingDetailsViewer_Previews: PreviewProvider {
//    static var previews: some View {
//        LoggingDetailsViewer(dittoManager: DittoManager.shared)
//    }
//}
