//
//  DocSizeDistributionSection.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

struct DocSizeDistributionSection: View {
    let selectedCollection: String?
    let totalDocCount: Int?
    let sample: CollectionSample?
    let sampleLimit: Int
    let isSampling: Bool
    let hasScannedCollections: Bool
    let sampleError: Error?
    let onSampleTapped: () -> Void

    var body: some View {
        Section(header: Text("Document Size Distribution")) {
            content
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        if !hasScannedCollections {
            Text("Scan collections first to sample one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else if selectedCollection == nil {
            Text("No collection available to sample.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        } else {
            sampleButton
            sampleContent
        }
    }

    @ViewBuilder
    private var sampleButton: some View {
        Button(action: onSampleTapped) {
            HStack(spacing: 8) {
                if isSampling { ProgressView() }
                Text(buttonLabel)
            }
        }
        .disabled(isSampling)
    }

    @ViewBuilder
    private var sampleContent: some View {
        if let sampleError {
            Label(
                "Couldn't sample collection: \(sampleError.localizedDescription)",
                systemImage: "exclamationmark.triangle"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        } else if let sample {
            summary(for: sample)
            histogram(for: sample)
            footnote
        } else {
            Text("Tap Sample to bucket up to \(sampleLimit.formattedAsCount) documents by JSON byte size.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func summary(for sample: CollectionSample) -> some View {
        HStack {
            Text("Sampled")
                .font(.subheadline)
            Spacer()
            Text(summaryText(for: sample))
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
            valueFormatter: { $0.formattedAsCount }
        )
        .padding(.top, 4)
    }

    private var footnote: some View {
        Text("Approximation based on JSON serialization. Actual on-disk size includes CRDT metadata and indexes.")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    // MARK: - Helpers

    private var buttonLabel: LocalizedStringKey {
        if isSampling { return "Sampling…" }
        return sample == nil ? "Sample documents" : "Re-sample documents"
    }

    private func summaryText(for sample: CollectionSample) -> String {
        let sampledText = sample.sampledCount.formattedAsCount
        if let total = totalDocCount {
            // Counts match — we sampled the whole collection.
            if sample.sampledCount == total {
                return "All \(total.formattedAsCount) docs"
            }
            // Sample was capped by the limit, scan count is bigger.
            if sample.sampledCount < total, sample.reachedLimit {
                return "\(sampledText) of \(total.formattedAsCount) docs"
            }
            // Counts don't match for some other reason (collection changed
            // since the scan). Show what we actually sampled.
            return "\(sampledText) docs"
        }
        // Without a scan count, `reachedLimit` is the best we have.
        if sample.reachedLimit {
            return "\(sampledText) docs (collection may be larger)"
        }
        return "\(sampledText) docs"
    }
}
