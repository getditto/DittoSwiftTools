//
//  HealthGaugeView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Horizontal capsule-fill gauge for current bytes against a threshold.
/// Status is computed from the two byte values internally so the caller
/// can't pass mismatched values.
struct HealthGaugeView: View {
    let currentBytes: Int
    let thresholdBytes: Int

    /// Spacing between the small label row and the gauge capsule.
    private static let labelToGaugeSpacing: CGFloat = 6

    /// Gauge capsule height — slim enough to look like a progress bar,
    /// thick enough to remain visible on small screens.
    private static let gaugeHeight: CGFloat = 8

    /// Opacity of the unfilled portion of the gauge capsule.
    private static let trackOpacity: Double = 0.2

    private var status: HealthStatus {
        HealthStatus(currentBytes: currentBytes, thresholdBytes: thresholdBytes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.labelToGaugeSpacing) {
            HStack {
                Text("\(percentText) used")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Format.bytes(currentBytes)) of \(Format.bytes(thresholdBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(Self.trackOpacity))
                    Capsule()
                        .fill(status.tint)
                        .frame(width: geometry.size.width * fillRatio)
                }
            }
            .frame(height: Self.gaugeHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Disk usage gauge")
        .accessibilityValue(Text("\(percentText) of threshold used"))
    }

    private var fillRatio: CGFloat {
        guard thresholdBytes > 0 else { return 0 }
        let ratio = CGFloat(currentBytes) / CGFloat(thresholdBytes)
        return min(max(ratio, 0), 1)
    }

    private var percentText: String {
        guard thresholdBytes > 0 else { return "—" }
        let ratio = Double(currentBytes) / Double(thresholdBytes)
        let clamped = min(max(ratio, 0), 1)
        return String(format: "%.0f%%", clamped * 100)
    }
}
