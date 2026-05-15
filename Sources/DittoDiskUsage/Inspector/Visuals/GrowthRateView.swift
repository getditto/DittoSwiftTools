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

    /// Spacing between the trend icon and the label/value column.
    private static let iconToTextSpacing: CGFloat = 6

    /// Spacing between the "Growth rate" caption and the formatted value.
    private static let captionToValueSpacing: CGFloat = 2

    var body: some View {
        HStack(spacing: Self.iconToTextSpacing) {
            Image(systemName: iconName)
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: Self.captionToValueSpacing) {
                Text("Growth rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                formattedText
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Growth rate")
        .accessibilityValue(formattedText)
    }

    // MARK: - Formatting

    /// `Text` rather than `String` so the literals go through
    /// `LocalizedStringKey` rather than the non-localized `Text(String)` init.
    private var formattedText: Text {
        guard let rate = bytesPerSecond else { return Text("—") }
        if abs(rate) < Self.stableThresholdBytesPerSecond { return Text("Stable") }
        let perMinute = Int(abs(rate * 60).rounded())
        let sign = rate >= 0 ? "+" : "−"
        return Text("\(sign)\(ByteCountFormatting.format(perMinute)) / min")
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
