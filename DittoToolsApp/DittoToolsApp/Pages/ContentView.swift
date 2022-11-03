//
//  Copyright © 2022 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift
import Combine

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
                }
                Section(header: Text("Configuration")) {
                    NavigationLink(destination: Login()) {
                        MenuListItem(title: "Change Identity", systemImage: "envelope", color: .green)
                    }
                }
                
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ditto Tools")
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $viewModel.isShowingLoginSheet, content: {
            Login()
                .onSubmit {
                    viewModel.isShowingLoginSheet = false
                }
        })
        VStack {
            Text("SDK Version: \(dittoModel.ditto!.sdkVersion ?? "N/A")")
        }.padding()
}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
