//
//  MenuView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoAllToolsMenu
import DittoSwift
import SwiftUI

struct MenuView: View {

    // Observe DittoService for changes in the Ditto instance
    @ObservedObject var dittoService = DittoService.shared

    // If the license info is not found, present the Credentials view automatically
    @State var isShowingCredentialsView = (CredentialsService.shared.activeCredentials == nil)

    public let title: String

    // Public initializer with a default value for the title
    public init(title: String = "Ditto Tools") {
        self.title = title
    }

    public var body: some View {
        MultiPlatformLayoutView
            .navigationTitle(title)
            .navigationBarItems(
                trailing:
                    CredentialsButton
            )
            .sheet(isPresented: $isShowingCredentialsView) {
                CredentialsView()
            }
    }

    /// The main content of the view, a two column layout for tvos with an image and a menu, otherwise just the menu
    @ViewBuilder
    private var MultiPlatformLayoutView: some View {
        #if os(tvOS)
            HStack {
                VStack {
                    LogoView

                    SyncButton(dittoService: dittoService)
                        .buttonStyle(.plain)

                    Text("SDK Version: \(dittoService.ditto?.sdkVersion ?? Ditto.version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .focusSection()

                AllToolsMenu(ditto: DittoService.shared.ditto)
                    .listStyle(.grouped)
            }

        #else
            AllToolsMenu(ditto: DittoService.shared.ditto)
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        VStack(spacing: 0) {
                            SyncButton(dittoService: dittoService)
                            CopyButton
                        }
                    }
                }
        #endif
    }

    @ViewBuilder
    private var LogoView: some View {
        Image("Ditto.LogoMark.Blue", bundle: .main)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .foregroundColor(.dittoBlue)
            .padding(180)
    }

    #if !os(tvOS)
        private var CopyButton: some View {
            Button(action: {
                // Copy SDK version to clipboard on tap
                UIPasteboard.general.string = Ditto.version
            }) {
                HStack {
                    if let ditto = dittoService.ditto {
                        Text("SDK Version: \(ditto.sdkVersion)")
                    } else {
                        Text("SDK Version: \(Ditto.version)")
                    }

                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    #endif

    @ViewBuilder
    private var CredentialsButton: some View {
        Button(action: {
            isShowingCredentialsView.toggle()
        }) {
            Image(systemName: "key.2.on.ring.fill")
                #if os(tvOS)
                    .font(.subheadline)
                #endif
        }
    }
}
