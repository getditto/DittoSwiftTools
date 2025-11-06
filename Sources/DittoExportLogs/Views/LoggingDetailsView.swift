//
//  LoggingDetailsView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//
import DittoSwift
import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

public struct LoggingDetailsView: View {

    @State var selectedLogLevel = DittoLogger.minimumLogLevel
    @State var isLoggingEnabled = DittoLogger.isEnabled
    @State private var presentExportLogsAlert: Bool = false
    @State private var showExportToPortal: Bool = false
    @State private var exportedLogURL: URL?
    @State private var urlToSave: URL?

    private let ditto: Ditto
    
    public init(ditto: Ditto) {
        self.ditto = ditto
    }
    
    public var body: some View {
        #if os(iOS) || os(tvOS)
        List {
            Section {
                settingsBody()
            } footer: {
                Text("Changes will be applied immediately.")
                    .font(.caption)
            }
            #if os(iOS)
            Section {
                exportLogsButton()
                exportLogsToPortalButton()
            }
            #endif
        }
        #if os(iOS)
        .padding(.top, -16)
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitleDisplayMode(.inline)
        #else
        .listStyle(GroupedListStyle())
        #endif
        
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                settingsBody()
                exportLogsButton()
                    .padding(.top, 20)
                exportLogsToPortalButton()
            }
            .padding()
        }
        #endif
    }
    
    #if os(iOS) || os(macOS)
    private func exportLogsButton() -> some View {
        Button {
            presentExportLogsAlert.toggle()
        } label: {
            Text("Export Logs to Device")
        }
        .alert(isPresented: $presentExportLogsAlert) {
            Alert(title: Text("Export Logs"),
                  message: Text("This may take a few seconds..."),
                  primaryButton: .default(
                    Text("Export"),
                    action: {
                        Task {
                            if let url = await getZippedLogs() {
                                presentShareSheet(for: url)
                            }
                        }
                    }),
                  secondaryButton: .cancel()
            )
        }
    }

    private func exportLogsToPortalButton() -> some View {
        Button {
            showExportToPortal = true
        } label: {
            Text("Export Logs to Portal")
        }
        .sheet(isPresented: $showExportToPortal) {
            ExportLogsToPortalView(ditto: ditto) {
                showExportToPortal = false
            }
        }
    }
    #endif
    
    private func pickerText() -> String {
        #if os(iOS) || os(tvOS)
        return "Log Level"
        #else
        return "Log Level:"
        #endif
    }
    
    private func settingsBody() -> some View {
        Group {
            Picker(pickerText(), selection: $selectedLogLevel) {
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
                    DittoLogger.isEnabled = newValue
                }
        }
    }
    
    #if os(iOS)
    func presentShareSheet(for url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(avc, animated: true)
    }
    #endif
    
    #if os(macOS)
    func presentShareSheet(for url: URL) {
        guard let keyWindow = NSApp.keyWindow,
              let contentView = keyWindow.contentView else {
            return
        }

        // Prompt user to save the file first
        let panel = NSSavePanel()
        panel.title = "Save Exported Logs"
        panel.allowedFileTypes = ["gz"]
        panel.nameFieldStringValue = "ditto.jsonl.gz"

        panel.beginSheetModal(for: keyWindow) { response in
            if response == .OK, let destination = panel.url {
                do {
                    try FileManager.default.copyItem(at: url, to: destination)
                } catch {
                    print("Error saving file: \(error)")
                }
            }

            // After that, offer to share it
            let picker = NSSharingServicePicker(items: [url])
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
    }
    #endif
    
    func getZippedLogs() async -> URL? {
        return try? await LogManager.shared.exportLogs()
    }
}

#if os(iOS)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard controller.presentedViewController == nil else { return }
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.present(avc, animated: true)
    }
}

#endif
