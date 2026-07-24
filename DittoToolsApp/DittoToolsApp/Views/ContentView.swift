//
//  ContentView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoAllToolsMenu
import DittoSwift
import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            MenuView()
                .navigationTitle("Ditto Tools")

            // Default view when no tool is selected.
            Text("Please select a tool.")
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

#Preview("Content View") {
    ContentView()
}
