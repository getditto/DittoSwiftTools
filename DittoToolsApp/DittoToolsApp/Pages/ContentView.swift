//
//  ContentView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoAllToolsMenu
import DittoSwift


struct ContentView: View {
    @ObservedObject private var dittoModel = DittoManager.shared
    @State var isShowingConfigurationSheet = DittoManager.shared.ditto == nil

    var body: some View {
        NavigationView {
            AllToolsMenu(ditto: dittoModel.ditto!)
                .navigationTitle("Ditto Tools")
                .navigationBarItems(trailing:
                                        Button(action: {
                                            isShowingConfigurationSheet.toggle()
                                        }) {
                                            Image(systemName: "gear")
                                        })

            // Default view when no tool is selected.
            Text("Please select a tool.")
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .sheet(isPresented: $isShowingConfigurationSheet) {
            ConfigurationView()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
