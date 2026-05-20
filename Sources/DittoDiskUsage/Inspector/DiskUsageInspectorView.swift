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
            // Overview lives at the top without a group header — matches
            // the Android layout.
            TotalCounterSection(state: TotalCounterSectionState(
                totalBytes: storage.breakdown.totalOnDiskBytes,
                hasReceivedFirstSnapshot: storage.hasReceivedFirstSnapshot,
                status: storage.healthStatus,
                fillRatio: storage.fillRatio,
                // The VM already gates these on scanError, so a failed
                // scan leaves the overview's count strip blank.
                collectionCount: inspection.collectionCount,
                totalDocumentCount: inspection.totalDocumentCount
            ))

            // MARK: Health group

            groupHeader(
                title: "Health",
                subtitle: "Is usage okay & trending?",
                systemImageName: "heart.text.square",
                tint: .green
            )

            HealthStatusSection(
                state: HealthStatusSectionState(
                    currentBytes: storage.breakdown.totalOnDiskBytes,
                    thresholdBytes: storage.healthThresholdBytes,
                    status: storage.healthStatus,
                    hasReceivedFirstSnapshot: storage.hasReceivedFirstSnapshot
                ),
                actions: HealthStatusSectionActions(
                    onIncreaseThreshold: {
                        storage.adjustHealthThreshold(by: DiskStorageViewModel.thresholdStepBytes)
                    },
                    onDecreaseThreshold: {
                        storage.adjustHealthThreshold(by: -DiskStorageViewModel.thresholdStepBytes)
                    }
                )
            )

            DiskGrowthSection(state: DiskGrowthSectionState(
                historyTotals: storage.historyTotalBytes,
                status: storage.healthStatus,
                growthRatePerSecond: storage.growthRatePerSecond
            ))

            GrowthPredictionSection(state: GrowthPredictionSectionState(
                estimatedSecondsToThreshold: storage.estimatedSecondsToThreshold,
                remainingBytes: storage.healthThresholdBytes - storage.breakdown.totalOnDiskBytes
            ))

            // MARK: Collections group

            groupHeader(
                title: "Collections",
                subtitle: "Per-collection detail",
                systemImageName: "tray.full",
                tint: .orange
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

            CollectionRankingSection(state: CollectionRankingSectionState(
                discoveredCollections: inspection.discoveredCollections,
                scanStates: inspection.collectionScanStates,
                hasScanned: inspection.hasScannedCollections,
                scanError: inspection.scanError
            ))

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

            // MARK: Reference group

            groupHeader(
                title: "Reference",
                subtitle: "Definitions & help",
                systemImageName: "book",
                tint: .gray
            )

            GlossarySection()
            AboutSection()
        }
        .navigationTitle("Disk Usage Inspector")
    }

    @ViewBuilder
    private func groupHeader(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImageName: String,
        tint: Color
    ) -> some View {
        Section {
            GroupHeaderRow(
                title: title,
                subtitle: subtitle,
                systemImageName: systemImageName,
                tint: tint
            )
            .listRowBackground(Color.clear)
        }
    }
}
