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
        MultiPlatformLayoutView
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
        #elseif os(macOS)
        Text("Menu is not available on macOS")
        
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
                #if !os(macOS)
                // Copy SDK version to clipboard on tap
                UIPasteboard.general.string = Ditto.version
                #endif
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
}
