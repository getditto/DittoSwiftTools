//
//  MenuItem.swift
//
//  This file defines views that represent individual menu options and their associated icons in the tools list.
//  Each `MenuItem` links to the corresponding view based on the selected option. The file also defines supporting views for rendering tool items and their icons.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// A view that represents a single menu option in the tools list.
///
/// `MenuItem` renders a `ToolListItem` representing a tool option. If the `ditto` instance is available,
/// the item becomes an interactive navigation link that takes the user to the tool's destination view.
/// Otherwise, the item is displayed in a disabled state.
struct MenuItem: View {
    let option: MenuOption
    @ObservedObject var dittoService = DittoService.shared

    var body: some View {
        if let ditto = dittoService.ditto, ditto.activated {
            NavigationLink(destination: option.destinationView(ditto: ditto)) {
                ToolListItem(title: option.rawValue, systemImageName: option.icon, color: option.color)
            }
        } else {
            ToolListItem(title: option.rawValue, systemImageName: option.icon, color: .secondary)
                .foregroundColor(.secondary)
                .disabled(true)
        }
    }
}


/// A view that represents a single tool item in the tools list.
///
/// `ToolListItem` displays a tool's icon and title, with customizable colors for both the icon and the text.
/// This view is typically used within a list to represent different tools or diagnostics options available in the app.
fileprivate struct ToolListItem: View {

    var title: String
    var systemImageName: String
    var color: Color = .accentColor
    var foregroundColor: Color = .white

    var body: some View {
        HStack(spacing: 16) {
            SettingsIcon(backgroundColor: color, systemImageName: systemImageName)
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
    let backgroundColor: Color
    let systemImageName: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // A rounded rectangle with a corner radius that scales based on the geometry's height
                RoundedRectangle(cornerRadius: geometry.size.height * 0.26)
                    .foregroundColor(backgroundColor)
                
                // The tool icon, sized and centered within the rounded rectangle
                Image(systemName: systemImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .imageScale(.small)
                    .foregroundColor(.white)
                    .frame(width: geometry.size.height * 0.7, height: geometry.size.height * 0.7)
            }
        }
    }
}
