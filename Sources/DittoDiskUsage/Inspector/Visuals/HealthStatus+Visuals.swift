//
//  HealthStatus+Visuals.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Presentation properties for ``HealthStatus``. Kept separate from the model
/// so the enum itself stays free of icon-name and color choices.
extension HealthStatus {
    var systemImageName: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .unhealthy: return .red
        }
    }
}
