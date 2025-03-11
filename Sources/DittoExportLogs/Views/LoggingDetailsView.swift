//
//  LoggingDetailsView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//
#if !os(macOS)
import Combine
import DittoSwift
import SwiftUI
import UIKit


public struct LoggingDetailsView: View {
    
    @State var selectedLogLevel = DittoLogger.minimumLogLevel
    
    @State var isLoggingEnabled = DittoLogger.enabled
    
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false
    
#if !os(tvOS)
    @State private var activityViewController: UIActivityViewController?
#endif
    
    private let ditto: Ditto
    
    public init(ditto: Ditto) {
        self.ditto = ditto
    }
    
    public var body: some View {
        List {
            Section(header: Text("Settings"),
                    footer: Text("Changes will be applied immediately.")
            ) {
                Picker("Log Level", selection: $selectedLogLevel) {
                    ForEach(DittoLogLevel.displayableCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .onChange(of: selectedLogLevel) { newValue in
                    DittoLogger.minimumLogLevel = newValue
                    DittoLogger.minimumLogLevel.saveToStorage()
                }
                Toggle("Enable Logging", isOn: $isLoggingEnabled)
                    .onChange(of: isLoggingEnabled) { newValue in
                        DittoLogger.enabled = newValue
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
#endif
