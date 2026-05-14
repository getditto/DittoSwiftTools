//
//  DiskUsageInspectorView.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI
import DittoSwift

/// Visualizes Ditto's local on-disk storage using only public SDK APIs.
public struct DiskUsageInspectorView: View {
    @StateObject private var viewModel: DiskUsageInspectorViewModel

    public init(ditto: Ditto) {
        _viewModel = StateObject(wrappedValue: DiskUsageInspectorViewModel(ditto: ditto))
    }

    public var body: some View {
        List {
            TotalCounterSection(
                totalBytes: viewModel.breakdown.totalOnDiskBytes,
                hasReceivedFirstSnapshot: viewModel.hasReceivedFirstSnapshot
            )
            HealthAndTrendSection(
                currentBytes: viewModel.breakdown.totalOnDiskBytes,
                thresholdBytes: viewModel.healthThresholdBytes,
                status: viewModel.healthStatus,
                historyTotals: viewModel.historyTotalBytes,
                growthRatePerSecond: viewModel.growthRatePerSecond
            )
            GlossarySection()
        }
        .navigationTitle("Disk Usage Inspector")
    }
}
