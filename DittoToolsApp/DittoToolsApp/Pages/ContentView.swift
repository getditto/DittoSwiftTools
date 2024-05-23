//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoExportData
import DittoHeartbeat
import DittoSwift
import SwiftUI
import DittoAllToolsMenu

class MainListViewModel: ObservableObject {
    @Published var isShowingLoginSheet = DittoManager.shared.ditto == nil
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = MainListViewModel()
    @ObservedObject private var dittoModel = DittoManager.shared

    // Export Ditto Directory
    @State private var presentExportDataShare: Bool = false
    @State private var presentExportDataAlert: Bool = false

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        NavigationView {
            List{
                Section(header: Text("Debug")) {
                    #if canImport(PresenceViewer)
                    NavigationLink(destination: PresenceViewer()) {
                        MenuListItem(title: "Presence Viewer", systemImage: "network", color: .pink)
                    }
                    #endif
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
                Section(header: Text("Configuration")) {
                    NavigationLink(destination: Login()) {
                        MenuListItem(title: "Change Identity", systemImage: "envelope", color: .purple)
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
#if canImport(ExportData)
                        ExportData(ditto: dittoModel.ditto!)
#endif
                    }
                }
            }
#if canImport(InsetGroupedListStyle)
            .listStyle(InsetGroupedListStyle())
#else
            .listStyle(.grouped)
#endif
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
        .sheet(isPresented: $viewModel.isShowingLoginSheet, content: {
            Login()
                .onSubmit {
                    viewModel.isShowingLoginSheet = false
                }
        })
        VStack {
            Text("SDK Version: \(dittoModel.ditto?.sdkVersion ?? "N/A")")
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
