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
            CollectionScanSection(
                discoveredCollections: viewModel.discoveredCollections,
                scanStates: viewModel.collectionScanStates,
                selectedCollection: viewModel.selectedCollection,
                isScanning: viewModel.isScanningCollections,
                hasScanned: viewModel.hasScannedCollections,
                scanError: viewModel.scanError,
                onScanTapped: viewModel.scanCollections,
                onSelectCollection: viewModel.selectCollection
            )
            DocSizeDistributionSection(
                selectedCollection: viewModel.selectedCollection,
                totalDocCount: totalDocsForSelected,
                sample: sampleForSelected,
                sampleLimit: DiskUsageInspectorViewModel.sampleLimit,
                isSampling: viewModel.isSamplingCollection,
                hasScannedCollections: viewModel.hasScannedCollections,
                sampleError: viewModel.sampleError,
                onSampleTapped: viewModel.sampleSelectedCollection
            )
            GlossarySection()
        }
        .navigationTitle("Disk Usage Inspector")
    }

    private var totalDocsForSelected: Int? {
        guard let name = viewModel.selectedCollection,
              case let .counted(total) = viewModel.collectionScanStates[name] else {
            return nil
        }
        return total
    }

    private var sampleForSelected: CollectionSample? {
        guard let name = viewModel.selectedCollection else { return nil }
        return viewModel.collectionSamples[name]
    }
}
