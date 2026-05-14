//
//  HealthGaugeView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Horizontal capsule-fill gauge for current bytes against a threshold.
struct HealthGaugeView: View {
    let currentBytes: Int
    let thresholdBytes: Int
    let status: HealthStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(currentBytes.formattedByteCount) of \(thresholdBytes.formattedByteCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(status.tint)
                        .frame(width: geometry.size.width * fillRatio)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Disk usage gauge")
        .accessibilityValue(Text("\(currentBytes.formattedByteCount) of \(thresholdBytes.formattedByteCount)"))
    }

    private var fillRatio: CGFloat {
        guard thresholdBytes > 0 else { return 0 }
        let ratio = CGFloat(currentBytes) / CGFloat(thresholdBytes)
        return min(max(ratio, 0), 1)
    }
}
