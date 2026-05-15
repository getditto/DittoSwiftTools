//
//  CollectionScanSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct CollectionScanSection: View {
    let discoveredCollections: [String]
    let scanStates: [String: CollectionScanState]
    let selectedCollection: String?
    let isScanning: Bool
    let hasScanned: Bool
    let scanError: Error?
    let onScanTapped: () -> Void
    let onSelectCollection: (String) -> Void

    var body: some View {
        Section(header: Text("Collections")) {
            scanButton
            content
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var scanButton: some View {
        Button(action: onScanTapped) {
            HStack(spacing: 8) {
                if isScanning {
                    ProgressView()
                }
                Text(buttonLabel)
            }
        }
        .disabled(isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if let scanError {
            Label(
                "Couldn't list collections: \(scanError.localizedDescription)",
                systemImage: "exclamationmark.triangle"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        } else if !hasScanned {
            Text("Tap \"Scan collections\" to list local collections and their document counts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else if discoveredCollections.isEmpty {
            Text("No collections found in the local store.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            collectionDetail
            ranking
        }
    }

    @ViewBuilder
    private var collectionDetail: some View {
        Picker("Collection", selection: pickerBinding) {
            ForEach(discoveredCollections, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .pickerStyle(.menu)

        if let selected = selectedCollection, let state = scanStates[selected] {
            HStack {
                Text("Documents")
                    .font(.subheadline)
                Spacer()
                Text(detailValue(for: state))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var ranking: some View {
        HorizontalBarChartView(
            items: rankedItems,
            tint: .accentColor,
            valueFormatter: { $0.formattedAsCount }
        )
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private var buttonLabel: LocalizedStringKey {
        if isScanning { return "Scanning…" }
        return hasScanned ? "Re-scan collections" : "Scan collections"
    }

    private var pickerBinding: Binding<String> {
        Binding(
            get: { selectedCollection ?? "" },
            set: { onSelectCollection($0) }
        )
    }

    private var rankedItems: [HorizontalBarChartView.Item] {
        discoveredCollections.compactMap { name in
            guard case let .counted(count) = scanStates[name] else { return nil }
            return HorizontalBarChartView.Item(id: name, label: name, value: count)
        }
        .sorted { $0.value > $1.value }
    }

    private func detailValue(for state: CollectionScanState) -> String {
        switch state {
        case .pending: return "Counting…"
        case .counted(let n): return "\(n.formattedAsCount) docs"
        case .failed: return "Failed"
        }
    }
}
