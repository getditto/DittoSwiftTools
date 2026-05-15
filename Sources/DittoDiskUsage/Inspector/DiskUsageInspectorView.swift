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
    @StateObject private var storage: DiskStorageViewModel
    @StateObject private var inspection: CollectionInspectionViewModel

    public init(ditto: Ditto) {
        _storage = StateObject(wrappedValue: DiskStorageViewModel(ditto: ditto))
        _inspection = StateObject(wrappedValue: CollectionInspectionViewModel(ditto: ditto))
    }

    /// Initializer that accepts pre-built view models. Useful for sharing
    /// state across views or injecting fakes in tests.
    public init(
        storage: DiskStorageViewModel,
        inspection: CollectionInspectionViewModel
    ) {
        _storage = StateObject(wrappedValue: storage)
        _inspection = StateObject(wrappedValue: inspection)
    }

    public var body: some View {
        List {
            TotalCounterSection(
                totalBytes: storage.breakdown.totalOnDiskBytes,
                hasReceivedFirstSnapshot: storage.hasReceivedFirstSnapshot
            )
            HealthAndTrendSection(
                state: HealthAndTrendSectionState(
                    currentBytes: storage.breakdown.totalOnDiskBytes,
                    thresholdBytes: storage.healthThresholdBytes,
                    status: storage.healthStatus,
                    historyTotals: storage.historyTotalBytes,
                    growthRatePerSecond: storage.growthRatePerSecond
                )
            )
            CollectionScanSection(
                state: CollectionScanSectionState(
                    discoveredCollections: inspection.discoveredCollections,
                    scanStates: inspection.collectionScanStates,
                    selectedCollection: inspection.selectedCollection,
                    isScanning: inspection.isScanningCollections,
                    hasScanned: inspection.hasScannedCollections,
                    scanError: inspection.scanError
                ),
                actions: CollectionScanSectionActions(
                    onScanTapped: inspection.scanCollections,
                    onSelectCollection: inspection.selectCollection
                )
            )
            DocSizeDistributionSection(
                state: DocSizeDistributionSectionState(
                    selectedCollection: inspection.selectedCollection,
                    totalDocCount: inspection.totalDocsForSelected,
                    sample: inspection.sampleForSelected,
                    sampleLimit: CollectionInspectionViewModel.sampleLimit,
                    isSampling: inspection.isSamplingCollection,
                    hasScannedCollections: inspection.hasScannedCollections,
                    scanFailed: inspection.scanError != nil,
                    sampleError: inspection.sampleError
                ),
                onSampleTapped: inspection.sampleSelectedCollection
            )
            GlossarySection()
        }
        .navigationTitle("Disk Usage Inspector")
    }
}
