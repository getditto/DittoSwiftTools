///
//  LoggingDetailsView.swift
//  DittoToolsApp
//
//  Created by Eric Turner on 5/30/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoExportLogs
import SwiftUI

struct LoggingDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var dittoManager = DittoManager.shared
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        List {
            Section {
                Text("Ditto Logging")
                    .frame(width: 400, alignment: .center)
                    .font(.title)
            }
            Section {
                Picker("Logging Level", selection: $dittoManager.logLevel) {
                    ForEach(AppSettings.LogLevel.allCases, id: \.self) { loggingOption in
                        Text(loggingOption.description).tag(loggingOption)
                    }
                }
            }
            Section {
                    // Export Logs
                    Button(action: {
                        self.presentExportLogsAlert.toggle()
                    }) {
                        HStack {
                            MenuListItem(title: "Export Logs", systemImage: "square.and.arrow.up", color: .green)
                            Spacer()
                        }
                    }
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $presentExportLogsShare) {
                    ExportLogs()
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert("Export Logs", isPresented: $presentExportLogsAlert) {
            Button("Export") {
                presentExportLogsShare = true
            }
            Button("Cancel", role: .cancel) {}

        } message: {
            Text("Compressing the logs may take a few seconds.")
        }
    }
}

struct LoggingDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDetailsView()
    }
}
