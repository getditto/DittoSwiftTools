//
//  AllToolsMenu.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoExportData
import DittoSwift


public struct AllToolsMenu: View {
    
    /// Initialize the view with a Ditto instance.
    public init(ditto: Ditto) {
        DittoManager.shared.ditto = ditto
    }
    
    public var body: some View {
#if os(tvOS)
        HStack {
            VStack {
                Image("Ditto.LogoMark.Blue")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.blue)
                    .padding(180)
                
                Text("SDK Version: \(DittoManager.shared.ditto?.sdkVersion ?? "N/A")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ToolsList()
                .listStyle(.grouped)
        }
#else
        ToolsList()
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        // Copy SDK version to clipboard on tap
                        let sdkVersion = DittoManager.shared.ditto?.sdkVersion ?? "N/A"
                        UIPasteboard.general.string = sdkVersion
                    }) {
                        HStack {
                            Text("SDK Version: \(DittoManager.shared.ditto?.sdkVersion ?? "N/A")")
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
#endif
    }
}


/// A view that displays a list of diagnostic tools and data management options.
///
/// `ToolsList` organizes various tools into sections, each with its own set of options.
/// The view can be conditionally configured to include or exclude specific items based on
/// the platform (e.g., excluding certain features on tvOS).
///
/// - Note: On platforms other than tvOS, an additional section is included for exporting data,
///   which presents an alert to confirm the action.
fileprivate struct ToolsList: View {
    
    public var body: some View {
        List {
            Section(header: Text("Diagnostics")) {
                
#if canImport(WebKit)
                NavigationLink(destination: PresenceViewer()) {
                    ToolListItem(title: "Presence Viewer", systemImage: "network", color: .pink)
                }
#endif
                NavigationLink(destination: PeersListViewer()) {
                    ToolListItem(title: "Peers List", systemImage: "network", color: .blue)
                }
                NavigationLink(destination: DiskUsageViewer()) {
                    ToolListItem(title: "Disk Usage", systemImage: "opticaldiscdrive", color: .secondary)
                }
                NavigationLink(destination: DataBrowserView()) {
                    ToolListItem(title: "Data Browser", systemImage: "photo", color: .orange)
                }
                NavigationLink(destination: PresenceDegradationViewer()) {
                    ToolListItem(title: "Presence Degradation", systemImage: "network", color: .red)
                }
                NavigationLink(destination: HeartBeatViewer()) {
                    ToolListItem(title: "Heartbeat", systemImage: "heart.fill", color: .red)
                }
                NavigationLink(destination: PermissionsHealthViewer()) {
                    ToolListItem(title: "Permissions Health", systemImage: "stethoscope", color: .purple)
                }
            }
            Section(header: Text("Data Exporting")) {
                NavigationLink(destination:  LoggingDetailsViewer()) {
                    ToolListItem(title: "Logging", systemImage: "square.split.1x2", color: .green)
                }
            }
             
#if !os(tvOS)
            // Do not show on tvOS as export is not currently supported.
            Section(footer: Text("Export all Ditto data on this device as a .zip file.")) {
                ExportButton()
            }
#endif
        }
    }
}
        

/// A view that represents a single tool item in the tools list.
///
/// `ToolListItem` displays a tool's icon and title, with customizable colors for both the icon and the text.
/// This view is typically used within a list to represent different tools or diagnostics options available in the app.
fileprivate struct ToolListItem: View {

    var title: String
    var systemImage: String
    var color: Color = .accentColor
    var foregroundColor: Color = .white

    var body: some View {
        HStack(spacing: 16) {
            SettingsIcon(color: color, imageName: systemImage)
#if os(tvOS)
                .frame(width: 48, height: 48)
#else
                .frame(width: 29, height: 29)
#endif
            Text(title)
        }
    }
}


/// A view that displays an icon inside a rounded rectangle with a customizable background color.
/// 
/// `SettingsIcon` is used to render the icon associated with a tool in the `ToolListItem`.
/// The icon is centered within a rounded rectangle, and its size adjusts relative to the containing view.
fileprivate struct SettingsIcon: View {
    let color: Color
    let imageName: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: geometry.size.height * 0.26)
                    .foregroundColor(color)
                
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .imageScale(.small)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.height * 0.7, height: geometry.size.height * 0.7)
            }
        }
    }
}


#if !os(tvOS)
fileprivate struct ExportButton: View {
    
    // State variables to manage the presentation of alerts and sheets for exporting data
    @State private var presentExportDataAlert = false
    @State private var isExportDataSharePresented = false

    var body: some View {
        Button(action: {
            presentExportDataAlert.toggle()
        }) {
            Text("Export Data…")
                .foregroundColor(.accentColor)
        }
        .alert(isPresented: $presentExportDataAlert) {
            Alert(title: Text("Are you sure?"),
                  message: Text("Compressing the Ditto directory data may take a while."),
                  primaryButton: .cancel(Text("Cancel")),
                  secondaryButton: .default(Text("Export…")) {
                    isExportDataSharePresented = true
                print("ok!")
            })
        }
        .sheet(isPresented: $isExportDataSharePresented) {
            ExportData(ditto:  DittoManager.shared.ditto!)
        }

    }
}
#endif
