//
//  ContentView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoAllToolsMenu
import DittoSwift


struct ContentView: View {

    var body: some View {
        NavigationView {
            AllToolsMenu()

            // Default view when no tool is selected.
            Text("Please select a tool.")
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}


#Preview {
    ContentView()
}
