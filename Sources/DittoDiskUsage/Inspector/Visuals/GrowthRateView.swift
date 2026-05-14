//
//  GrowthRateView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Renders the session growth rate as a signed per-minute byte count, or a
/// "Stable" / placeholder when the rate is not yet meaningful.
struct GrowthRateView: View {
    let bytesPerSecond: Double?

    /// Below 1 B/s the per-minute display rounds to zero. Show "Stable".
    private static let stableThresholdBytesPerSecond: Double = 1.0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Growth rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Growth rate")
        .accessibilityValue(Text(formatted))
    }

    // MARK: - Formatting

    private var formatted: String {
        guard let rate = bytesPerSecond else { return "—" }
        if abs(rate) < Self.stableThresholdBytesPerSecond { return "Stable" }
        let perMinute = Int(abs(rate * 60).rounded())
        let sign = rate >= 0 ? "+" : "−"
        return "\(sign)\(perMinute.formattedByteCount) / min"
    }

    private var iconName: String {
        guard let rate = bytesPerSecond,
              abs(rate) >= Self.stableThresholdBytesPerSecond else {
            return "minus"
        }
        return rate > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private var tint: Color {
        guard let rate = bytesPerSecond,
              abs(rate) >= Self.stableThresholdBytesPerSecond else {
            return .secondary
        }
        // `.blue` for growing (neutral direction cue) keeps `.orange`/`.red`
        // exclusively meaning "approaching/over threshold" in the gauge.
        return rate > 0 ? .blue : .green
    }
}
