//
//  AllToolsMenu.swift
//
//  This file defines the `AllToolsMenu` view, which organizes and displays a list of diagnostic and data management tools.
//  Each tool is grouped into relevant sections.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift
import DittoExportData


/// A view that displays a list of diagnostic tools and data management options.
///
/// `AllToolsMenu` organizes various tools into sections, each with its own set of options.
public struct AllToolsMenu: View {
    
    var ditto: Ditto?
    
    public init(ditto: Ditto?) {
        self.ditto = ditto
    }
    
    public var body: some View {
        List {
            ForEach(MenuOption.Section.allCases, id: \.self) { section in
                Section(header: Text(section.rawValue)) {
                    ForEach(section.options, id: \.self) { option in
                        MenuItem(option: option, ditto: ditto)
                    }
                }
            }
            Section(footer: Text("Export all Ditto data on this device as a .zip file.")) {
                ExportDataButton(ditto: ditto)
            }
        }
    }
}


/// A button view that triggers the export of Ditto data.
///
/// `ExportDataButton` provides the functionality to export Ditto data as a `.zip` file.
/// It shows an alert to confirm the action and, once confirmed, presents a system sheet for sharing the exported file.
fileprivate struct ExportDataButton: View {
    var ditto: Ditto?

    // State variables to manage the presentation of alerts and sheets for exporting data
    @State private var presentExportDataAlert = false
    @State private var isExportDataSharePresented = false

    var body: some View {
        Button {
            self.presentExportDataAlert.toggle()
        } label: {
            Label("Export Data Directory", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $isExportDataSharePresented) {
            #if os(iOS)
            if let ditto {
                ExportData(ditto: ditto)
            }
            #endif
        }
        .alert(isPresented: $presentExportDataAlert) {
            if ditto != nil {
                Alert(title: Text("Export Ditto Directory"),
                      message:
                        Text("Compressing the data may take a while."),
                      primaryButton: .default(
                        Text("Export"),
                        action: {
#if os(iOS)
                            isExportDataSharePresented = true
#elseif os(macOS)
                            if let ditto {
                                ExportDataMacOS(ditto: ditto).export()
                            }
#endif
                        }),
                      secondaryButton: .cancel()
                )
            } else {
                Alert(title: Text("An active Ditto instance must be running in order to export data for security and privacy reasons."))
            }
        }
        .disabled(!(ditto?.isActivated ?? false))
    }
}
