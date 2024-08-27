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
                    NavigationLink(destination: AllToolsViewer()) {
                        MenuListItem(title: "All Tools Menu", systemImage: "menucard", color: .blue)
                    }
                }
                Section(header: Text("Configuration")) {
                    NavigationLink(destination: Login()) {
                        MenuListItem(title: "Change Identity", systemImage: "envelope", color: .purple)
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
