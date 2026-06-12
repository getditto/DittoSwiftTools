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

    public var body: some View {
        multiPlatformLayoutView
    }

    /// The main content of the view, a two column layout for tvos with an image and a menu, otherwise just the menu
    @ViewBuilder
    private var multiPlatformLayoutView: some View {
        #if os(tvOS)
            HStack {
                VStack {
                    logoView

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
        #elseif os(macOS)
            AllToolsMenu(ditto: DittoService.shared.ditto)
        #else
            AllToolsMenu(ditto: DittoService.shared.ditto)
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        VStack(spacing: 0) {
                            SyncButton(dittoService: dittoService)
                            copyButton
                        }
                    }
                }
        #endif
    }

    @ViewBuilder
    private var logoView: some View {
        Image("Ditto.LogoMark", bundle: .main)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .foregroundColor(.dittoBlue)
            .padding(180)
    }

    #if !os(tvOS)
        private var copyButton: some View {
            Button(action: {
                #if !os(macOS)
                // Copy SDK version to clipboard on tap
                UIPasteboard.general.string = Ditto.version
                #endif
            }) {
                HStack {
                    Text("SDK Version: \(Ditto.version)")
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    #endif
}
