//
//  CollectionRankingSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 5/20/26.
//

import SwiftUI

/// Read-only state ``CollectionRankingSection`` needs.
struct CollectionRankingSectionState {
    let discoveredCollections: [String]
    let scanStates: [String: CollectionScanState]
    let hasScanned: Bool
    let scanError: Error?
}

struct CollectionRankingSection: View {
    let state: CollectionRankingSectionState

    var body: some View {
        Section {
            content
        } header: {
            Text("Collection Ranking")
        } footer: {
            Text("Sorted by document count, largest first. Collections whose count failed are omitted.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.scanError != nil {
            placeholder("Run a successful scan to see the ranking.")
        } else if !state.hasScanned {
            placeholder("Tap \"Scan collections\" above to see how collections rank by document count.")
        } else if state.discoveredCollections.isEmpty {
            placeholder("No collections to rank.")
        } else if rankedItems.isEmpty {
            // Some collections discovered but none has a count yet.
            if anyPending {
                placeholder("Counts are still in flight…")
            } else {
                placeholder("No counts available — every collection failed.")
            }
        } else {
            HorizontalBarChartView(
                items: rankedItems,
                tint: .accentColor,
                valueFormatter: CountFormatting.format
            )
        }
    }

    private func placeholder(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var rankedItems: [HorizontalBarChartView.Item] {
        state.discoveredCollections.compactMap { name in
            guard case let .counted(count) = state.scanStates[name] else { return nil }
            return HorizontalBarChartView.Item(id: name, label: name, value: count)
        }
        .sorted { $0.value > $1.value }
    }

    private var anyPending: Bool {
        state.scanStates.values.contains { scanState in
            if case .pending = scanState { return true }
            return false
        }
    }
}
