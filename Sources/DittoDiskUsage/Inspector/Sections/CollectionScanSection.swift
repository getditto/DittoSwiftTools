//
//  CollectionScanSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Read-only state ``CollectionScanSection`` needs from the view model.
struct CollectionScanSectionState {
    let discoveredCollections: [String]
    let scanStates: [String: CollectionScanState]
    let selectedCollection: String?
    let isScanning: Bool
    let hasScanned: Bool
    let scanError: Error?
}

/// Callbacks for the section's user actions.
struct CollectionScanSectionActions {
    let onScanTapped: () -> Void
    let onSelectCollection: (String) -> Void
}

struct CollectionScanSection: View {
    let state: CollectionScanSectionState
    let actions: CollectionScanSectionActions

    /// Horizontal spacing between the progress spinner and the button label.
    private static let buttonHStackSpacing: CGFloat = 8

    var body: some View {
        Section {
            scanButton
            content
        } header: {
            Text("Collection Scan")
        } footer: {
            Text("Counts come from one-shot `SELECT COUNT(*)` queries — no live observers on user collections.")
        }
    }

    // MARK: - Subviews

    private var scanButton: some View {
        Button(action: actions.onScanTapped) {
            HStack(spacing: Self.buttonHStackSpacing) {
                if state.isScanning {
                    ProgressView()
                }
                Text(buttonLabel)
            }
        }
        .disabled(state.isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if let scanError = state.scanError {
            Label(
                "Couldn't list collections: \(scanError.localizedDescription)",
                systemImage: "exclamationmark.triangle"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        } else if !state.hasScanned {
            Text("Tap \"Scan collections\" to list local collections and their document counts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else if state.discoveredCollections.isEmpty {
            Text("No collections found in the local store.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            collectionDetail
        }
    }

    @ViewBuilder
    private var collectionDetail: some View {
        Picker("Collection", selection: pickerBinding) {
            ForEach(state.discoveredCollections, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .pickerStyle(.menu)

        if let selected = state.selectedCollection,
           let scanState = state.scanStates[selected] {
            HStack {
                Text("Documents")
                    .font(.subheadline)
                Spacer()
                detailValue(for: scanState)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var buttonLabel: LocalizedStringKey {
        if state.isScanning { return "Scanning…" }
        return state.hasScanned ? "Re-scan collections" : "Scan collections"
    }

    private var pickerBinding: Binding<String> {
        Binding(
            get: { state.selectedCollection ?? "" },
            set: { actions.onSelectCollection($0) }
        )
    }

    private func detailValue(for scanState: CollectionScanState) -> Text {
        switch scanState {
        case .pending: return Text("Counting…")
        case .counted(let n): return Text("\(Format.count(n)) docs")
        case .failed: return Text("Failed")
        }
    }
}
