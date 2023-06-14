//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift
import Combine
import DittoExportLogs

struct ContentView: View {
    
    class ViewModel: ObservableObject {

        @Published var isShowingLoginSheet = DittoManager.shared.ditto == nil

        var cancellables = Set<AnyCancellable>()
        
        var names: [String] = []
        
        func stopSync() {
        }
    }

    @ObservedObject var viewModel = ViewModel()
    @ObservedObject var dittoModel = DittoManager.shared
    @State var exportLogsSheet : Bool = false
    @State var exportLogs : Bool = false
    @Environment(\.colorScheme) var colorScheme


    
    
    var body: some View {
        NavigationView {
            List{
                Section(header: Text("Debug")) {
                    NavigationLink(destination: DataBrowserView()) {
                        MenuListItem(title: "Data Browser", systemImage: "photo", color: .green)
                    }
                    NavigationLink(destination: NetworkPage()) {
                        MenuListItem(title: "Peers List", systemImage: "network", color: .green)
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
                Section(header: Text("Logs")) {
                    Button(action: {
                        self.exportLogs.toggle()
                    }) {
                        MenuListItem(title: "Export Logs", systemImage: "square.and.arrow.up", color: .green)
                    }
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .sheet(isPresented: $exportLogsSheet) {
                        ExportLogs()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ditto Tools")
            .alert("Export Logs", isPresented: $exportLogs) {
                Button("Export") {
                    exportLogsSheet = true
                }
                Button("Cancel", role: .cancel) {}

            } message: {
                Text("Compressing the logs may take a few seconds.")

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
