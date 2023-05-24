//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift
import Combine
import DittoExportLogs
import DittoExportData

struct ContentView: View {
    
    class ViewModel: ObservableObject {

        @Published var isShowingLoginSheet = DittoManager.shared.ditto == nil

        var cancellables = Set<AnyCancellable>()
        
        var names: [String] = []
        
        func stopSync() {
        }
    }

    @ObservedObject private var viewModel = ViewModel()
    @ObservedObject private var dittoModel = DittoManager.shared

    // Export Logs
    @State private var presentExportLogsShare: Bool = false
    @State private var presentExportLogsAlert: Bool = false

    // Export Ditto Directory
    @State private var presentExportDataShare: Bool = false
    @State private var presentExportDataAlert: Bool = false

    var body: some View {
        NavigationView {
            List{
                Section(header: Text("Debug")) {
                    NavigationLink(destination: DataBrowserView()) {
                        MenuListItem(title: "Data Browser", systemImage: "photo", color: .green)
                    }
                    if #available(iOS 15, *) {
                        NavigationLink(destination: PeersListViewer()) {
                            MenuListItem(title: "Peers List", systemImage: "network", color: .green)
                        }
                    } else {
                        NavigationLink(destination: NetworkPage()) {
                            MenuListItem(title: "Peers List", systemImage: "network", color: .green)
                        }
                    }
                    NavigationLink(destination: PresenceViewer()) {
                        MenuListItem(title: "Presence Viewer", systemImage: "network", color: .green)
                    }
                    NavigationLink(destination: DiskUsageViewer()) {
                        MenuListItem(title: "Disk Usage", systemImage: "opticaldiscdrive", color: .green)
                    }
                }
                Section(header: Text("Configuration")) {
                    NavigationLink(destination: Login()) {
                        MenuListItem(title: "Change Identity", systemImage: "envelope", color: .green)
                    }
                }
                Section(header: Text("Exports")) {
                    // Export Logs
                    Button(action: {
                        self.presentExportLogsAlert.toggle()
                    }) {
                        MenuListItem(title: "Export Logs", systemImage: "square.and.arrow.up", color: .green)
                    }
                    .foregroundColor(.black)
                    .sheet(isPresented: $presentExportLogsShare) {
                        ExportLogs()
                    }

                    // Export Ditto Directory
                    Button(action: {
                        self.presentExportDataAlert.toggle()
                    }) {
                        MenuListItem(title: "Export Data Directory", systemImage: "square.and.arrow.up", color: .green)
                    }
                    .foregroundColor(.black)
                    .sheet(isPresented: $presentExportDataShare) {
                        ExportData(ditto: dittoModel.ditto!)
                    }


                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ditto Tools")
            // Alerts
            .alert("Export Logs", isPresented: $presentExportLogsAlert) {
                Button("Export") {
                    presentExportLogsShare = true
                }
                Button("Cancel", role: .cancel) {}

            } message: {
                Text("Compressing the logs may take a few seconds.")
            }

            .alert("Export Ditto Directory", isPresented: $presentExportDataAlert) {
                Button("Export") {
                    presentExportDataShare = true
                }
                Button("Cancel", role: .cancel) {}

                } message: {
                    Text("Compressing the logs may take a while.")
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
