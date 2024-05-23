///
//  LoggingDetailsView.swift
//  DittoToolsApp
//
//  Created by Eric Turner on 5/30/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI


@available(iOS 15, *)
public struct LoggingDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false
    @Binding var selectedLoggingOption: DittoLogger.LoggingOptions
    
    public init(loggingOption: Binding<DittoLogger.LoggingOptions>) {
        self._selectedLoggingOption = loggingOption
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    public var body: some View {
        List {
            Section {
                Text("Ditto Logging")
                    .frame(alignment: .center)
                    .font(.title)
            }
            Section {
                Picker("Logging Level", selection: $selectedLoggingOption) {
                    ForEach(DittoLogger.LoggingOptions.allCases) { option in
                        Text(option.description)
                    }
                }
            }
            Section {
                    // Export Logs
                    Button(action: {
                        self.presentExportLogsAlert.toggle()
                    }) {
                        HStack {
                            Text("Export Logs")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
#if canImport(ExportLogs)
                .sheet(isPresented: $presentExportLogsShare) {
                    ExportLogs()
                }
#endif
            }
        }
#if canImport(InsetGroupedListStyle)
        .listStyle(InsetGroupedListStyle())
#else
        .listStyle(.grouped)
#endif
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

@available(iOS 15, *)
struct LoggingDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDetailsView(loggingOption: .constant(.debug))
    }
}
