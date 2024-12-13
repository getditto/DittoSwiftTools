//
//  AllToolsMenu.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoExportData
import DittoSwift


public struct AllToolsMenu: View {

    // Observe DittoService for changes in the Ditto instance
    @ObservedObject var dittoService = DittoService.shared

    // If the license info is not found, present the identity configuration sheet automatically
    @State var isShowingIdentityConfiguration = (IdentityConfigurationService.shared.activeConfiguration == nil)
    
    public let title:String
    public let showIdentityConfiguration:Bool
    
    // Public initializer with a default value for the title
    public init(title: String = "Ditto Tools", showIdentityConfiguration: Bool = true) {
        self.title = title
        self.showIdentityConfiguration = showIdentityConfiguration
    }
    
    public var body: some View {
        Group {
#if os(tvOS)
            HStack {
                VStack {
                    Image("Ditto.LogoMark.Blue", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.blue)
                        .padding(180)
                    
                    VStack(spacing: 8) {
                        Text("SDK Version: \(dittoService.ditto?.sdkVersion ?? Ditto.version)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let ditto = dittoService.ditto, ditto.activated {
                            Text(ditto.isSyncActive ? "Ditto is active." : "Ditto is not running.")
                        } else {
                            Text("No license found.")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                ToolsList()
                    .listStyle(.grouped)
            }
#else
            Group {
                ToolsList()
                    .listStyle(.insetGrouped)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    VStack(spacing: 0) {
                        SyncButton(ditto: dittoService.ditto)
                        CopyButton
                    }
                }
            }
#endif
        }
        .navigationTitle(title)
        .navigationBarItems(trailing:
                                Group {
            if showIdentityConfiguration {
                Button(action: {
                    isShowingIdentityConfiguration.toggle()
                }) {
                    Image(systemName: "gear")
                }
            }
        })
        .sheet(isPresented: $isShowingIdentityConfiguration) {
            IdentityConfigurationView()
        }
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
}




