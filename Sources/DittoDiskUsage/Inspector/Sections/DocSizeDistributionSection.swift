//
//  DocSizeDistributionSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// Read-only state ``DocSizeDistributionSection`` needs from the view model.
struct DocSizeDistributionSectionState {
    let selectedCollection: String?
    let totalDocCount: Int?
    let sample: CollectionSample?
    let sampleLimit: Int
    let isSampling: Bool
    let hasScannedCollections: Bool
    let scanFailed: Bool
    let sampleError: Error?
}

struct DocSizeDistributionSection: View {
    let state: DocSizeDistributionSectionState
    let onSampleTapped: () -> Void

    /// Horizontal spacing between the progress spinner and the button label.
    private static let buttonHStackSpacing: CGFloat = 8

    /// Top padding on visual elements so they don't crowd siblings.
    private static let topPadding: CGFloat = 4

    var body: some View {
        Section {
            content
        } header: {
            Text("Document Size Distribution")
        } footer: {
            Text("Each document's size is its JSON serialization length. The sample takes the first documents the store returns, not a random pick. Sampling holds up to \(Format.count(CollectionInspectionViewModel.sampleLimit)) documents in memory at peak and releases each one right after measuring.")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        if state.scanFailed {
            Text("Scan failed — sample is unavailable until the scan succeeds.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else if !state.hasScannedCollections {
            Text("Scan collections first to sample one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else if state.selectedCollection == nil {
            Text("No collection available to sample.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            sampleButton
            sampleContent
        }
    }

    private var sampleButton: some View {
        Button(action: onSampleTapped) {
            HStack(spacing: Self.buttonHStackSpacing) {
                if state.isSampling { ProgressView() }
                Text(buttonLabel)
            }
        }
        .disabled(state.isSampling)
    }

    @ViewBuilder
    private var sampleContent: some View {
        if let sampleError = state.sampleError {
            Label(
                "Couldn't sample collection: \(sampleError.localizedDescription)",
                systemImage: "exclamationmark.triangle"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        } else if let sample = state.sample {
            summary(for: sample)
            histogram(for: sample)
            footnote
        } else {
            Text("Tap Sample to group up to \(Format.count(state.sampleLimit)) documents by JSON byte size.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func summary(for sample: CollectionSample) -> some View {
        HStack {
            Text("Sampled")
                .font(.subheadline)
            Spacer()
            summaryText(for: sample)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func histogram(for sample: CollectionSample) -> some View {
        HorizontalBarChartView(
            items: sample.buckets.map {
                HorizontalBarChartView.Item(id: $0.id, label: $0.label, value: $0.count)
            },
            tint: .accentColor,
            valueFormatter: Format.count
        )
        .padding(.top, Self.topPadding)
    }

    private var footnote: some View {
        Text("Approximation based on JSON serialization. Actual on-disk size includes CRDT metadata and indexes.")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Self.topPadding)
    }

    // MARK: - Helpers

    private var buttonLabel: LocalizedStringKey {
        if state.isSampling { return "Sampling…" }
        return state.sample == nil ? "Sample documents" : "Re-sample documents"
    }

    private func summaryText(for sample: CollectionSample) -> Text {
        let sampledText = Format.count(sample.sampledCount)
        if let total = state.totalDocCount {
            // Counts match — we sampled the whole collection.
            if sample.sampledCount == total {
                return Text("All \(Format.count(total)) docs")
            }
            // Sample was capped by the limit, scan count is bigger.
            if sample.sampledCount < total, sample.reachedLimit {
                return Text("\(sampledText) of \(Format.count(total)) docs")
            }
            // Counts don't match for some other reason (collection changed
            // since the scan). Show what we actually sampled.
            return Text("\(sampledText) docs")
        }
        // Without a scan count, `reachedLimit` is the best we have.
        if sample.reachedLimit {
            return Text("\(sampledText) docs (collection may be larger)")
        }
        return Text("\(sampledText) docs")
    }
}
