//
//  LoggingDetailsView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import SwiftUI
import UIKit


public struct LoggingDetailsView: View {
    @Binding var selectedLoggingOption: DittoLogger.LoggingOptions
    
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false
    
#if !os(tvOS)
    @State private var activityViewController: UIActivityViewController?
#endif
    
    public init(loggingOption: Binding<DittoLogger.LoggingOptions>) {
        self._selectedLoggingOption = loggingOption
    }
    
    public var body: some View {
        List {
            Section(header: Text("Settings"),
                    footer: Text("Changes will be applied immediately.")
            ) {
                Picker("Log Level", selection: $selectedLoggingOption) {
                    ForEach(DittoLogger.LoggingOptions.allCases) { option in
                        Text(option.description)
                    }
                }
            }
#if !os(tvOS)
            Section {
                // Export Logs
                Button {
                    presentExportLogsAlert.toggle()
                } label: {
                    Text("Export Logs…")
                }
                .sheet(isPresented: $presentExportLogsShare) {
                    if let activityVC = activityViewController {
                        // Use a wrapper UIViewController to present the activity controller
                        ActivityViewControllerWrapper(activityViewController: activityVC)
                    } else {
                        // Pass the binding for the `UIActivityViewController?`
                        ExportLogs(activityViewController: $activityViewController)
                    }
                }
            }
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
#endif
        }
        #if os(tvOS)
        .listStyle(GroupedListStyle())
        #else
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitleDisplayMode(.inline)
        #endif

        .navigationTitle("Logging")
    }
}

@available(tvOS, unavailable)
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
