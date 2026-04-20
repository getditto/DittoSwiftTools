//
//  DiskUsageInspectorView.swift
//  DittoSwiftTools/DittoDiskUsage
//

import SwiftUI
import DittoSwift
import DittoExportData

public struct DiskUsageInspectorView: View {
    @ObservedObject private var viewModel: DiskUsageInspectorViewModel
    @State private var presentExportDataAlert = false
    @State private var presentExportDataShare = false

    /// Create a Disk Usage Inspector backed by a **pre-existing** view model.
    /// Use this when you want the view model to survive across open/close cycles
    /// (e.g., hold it on your app's DittoManager singleton so charts keep history).
    public init(viewModel: DiskUsageInspectorViewModel) {
        self.viewModel = viewModel
    }

    /// Convenience initializer that creates a **new** view model.
    /// History resets each time the view is recreated.
    public init(ditto: Ditto, healthThresholdBytes: Int = 500_000_000) {
        self.viewModel = DiskUsageInspectorViewModel(ditto: ditto, healthThresholdBytes: healthThresholdBytes)
    }

    public var body: some View {
        List {
            overviewSection
            parseValidatorSection

            groupHeader(title: "Storage", subtitle: "Where is space going?", icon: "internaldrive", color: .blue)
            storageBreakdownSection
            donutChartSection
            contentVsInfrastructureSection
            attachmentsSection
            attachmentGCSection

            groupHeader(title: "Health", subtitle: "Is usage okay & trending?", icon: "heart.text.square", color: .green)
            healthSection
            growthRateSection
            growthPredictionSection

            groupHeader(title: "Collections", subtitle: "Opt-in per-collection scan", icon: "tray.full", color: .orange)
            collectionScanSection
            if !viewModel.collectionCounts.isEmpty {
                collectionRankingSection
            }
            if !viewModel.selectedCollection.isEmpty {
                docSizeDistributionSection
            }

            groupHeader(title: "Reference", subtitle: "Raw data & help", icon: "book", color: .secondary)
            fileListingSection
            glossarySection
            footerSection
        }
        .navigationTitle("Disk Usage Inspector")
    }

    // MARK: - Group Header

    @ViewBuilder
    private func groupHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(.subheadline, design: .rounded).bold())
                        .tracking(1.2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
            .listRowBackground(Color.clear)
            #if os(tvOS)
            .focusable(true)
            #endif
        }
    }

    // MARK: - Overview

    private var healthBadge: (icon: String, text: String, color: Color) {
        let current = viewModel.breakdown.totalOnDiskBytes
        let threshold = viewModel.unhealthySizeInBytes
        let ratio = threshold > 0 ? Double(current) / Double(threshold) : 0
        if ratio >= 1.0 {
            return ("exclamationmark.triangle.fill", "Critical", .red)
        } else if ratio >= 0.75 {
            return ("exclamationmark.circle.fill", "Warning", .orange)
        } else {
            return ("checkmark.circle.fill", "Healthy", .green)
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total on Disk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    AnimatedByteCounterView(
                        targetBytes: viewModel.breakdown.totalOnDiskBytes,
                        font: .system(.title, design: .rounded).bold(),
                        color: .primary
                    )
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: healthBadge.icon)
                        .foregroundColor(healthBadge.color)
                    Text(healthBadge.text)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(healthBadge.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(healthBadge.color.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.vertical, 4)
            #if os(tvOS)
            .focusable(true)
            #endif

            HStack {
                VStack(spacing: 2) {
                    Text(StorageBreakdown.formatBytes(viewModel.breakdown.storeBytes))
                        .font(.system(.title3, design: .rounded).bold())
                    Text("Store")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 30)

                VStack(spacing: 2) {
                    Text(StorageBreakdown.formatBytes(viewModel.breakdown.attachmentBytes))
                        .font(.system(.title3, design: .rounded).bold())
                    Text("Attachments")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 30)

                VStack(spacing: 2) {
                    Text(StorageBreakdown.formatBytes(viewModel.breakdown.logsBytes))
                        .font(.system(.title3, design: .rounded).bold())
                    Text("Logs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            #if os(tvOS)
            .focusable(true)
            #endif
        } header: {
            Text("Overview")
        }
    }

    // MARK: - Storage Breakdown

    @ViewBuilder
    private var storageBreakdownSection: some View {
        Section {
            breakdownRow(
                label: "Store",
                bytes: viewModel.breakdown.storeBytes,
                icon: "cylinder"
            )
            breakdownRow(
                label: "Attachments",
                bytes: viewModel.breakdown.attachmentBytes,
                icon: "paperclip"
            )
            breakdownRow(
                label: "Logs",
                bytes: viewModel.breakdown.logsBytes,
                icon: "text.alignleft"
            )
            breakdownRow(
                label: "Replication",
                bytes: viewModel.breakdown.replicationBytes,
                icon: "arrow.triangle.2.circlepath"
            )
        } header: {
            Text("Storage Breakdown")
        } footer: {
            Text("Top-level categories from the Ditto data directory. See Glossary below for term definitions.")
        }
    }

    @ViewBuilder
    private func breakdownRow(label: String, bytes: Int, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(label)
            Spacer()
            Text(StorageBreakdown.formatBytes(bytes))
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        #if os(tvOS)
        .focusable(true)
        #endif
    }

    // MARK: - Donut Chart

    private var breakdownSlices: [DonutSlice] {
        [
            DonutSlice(label: "Store", bytes: viewModel.breakdown.storeBytes, color: .blue),
            DonutSlice(label: "Attachments", bytes: viewModel.breakdown.attachmentBytes, color: .pink),
            DonutSlice(label: "Logs", bytes: viewModel.breakdown.logsBytes, color: .green),
            DonutSlice(label: "Replication", bytes: viewModel.breakdown.replicationBytes, color: .orange),
        ]
    }

    @ViewBuilder
    private var donutChartSection: some View {
        Section {
            VStack(spacing: 12) {
                DonutChartView(slices: breakdownSlices, lineWidth: 20)
                    .frame(height: 160)
                    .padding(.top, 8)

                DonutLegendView(slices: breakdownSlices)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Storage Distribution")
        }
    }

    // MARK: - Health

    @ViewBuilder
    private var healthSection: some View {
        Section {
            HealthIndicatorView(
                currentBytes: viewModel.breakdown.totalOnDiskBytes,
                thresholdBytes: viewModel.unhealthySizeInBytes
            )

            HealthGaugeView(
                currentBytes: viewModel.breakdown.totalOnDiskBytes,
                thresholdBytes: viewModel.unhealthySizeInBytes
            )

            HStack {
                Text("Threshold")
                Spacer()
                Text(StorageBreakdown.formatBytes(viewModel.unhealthySizeInBytes))
                    .foregroundColor(.secondary)
                Stepper("", onIncrement: {
                    viewModel.unhealthySizeInBytes += 50_000_000 // +50 MB
                }, onDecrement: {
                    viewModel.unhealthySizeInBytes = max(50_000_000, viewModel.unhealthySizeInBytes - 50_000_000)
                })
                .labelsHidden()
                .frame(width: 100)
            }
        } header: {
            Text("Health Status")
        } footer: {
            Text("Adjust the threshold in 50 MB steps. The gauge and indicator update live.")
        }
    }

    // MARK: - Growth Rate

    @ViewBuilder
    private var growthRateSection: some View {
        Section {
            GrowthRateView(bytesPerSecond: viewModel.growthRatePerSecond)

            if viewModel.diskUsageHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Total Disk Size Over Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let latest = viewModel.diskUsageHistory.last {
                            Text(StorageBreakdown.formatBytes(latest))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    SparklineView(
                        dataPoints: viewModel.diskUsageHistory,
                        color: .blue
                    )
                }
            }
        } header: {
            Text("Disk Growth")
        } footer: {
            Text("Observed rate based on disk usage samples this session. May fluctuate with GC events or sync bursts.")
        }
    }

    // MARK: - Growth Prediction

    private var predictionColor: Color {
        guard let seconds = viewModel.estimatedSecondsToThreshold, seconds > 0 else { return .red }
        let hours = seconds / 3600
        if hours < 1 { return .red }
        if hours < 24 { return .orange }
        return .green
    }

    private var predictionIcon: String {
        guard let seconds = viewModel.estimatedSecondsToThreshold, seconds > 0 else {
            return "exclamationmark.triangle.fill"
        }
        let hours = seconds / 3600
        if hours < 1 { return "exclamationmark.triangle.fill" }
        if hours < 24 { return "exclamationmark.circle.fill" }
        return "clock.fill"
    }

    private func formatTimeInterval(_ seconds: Double) -> String {
        if seconds < 60 { return "< 1 min" }
        let minutes = seconds / 60
        if minutes < 60 { return String(format: "%.0f min", minutes) }
        let hours = minutes / 60
        if hours < 24 { return String(format: "%.1f hours", hours) }
        let days = hours / 24
        if days < 365 { return String(format: "%.1f days", days) }
        let years = days / 365
        return String(format: "%.1f years", years)
    }

    @ViewBuilder
    private var growthPredictionSection: some View {
        Section {
            if let seconds = viewModel.estimatedSecondsToThreshold {
                if seconds <= 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Threshold Exceeded")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("Disk usage has already surpassed the health threshold.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: predictionIcon)
                            .foregroundColor(predictionColor)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time to Threshold")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTimeInterval(seconds))
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundColor(predictionColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(StorageBreakdown.formatBytes(
                                max(0, viewModel.unhealthySizeInBytes - viewModel.breakdown.totalOnDiskBytes)
                            ))
                            .font(.system(.title3, design: .rounded).bold())
                        }
                    }
                    .padding(.vertical, 4)
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                }
            } else if viewModel.growthRatePerSecond == nil {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Text("Collecting data to estimate growth prediction…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                #if os(tvOS)
                .focusable(true)
                #endif
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stable or Shrinking")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Disk usage is not growing — no threshold concern.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                #if os(tvOS)
                .focusable(true)
                #endif
            }
        } header: {
            Text("Growth Prediction")
        } footer: {
            Text("Rough estimate based on the observed growth rate this session. One-off events (GC, bulk imports) may cause this to fluctuate.")
        }
    }

    // MARK: - Content vs Infrastructure
    //
    // Groups the four top-level categories from `diskUsagePublisher()` into a
    // coarse "user-facing content" vs "Ditto infrastructure" split. Uses only
    // top-level bytes — no file walk, no collection observer. Note that Store
    // contains both user documents and CRDT metadata, so this is directional.

    @ViewBuilder
    private var contentVsInfrastructureSection: some View {
        Section {
            StackedComparisonView(
                leftLabel: "Content",
                leftBytes: viewModel.breakdown.storeBytes + viewModel.breakdown.attachmentBytes,
                leftColor: .blue,
                rightLabel: "Infrastructure",
                rightBytes: viewModel.breakdown.logsBytes + viewModel.breakdown.replicationBytes,
                rightColor: .orange
            )
        } header: {
            Text("Content vs Infrastructure")
        } footer: {
            Text("Store + Attachments (documents and binaries) versus Logs + Replication (diagnostics and sync state). Note: Store also contains CRDT metadata, so the left side slightly overestimates user content.")
        }
    }

    // MARK: - Collection Scan (opt-in)

    @ViewBuilder
    private var collectionScanSection: some View {
        Section {
            Button {
                Task { await viewModel.scanCollections() }
            } label: {
                HStack {
                    if viewModel.isScanningCollections {
                        ProgressView()
                        Text("Scanning…")
                    } else {
                        Label("Scan Collections", systemImage: "magnifyingglass")
                    }
                }
            }
            .disabled(viewModel.isScanningCollections)

            if viewModel.collections.isEmpty {
                Text("Tap to discover collections and count documents. Runs a single COUNT(*) per collection — no subscriptions, no document payload loaded.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("Collection", selection: Binding(
                    get: { viewModel.selectedCollection },
                    set: { viewModel.selectCollection($0) }
                )) {
                    ForEach(viewModel.collections, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                #if os(iOS)
                .pickerStyle(.menu)
                #endif

                Button {
                    Task { await viewModel.sampleSelectedCollection() }
                } label: {
                    HStack {
                        if viewModel.isSamplingCollection {
                            ProgressView()
                            Text("Sampling…")
                        } else {
                            Label(
                                "Sample \(Self.truncateForButton(viewModel.selectedCollection)) (≤ \(DiskUsageInspectorViewModel.sampleLimit) docs)",
                                systemImage: "chart.bar.doc.horizontal"
                            )
                        }
                    }
                }
                .disabled(
                    viewModel.isSamplingCollection
                    || viewModel.isScanningCollections
                    || viewModel.selectedCollection.isEmpty
                )

                if let date = viewModel.lastCollectionScanDate {
                    HStack {
                        Text("Last Scan")
                            .font(.caption)
                        Spacer()
                        Text(DiskUsageInspectorViewModel.dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Collection Scan")
        } footer: {
            Text("All collection insights below are opt-in. Sampling is capped at \(DiskUsageInspectorViewModel.sampleLimit) documents per collection and uses one-shot queries — no live observers, no sync subscriptions.")
        }
    }

    // MARK: - Collection Ranking (count-based, from opt-in scan)

    @ViewBuilder
    private var collectionRankingSection: some View {
        Section {
            HorizontalBarChartView(
                items: viewModel.collections
                    .compactMap { name -> (label: String, bytes: Int)? in
                        guard let count = viewModel.collectionCounts[name] else { return nil }
                        return (label: name, bytes: count)
                    }
                    .sorted { $0.bytes > $1.bytes },
                barColor: .orange,
                valueFormatter: { count in
                    count == 1 ? "1 doc" : "\(count) docs"
                }
            )

            if !viewModel.collectionsWithFailedCount.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Count unavailable for \(viewModel.collectionsWithFailedCount.count) collection\(viewModel.collectionsWithFailedCount.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Collection Size Ranking (by document count)")
        } footer: {
            if viewModel.collections.count > 10 {
                Text("Showing top 10 of \(viewModel.collections.count) collections. Counts are from a COUNT(*) snapshot — re-run Scan Collections to refresh.")
            } else {
                Text("Counts are from a COUNT(*) snapshot — re-run Scan Collections to refresh.")
            }
        }
    }

    // MARK: - Collection Section Helpers

    /// Clips overly long collection names inside the sample button label so
    /// the row doesn't wrap awkwardly on iPhone widths.
    private static func truncateForButton(_ name: String, max: Int = 24) -> String {
        guard name.count > max else { return name }
        return name.prefix(max - 1) + "…"
    }

    /// Formats the "Sampled X of Y docs" row without fabricating a denominator
    /// when the authoritative count is unknown (e.g. the count query failed).
    private func sampledLabel(for sample: CollectionSample) -> String {
        if let total = viewModel.collectionCounts[sample.name] {
            if sample.wasTruncated {
                return "\(sample.sampledCount) of \(total) docs"
            }
            return "\(sample.sampledCount) docs (all)"
        }
        if sample.wasTruncated {
            return "\(sample.sampledCount) docs (collection larger)"
        }
        return "\(sample.sampledCount) docs"
    }

    // MARK: - Document Size Distribution (from opt-in sample)

    @ViewBuilder
    private var docSizeDistributionSection: some View {
        Section {
            if let sample = viewModel.collectionSamples[viewModel.selectedCollection] {
                HistogramView(
                    buckets: sample.buckets,
                    barColor: .orange
                )

                HStack {
                    Text("Sampled")
                        .font(.caption)
                    Spacer()
                    Text(sampledLabel(for: sample))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Sample Payload")
                        .font(.caption)
                    Spacer()
                    Text(StorageBreakdown.formatBytes(sample.sampleBytes))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Scanned At")
                        .font(.caption)
                    Spacer()
                    Text(DiskUsageInspectorViewModel.dateFormatter.string(from: sample.scannedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Tap “Sample …” above to build a size distribution for the selected collection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            if viewModel.selectedCollection.isEmpty {
                Text("Document Size Distribution")
            } else {
                Text("Document Sizes: \(viewModel.selectedCollection)")
            }
        } footer: {
            if let sample = viewModel.collectionSamples[viewModel.selectedCollection], sample.wasTruncated {
                Text("Sample truncated at \(DiskUsageInspectorViewModel.sampleLimit) docs. Distribution reflects the sampled subset — not the whole collection.")
            } else {
                Text("Size buckets across the sampled documents. Each doc is inspected once and released immediately.")
            }
        }
    }

    // MARK: - Attachments

    private var attachmentPercentText: String {
        let total = viewModel.breakdown.totalOnDiskBytes
        guard total > 0 else { return "0.0%" }
        let pct = Double(viewModel.breakdown.attachmentBytes) / Double(total) * 100.0
        return String(format: "%.1f%%", pct)
    }

    @ViewBuilder
    private var attachmentsSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Attachment Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(StorageBreakdown.formatBytes(viewModel.breakdown.attachmentBytes))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.pink)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("% of Total Disk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(attachmentPercentText)
                        .font(.system(.title3, design: .rounded).bold())
                }
            }
            .padding(.vertical, 4)
            #if os(tvOS)
            .focusable(true)
            #endif
        } header: {
            Text("Attachments")
        } footer: {
            Text("Binary files (images, PDFs, etc.) stored alongside your documents. Ditto automatically garbage-collects attachments that are no longer referenced by any document.")
        }
    }

    // MARK: - Attachment GC Tracking

    @ViewBuilder
    private var attachmentGCSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GC Events Detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.gcEventsDetected > 0 ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(viewModel.gcEventsDetected > 0 ? .green : .secondary)
                        Text("\(viewModel.gcEventsDetected)")
                            .font(.system(.title3, design: .rounded).bold())
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Space Reclaimed (est.)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(StorageBreakdown.formatBytes(viewModel.gcBytesReclaimed))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
            #if os(tvOS)
            .focusable(true)
            #endif

            if viewModel.attachmentBytesHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Attachment Size Over Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let latest = viewModel.attachmentBytesHistory.last {
                            Text(StorageBreakdown.formatBytes(latest))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    SparklineView(
                        dataPoints: viewModel.attachmentBytesHistory,
                        color: .green
                    )
                }
            } else {
                Text("GC tracking will appear after a few updates. Drops in the chart indicate cleanup.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // GC health indicator
            HStack {
                Text("GC Status")
                Spacer()
                gcStatusLabel
            }
            #if os(tvOS)
            .focusable(true)
            #endif

            // Last GC event timestamp
            if let gcDate = viewModel.lastGCEventDate {
                HStack {
                    Text("Last GC Event")
                    Spacer()
                    Text(DiskUsageInspectorViewModel.dateFormatter.string(from: gcDate))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Garbage Collection")
        } footer: {
            Text("Ditto automatically removes attachment data no longer referenced by any document. Drops in the chart indicate successful cleanup cycles.")
        }
    }

    private var gcStatusLabel: some View {
        let bytesHistory = viewModel.attachmentBytesHistory
        let recentGrowth = bytesHistory.suffix(5)
        let isGrowing = recentGrowth.count >= 5
            && zip(recentGrowth, recentGrowth.dropFirst()).allSatisfy { $0 < $1 }

        let icon: String
        let text: String
        let color: Color

        if viewModel.gcEventsDetected > 0 {
            icon = "checkmark.seal.fill"
            text = "Active"
            color = .green
        } else if isGrowing {
            icon = "arrow.up.circle.fill"
            text = "Growing"
            color = .orange
        } else if bytesHistory.count >= 3 {
            icon = "clock"
            text = "GC not run yet"
            color = .secondary
        } else {
            icon = "clock"
            text = "GC not run yet"
            color = .secondary
        }

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }

    // MARK: - Parse Validator

    @ViewBuilder
    private var parseValidatorSection: some View {
        if !viewModel.parseWarnings.isEmpty {
            Section {
                ForEach(viewModel.parseWarnings, id: \.self) { warning in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.caption)
                    }
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                }

                if let date = viewModel.lastParseDate {
                    HStack {
                        Text("Last Checked")
                            .font(.caption)
                        Spacer()
                        Text(DiskUsageInspectorViewModel.dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                }
            } header: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Parse Warnings")
                    Spacer()
                    Text("\(viewModel.parseWarnings.count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }
            } footer: {
                Text("The disk usage tree may be incomplete or inconsistent. These warnings can help diagnose issues with disk usage reporting accuracy.")
            }
        }
    }

    // MARK: - Glossary

    @ViewBuilder
    private var glossarySection: some View {
        Section {
            GlossaryRow(
                term: "Store",
                definition: "The main database directory (ditto_store). Contains document data, CRDT metadata, indexes, and internal state managed by the Ditto SDK."
            )
            GlossaryRow(
                term: "Attachments",
                definition: "Binary files (images, PDFs, etc.) linked to documents. Stored in a dedicated directory and automatically garbage-collected when no longer referenced."
            )
            GlossaryRow(
                term: "Logs",
                definition: "Diagnostic log files generated by the Ditto SDK, useful for troubleshooting sync or connectivity issues."
            )
            GlossaryRow(
                term: "Replication",
                definition: "Internal state used by Ditto to coordinate peer-to-peer sync, including mesh network metadata and transport bookkeeping."
            )
            GlossaryRow(
                term: "Garbage Collection",
                definition: "Ditto's automatic process for removing attachment data that is no longer referenced by any document. GC events are detected when attachment bytes decrease significantly between samples. Reported values are estimates — concurrent sync or writes may partially mask the true reclaimed amount."
            )
            GlossaryRow(
                term: "Growth Prediction",
                definition: "A rough estimate of when disk usage will reach the configured health threshold, based on the observed growth rate during this session. Sensitive to one-off events like GC runs or bulk imports — best used as a directional indicator."
            )
            GlossaryRow(
                term: "Parse Warnings",
                definition: "Diagnostic checks on the disk usage tree. Warnings appear if expected directories are missing or if size totals are inconsistent, which may indicate incomplete disk reporting."
            )
            GlossaryRow(
                term: "Content vs Infrastructure",
                definition: "A coarse split of top-level directory bytes: Store + Attachments (user-facing content) versus Logs + Replication (diagnostics and sync state). Directional only — Store also contains CRDT metadata."
            )
            GlossaryRow(
                term: "Collection Scan",
                definition: "An opt-in snapshot triggered by an explicit button. Discovers collections and runs a single COUNT(*) per collection. Uses one-shot queries only — never registers a subscription or observer, so it doesn't pull data from peers or keep documents resident."
            )
            GlossaryRow(
                term: "Collection Sample",
                definition: "An opt-in sample of up to \(DiskUsageInspectorViewModel.sampleLimit) documents from a single collection, used to build a size distribution. Documents are inspected once and released immediately. If the collection is larger than the cap, the histogram reflects the sampled subset only."
            )
        } header: {
            Text("Glossary")
        } footer: {
            Text("Definitions of technical terms used in this report.")
        }
    }

    // MARK: - File Listing

    @ViewBuilder
    private var fileListingSection: some View {
        Section {
            if let listing = viewModel.fileListing {
                ForEach(listing.children, id: \.self) { child in
                    HStack {
                        Text(child.relativePath)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 200, alignment: .leading)
                        Spacer()
                        Text(child.size)
                            .foregroundColor(.secondary)
                            .frame(minWidth: 100, alignment: .trailing)
                    }
                }
                #if os(tvOS)
                .focusable(true)
                #endif

                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                        .frame(minWidth: 200, alignment: .leading)
                    Spacer()
                    Text(listing.totalSize)
                        .fontWeight(.semibold)
                        .frame(minWidth: 100, alignment: .trailing)
                }
                #if os(tvOS)
                .focusable(true)
                #endif
            } else {
                Text(DittoDiskUsageConstants.noData)
            }
        } header: {
            Text("File Listing")
        } footer: {
            Text("Individual files and directories in the Ditto root.")
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {
        Section {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Updated at:")
                Spacer()
                Text(viewModel.fileListing?.lastUpdated ?? DiskUsageInspectorViewModel.dateFormatter.string(from: Date()))
                    .foregroundColor(.secondary)
            }
            #if os(tvOS)
            .focusable(true)
            #endif

            #if !os(tvOS)
            Button {
                presentExportDataAlert.toggle()
            } label: {
                Label("Export Data Directory", systemImage: "square.and.arrow.up")
            }
            .sheet(isPresented: $presentExportDataShare) {
                #if os(iOS)
                ExportData(ditto: viewModel.ditto)
                #endif
            }
            .alert(isPresented: $presentExportDataAlert) {
                Alert(
                    title: Text("Export Ditto Directory"),
                    message: Text("Compressing the data may take a while."),
                    primaryButton: .default(Text("Export")) {
                        #if os(iOS)
                        presentExportDataShare = true
                        #elseif os(macOS)
                        ExportData_macOS(ditto: viewModel.ditto).export()
                        #endif
                    },
                    secondaryButton: .cancel()
                )
            }
            #endif
        }
    }
}
