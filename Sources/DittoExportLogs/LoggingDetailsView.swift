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
                    .frame(width: 400, alignment: .center)
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
                .sheet(isPresented: $presentExportLogsShare) {
                    ExportLogs()
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert(isPresented: $presentExportLogsAlert) {
            Alert(title: Text("Export Logs"),
                  message: Text("Compressing the logs may take a few seconds."),
                  primaryButton: .default(
                    Text("Export"),
                    action: {
                        presentExportLogsShare = true
                    }),
                  secondaryButton: .cancel()
            )
        }
    }
}

struct LoggingDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDetailsView(loggingOption: .constant(.debug))
    }
}
