//
//  ContentView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoAllToolsMenu
import DittoSwift
import SwiftUI

struct ContentView: View {

    // If the license info is not found, present the Credentials view automatically
    @State var isShowingCredentialsView = (CredentialsService.shared.activeCredentials == nil)

    var body: some View {
        NavigationView {
            MenuView()
                .navigationTitle("Ditto Tools")
                .navigationBarItems(
                    trailing:
                        CredentialsButton
                )
                .sheet(isPresented: $isShowingCredentialsView) {
                    CredentialsView()
                }

            // Default view when no tool is selected.
            Text("Please select a tool.")
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }

    @ViewBuilder
    private var CredentialsButton: some View {
        Button(action: {
            isShowingCredentialsView.toggle()
        }) {
            Image("key.2.on.ring.fill")
                #if os(tvOS)
                    .font(.subheadline)
                #endif
        }
    }

}

#Preview("Content View") {
    ContentView(isShowingCredentialsView: false)
}

#Preview("Credentials View") {
    ContentView(isShowingCredentialsView: true)
}
