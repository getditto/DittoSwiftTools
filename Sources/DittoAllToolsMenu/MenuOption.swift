//
//  MenuOption.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// `MenuOption` enum defines various menu options in the tools app.
/// Each case represents a specific feature or tool that can be selected by the user.
enum MenuOption: String, CaseIterable {
    case presenceViewer = "Presence Viewer"
    case peersList = "Peers List"
    case presenceDegradation = "Presence Degradation"
    case diskUsage = "Disk Usage"
    case permissionsHealth = "Permissions Health"
    case heartbeat = "Heartbeat"
    case dataBrowser = "Data Browser"
    case logging = "Logging"

    // MARK: - Section
    
    /// `Section` enum is used to group related `MenuOption`s.
    /// Each section represents a high-level category of tools available in the application.
    enum Section: String, CaseIterable {
        case networkAndPresenceTools = "Network"
        case systemAndPerformanceTools = "System"
        case diagnosticsAndDebuggingTools = "Debugging"
        
        /// Returns a list of `MenuOption`s available for each section.
        /// - On tvOS, some options are excluded.
        var options: [MenuOption] {
            switch self {
            case .networkAndPresenceTools:
#if os(tvOS)
                return [.peersList, .presenceDegradation, .heartbeat]
#else
                return [.presenceViewer, .peersList, .presenceDegradation, .heartbeat]

#endif
            case .systemAndPerformanceTools:
                return [.permissionsHealth, .diskUsage]
            case .diagnosticsAndDebuggingTools:
                return [.dataBrowser, .logging]
            }
        }
    }
    
    // MARK: - Icon
    
    /// Returns the SF Symbol icon name for each `MenuOption`.
    /// - Used to visually represent each menu option in the UI.
    var icon: String {
        switch self {
        case .presenceViewer:
            return "network"
        case .peersList:
            return "list.bullet"
        case .presenceDegradation:
            return "exclamationmark.triangle"
        case .diskUsage:
            return "opticaldiscdrive"
        case .permissionsHealth:
            return "checklist"
        case .heartbeat:
            return "waveform.path.ecg"
        case .dataBrowser:
            return "folder"
        case .logging:
            return "list.bullet.rectangle"
        }
    }

    // MARK: - Color
    
    /// Returns the associated color for each `MenuOption`.
    /// - Used to color-code menu options in the UI.
    var color: Color {
        switch self {
        case .presenceViewer:
            return .green
        case .peersList:
            return .blue
        case .presenceDegradation:
            return .red
        case .diskUsage:
            return .secondary
        case .permissionsHealth:
            return .purple
        case .heartbeat:
            return .pink
        case .dataBrowser:
            return .orange
        case .logging:
            return .gray
        }
    }

    // MARK: - Destination View
    
    /// Returns the appropriate destination view based on the selected `MenuOption` and the provided `ditto` instance.
    /// - If `ditto` is `nil`, an empty view is returned.
    /// - If `ditto` is not `nil`, a corresponding view is returned based on the selected menu option.
    /// - Note: Some views require importing `WebKit`.
    /// - Parameter ditto: The `Ditto` instance, which powers many of the views.
    /// - Returns: A SwiftUI `View` that represents the destination for the selected menu option.
    @ViewBuilder
    func destinationView(ditto: Ditto?) -> some View {
        if let ditto = ditto {
            switch self {
#if !os(macOS)

            case .presenceViewer:
#if canImport(WebKit)
                PresenceViewer(ditto: ditto)
#else
                EmptyView()
#endif
            case .peersList:
                PeersListViewer(ditto: ditto)
            case .presenceDegradation:
                PresenceDegradationViewer(ditto: ditto)
#endif
            case .diskUsage:
                DiskUsageViewer(ditto: ditto)
#if !os(macOS)

            case .permissionsHealth:
                PermissionsHealthViewer()
            case .heartbeat:
                HeartBeatViewer(ditto: ditto)
            case .dataBrowser:
                DataBrowserView(ditto: ditto)
            case .logging:
                LoggingDetailsViewer(ditto: ditto)
#endif
            default:
                EmptyView()

            }
        } else {
            EmptyView()  // Return an empty view when ditto is nil
        }
    }
}
