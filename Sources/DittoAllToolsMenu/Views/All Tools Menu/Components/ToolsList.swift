//
//  ToolsList.swift
//
//  This file defines the `ToolsList` view, which organizes and displays a list of diagnostic and data management tools.
//  Each tool is grouped into relevant sections, and the view adapts its contents based on the platform (e.g., excluding export functionality on tvOS).
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoExportData


/// A view that displays a list of diagnostic tools and data management options.
///
/// `ToolsList` organizes various tools into sections, each with its own set of options.
/// The view can be conditionally configured to include or exclude specific items based on
/// the platform (e.g., excluding certain features on tvOS).
///
/// - Note: On platforms other than tvOS, an additional section is included for exporting data,
///   which presents an alert to confirm the action.
struct ToolsList: View {
    @ObservedObject var dittoService = DittoService.shared
    
    public var body: some View {
        List {
            ForEach(MenuOption.Section.allCases, id: \.self) { section in
                Section(header: Text(section.rawValue)) {
                    ForEach(section.options, id: \.self) { option in
                        MenuItem(option: option, dittoService: dittoService)
                    }
                }
            }
            
#if !os(tvOS)
            // Do not show on tvOS as export is not currently supported.
            Section(footer: Text("Export all Ditto data on this device as a .zip file.")) {
                ExportDataButton()
            }
#endif
        }
    }
}


#if !os(tvOS)
/// A button view that triggers the export of Ditto data.
///
/// `ExportDataButton` provides the functionality to export Ditto data as a `.zip` file.
/// It shows an alert to confirm the action and, once confirmed, presents a system sheet for sharing the exported file.
fileprivate struct ExportDataButton: View {
    @ObservedObject var dittoService = DittoService.shared
    
    // State variables to manage the presentation of alerts and sheets for exporting data
    @State private var presentExportDataAlert = false
    @State private var isExportDataSharePresented = false

    var body: some View {
        Button(action: {
            presentExportDataAlert.toggle()
        }) {
            Text("Export Data…")
                .foregroundColor(.accentColor)
        }
        .alert(isPresented: $presentExportDataAlert) {
            Alert(title: Text("Are you sure?"),
                  message: Text("Compressing the Ditto directory data may take a while."),
                  primaryButton: .cancel(Text("Cancel")),
                  secondaryButton: .default(Text("Export…")) {
                    isExportDataSharePresented = true
                print("ok!")
            })
        }
        .disabled(!(dittoService.ditto?.activated ?? false))
        .sheet(isPresented: $isExportDataSharePresented) {
            // Sheet to handle the file sharing of the exported data.
            if let ditto = DittoService.shared.ditto {
                ExportData(ditto:  ditto)
            } else {
                Text("An active Ditto instance must be running in order to export data for security and privacy reasons.")
            }
        }
    }
}
#endif
