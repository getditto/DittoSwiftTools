//
//  ExportLogsToPortalViewer.swift
//  DittoAllToolsMenu
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift
import DittoExportLogs

/// Wrapper view for ExportLogsToPortal integration in the AllToolsMenu
struct ExportLogsToPortalViewer: View {
    let ditto: Ditto
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ExportLogsToPortalView(ditto: ditto) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
