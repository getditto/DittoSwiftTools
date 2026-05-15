//
//  HealthAndTrendSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Input state for ``HealthAndTrendSection``. Wraps the section's inputs
/// so the view doesn't take many positional parameters.
struct HealthAndTrendSectionState {
    let currentBytes: Int
    let thresholdBytes: Int
    let status: HealthStatus
    let historyTotals: [Int]
    let growthRatePerSecond: Double?
}

struct HealthAndTrendSection: View {
    let state: HealthAndTrendSectionState

    /// Spacing between the indicator, gauge, growth rate, and sparkline.
    private static let stackSpacing: CGFloat = 12

    /// Vertical padding inside the row.
    private static let verticalPadding: CGFloat = 6

    var body: some View {
        Section(header: Text("Health & Trend")) {
            VStack(alignment: .leading, spacing: Self.stackSpacing) {
                HealthIndicatorView(status: state.status)
                HealthGaugeView(
                    currentBytes: state.currentBytes,
                    thresholdBytes: state.thresholdBytes
                )
                Divider()
                GrowthRateView(bytesPerSecond: state.growthRatePerSecond)
                SparklineView(values: state.historyTotals, color: state.status.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        }
    }
}
