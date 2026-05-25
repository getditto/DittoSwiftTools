//
//  DiskGrowthSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/20/26.
//

import SwiftUI

/// Read-only state ``DiskGrowthSection`` needs.
struct DiskGrowthSectionState {
    let historyTotals: [Int]
    let status: HealthStatus
    let growthRatePerSecond: Double?
}

struct DiskGrowthSection: View {
    let state: DiskGrowthSectionState

    /// Spacing between the growth-rate row and the sparkline.
    private static let stackSpacing: CGFloat = 8

    /// Vertical padding inside the row.
    private static let verticalPadding: CGFloat = 6

    /// Window length the footer cites — sourced from the view model so
    /// the two can't drift apart.
    private static let windowSeconds: Int = Int(DiskStorageViewModel.growthRateWindowSeconds)

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Self.stackSpacing) {
                headerRow
                GrowthRateView(bytesPerSecond: state.growthRatePerSecond)
                SparklineView(values: state.historyTotals, color: state.status.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.verticalPadding)
        } header: {
            Text("Disk Growth")
        } footer: {
            Text("Rate averaged over a \(Self.windowSeconds)-second window of disk usage snapshots from this session. Resets when the inspector closes.")
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Total over time")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Spacer()
            if let latest = state.historyTotals.last {
                Text(Format.bytes(latest))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
