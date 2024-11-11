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
import UIKit


public struct LoggingDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false
    @Binding var selectedLoggingOption: DittoLogger.LoggingOptions
    
    @State private var activityViewController: UIActivityViewController?
    
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
                        print(self.presentExportLogsAlert)
                    }) {
                        HStack {
                            Text("Export Logs")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
#if !os(tvOS)
                    .sheet(isPresented: $presentExportLogsShare) {
                        if let activityVC = activityViewController {
                            // Use a wrapper UIViewController to present the activity controller
                            ActivityViewControllerWrapper(activityViewController: activityVC)
                        } else {
                            // Pass the binding for the `UIActivityViewController?`
                            ExportLogs(activityViewController: $activityViewController)
                        }
                    }
#endif
            }
            .alert(isPresented: $presentExportLogsAlert) {
    #if os(tvOS)
                Alert(title: Text("Export Logs"),
                      message: Text("Exporting logs is not supported on tvOS at this time."),
                      dismissButton: .cancel()
                )
    #else
                Alert(title: Text("Export Logs"),
                      message: Text("Compressing the logs may take a few seconds."),
                      primaryButton: .default(
                        Text("Export"),
                        action: {
                            presentExportLogsShare = true
                        }),
                      secondaryButton: .cancel()
                )
    #endif
            }
        }
#if os(tvOS)
        .listStyle(GroupedListStyle())
#else
        .listStyle(InsetGroupedListStyle())
#endif
    }
}

struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    let activityViewController: UIActivityViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewController.present(activityViewController, animated: true)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No need to update the view controller here
    }
}
