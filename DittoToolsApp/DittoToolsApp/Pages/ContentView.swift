//
//  ContentView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoAllToolsMenu
import DittoSwift


class MainListViewModel: ObservableObject {
    @Published var isShowingLoginSheet = DittoManager.shared.ditto == nil
}


struct ContentView: View {

    @StateObject private var viewModel = MainListViewModel()

    @ObservedObject private var dittoModel = DittoManager.shared

    var body: some View {
        NavigationView {
            AllToolsViewer()
                .navigationTitle("Ditto Tools")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.isShowingLoginSheet.toggle()
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }

            // Default view when no tool is selected.
            Text("Please select a tool.")
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
#if !os(tvOS)
                .background(Color(UIColor.systemBackground))
#endif            
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
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
