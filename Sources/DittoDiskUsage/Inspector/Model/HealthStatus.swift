//
//  HealthStatus.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Three-state health indicator derived from `currentBytes` versus a configured
/// threshold.
public enum HealthStatus: Hashable, Sendable {
    case healthy
    case warning
    case unhealthy

    /// 80% of threshold — warn before the limit is hit.
    public static let warningRatio: Double = 0.8

    /// At or above the threshold.
    public static let unhealthyRatio: Double = 1.0

    public init(currentBytes: Int, thresholdBytes: Int) {
        guard thresholdBytes > 0 else {
            self = .healthy
            return
        }
        let ratio = Double(currentBytes) / Double(thresholdBytes)
        switch ratio {
        case ..<Self.warningRatio: self = .healthy
        case Self.warningRatio..<Self.unhealthyRatio: self = .warning
        default: self = .unhealthy
        }
    }

    public var label: LocalizedStringKey {
        switch self {
        case .healthy: return "Healthy"
        case .warning: return "Approaching threshold"
        case .unhealthy: return "Over threshold"
        }
    }
}
