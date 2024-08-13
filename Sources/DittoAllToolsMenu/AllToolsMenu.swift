//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoExportData
import DittoHeartbeat
import DittoSwift
import SwiftUI
import DittoExportLogs

@available(iOS 15.0, *)
public struct AllToolsMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    // Export Ditto Directory
    @State private var presentExportDataShare: Bool = false
    @State private var presentExportDataAlert: Bool = false
    
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    public init(ditto: Ditto) {
        DittoManager.shared.ditto = ditto
    }
    
    public var body: some View {
        NavigationView {
            List{
                Section(header: Text("Debug")) {
                    NavigationLink(destination: PresenceViewer()) {
                        MenuListItem(title: "Presence Viewer", systemImage: "network", color: .pink)
                    }
                    NavigationLink(destination: PeersListViewer()) {
                        MenuListItem(title: "Peers List", systemImage: "network", color: .blue)
                    }
                    NavigationLink(destination: DiskUsageViewer()) {
                        MenuListItem(title: "Disk Usage", systemImage: "opticaldiscdrive", color: .secondary)
                    }
                    NavigationLink(destination: DataBrowserView()) {
                        MenuListItem(title: "Data Browser", systemImage: "photo", color: .orange)
                    }
                    NavigationLink(destination: PresenceDegradationViewer()) {
                        MenuListItem(title: "Presence Degradation", systemImage: "network", color: .red)
                    }
                    NavigationLink(destination: HeartBeatViewer()) {
                        MenuListItem(title: "Heartbeat", systemImage: "heart.fill", color: .red)
                    }
                    NavigationLink(destination: PermissionsHealthViewer()) {
                        MenuListItem(title: "Permissions Health", systemImage: "stethoscope", color: .purple)
                    }
                }
                Section(header: Text("Exports")) {
                    NavigationLink(destination:  LoggingDetailsViewer()) {
                        MenuListItem(title: "Logging", systemImage: "square.split.1x2", color: .green)
                    }

                    // Export Ditto Directory
                    Button(action: {
                        self.presentExportDataAlert.toggle()
                    }) {
                        HStack {
                            MenuListItem(title: "Export Data Directory", systemImage: "square.and.arrow.up", color: .green)
                            Spacer()
                        }
                    }
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sheet(isPresented: $presentExportDataShare) {
                        ExportData(ditto:  DittoManager.shared.ditto!)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ditto Tools")
            .alert("Export Ditto Directory", isPresented: $presentExportDataAlert) {
                Button("Export") {
                    presentExportDataShare = true
                }
                Button("Cancel", role: .cancel) {}

                } message: {
                    Text("Compressing the data may take a while.")
                }
            }
            
        .navigationViewStyle(StackNavigationViewStyle())
        VStack {
            Text("SDK Version: \(DittoManager.shared.ditto?.sdkVersion ?? "N/A")")
        }.padding()
    }
}

