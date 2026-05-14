//
//  HealthAndTrendSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct HealthAndTrendSection: View {
    let currentBytes: Int
    let thresholdBytes: Int
    let status: HealthStatus
    let historyTotals: [Int]
    let growthRatePerSecond: Double?

    var body: some View {
        Section(header: Text("Health & Trend")) {
            VStack(alignment: .leading, spacing: 12) {
                HealthIndicatorView(status: status)
                HealthGaugeView(
                    currentBytes: currentBytes,
                    thresholdBytes: thresholdBytes,
                    status: status
                )
                Divider()
                GrowthRateView(bytesPerSecond: growthRatePerSecond)
                SparklineView(values: historyTotals, color: status.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
    }
}
