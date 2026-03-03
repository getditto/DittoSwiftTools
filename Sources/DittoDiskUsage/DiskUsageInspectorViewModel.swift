//
//  DiskUsageInspectorViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  A single view model that provides both the flat file listing (from the
//  existing DiskUsageViewModel) and the categorized storage breakdown (from
//  StorageBreakdownViewModel) using one shared diskUsagePublisher subscription.
//

import Foundation
import Combine
import DittoSwift
import DittoHealthMetrics

/// A bucket for the document size distribution histogram.
public struct DocSizeBucket: Identifiable {
    public let id: String
    /// User-friendly label (e.g. "< 1 KB").
    public let label: String
    /// Number of documents in this bucket.
    public var count: Int

    /// Empty set of default buckets.
    public static let emptyBuckets: [DocSizeBucket] = [
        DocSizeBucket(id: "tiny",   label: "< 1 KB",        count: 0),
        DocSizeBucket(id: "small",  label: "1 – 10 KB",     count: 0),
        DocSizeBucket(id: "medium", label: "10 – 100 KB",   count: 0),
        DocSizeBucket(id: "large",  label: "100 KB – 1 MB", count: 0),
        DocSizeBucket(id: "xlarge", label: "> 1 MB",        count: 0),
    ]
}

/// - Note: Individual methods are annotated `@MainActor` rather than the class
///   itself, because `registerObserver` callbacks arrive on a Ditto-internal queue
///   and need an explicit `Task { @MainActor in }` hop. Marking the whole class
///   `@MainActor` would conflict with strict concurrency checks on those captures.
public class DiskUsageInspectorViewModel: ObservableObject {

    // MARK: - Published State

    /// Flat file listing (same data the existing Disk Usage view shows).
    @Published var fileListing: DiskUsageState? = DiskUsageState.defaultState
    /// Categorized breakdown (payload, WAL/SHM, logs, metadata).
    @Published public var breakdown = StorageBreakdown()
    /// Available collections on this device.
    @Published public var collections: [String] = []
    /// Currently selected collection for doc count / payload sizing.
    @Published public var selectedCollection: String = ""
    /// Whether the initial collection load is in progress.
    @Published public var isLoading: Bool = true
    /// Rolling history of total on-disk bytes for the trend sparkline.
    @Published public var diskUsageHistory: [Int] = []
    /// Rolling history of document count for the selected collection.
    @Published public var docCountHistory: [Int] = []
    /// Per-collection payload sizes (collection name → bytes). Sorted by size descending.
    @Published public var collectionSizes: [(name: String, bytes: Int)] = []
    /// Total document count across all collections.
    @Published public var totalDocumentCount: Int = 0
    /// Total document payload bytes across all collections.
    ///
    /// Initially computed by `loadCollectionSizes()`. Kept fresh for the
    /// **selected** collection via incremental deltas from the store observer
    /// (see `rewireForCurrentCollection`). Other collections remain at their
    /// initial values until the next manual refresh.
    @Published public var totalPayloadBytes: Int = 0
    /// Document size distribution buckets for the selected collection.
    @Published public var docSizeBuckets: [DocSizeBucket] = DocSizeBucket.emptyBuckets
    /// Replication directory size in bytes.
    @Published public var replicationBytes: Int = 0
    /// Store directory size in bytes.
    @Published public var storeBytes: Int = 0
    /// Observed growth rate in bytes per second. `nil` until ≥ 3 samples.
    ///
    /// Computed as `(newest - oldest) / elapsed` across the sample window.
    /// This is sensitive to one-off events (GC drops, bulk imports, large
    /// sync batches) which can cause large swings. Treat as a rough
    /// session-level indicator, not a steady-state measurement.
    @Published public var growthRatePerSecond: Double? = nil
    /// Rolling history of attachment file count for GC tracking.
    @Published public var attachmentCountHistory: [Int] = []
    /// Number of detected garbage collection events (attachment count decreased between samples).
    ///
    /// - Important: This is a **heuristic**. If new attachments arrive between
    ///   samples and outnumber the deletions, the net count won't decrease and the
    ///   GC event goes undetected. Treat as a lower-bound estimate.
    @Published public var gcEventsDetected: Int = 0
    /// Cumulative **net** bytes reclaimed by detected GC events.
    ///
    /// Because we only observe snapshots of the attachment directory, concurrent
    /// additions between samples reduce the observed delta. This value represents
    /// the net decrease, not the gross bytes deleted by GC. Treat as a lower-bound.
    @Published public var gcBytesReclaimed: Int = 0
    /// Size of the main SQLite database file(s) under ditto_store in bytes.
    @Published public var dbSqlBytes: Int = 0
    /// Estimated seconds until disk usage reaches the health threshold.
    /// `nil` if growth rate is not positive or not yet computed.
    ///
    /// - Important: Based on linear extrapolation of `growthRatePerSecond`,
    ///   which is noisy. A GC event can make this jump to `nil` (rate goes
    ///   negative), and a bulk import can make it drop to near-zero. Best
    ///   used as a rough directional indicator, not a precise countdown.
    @Published public var estimatedSecondsToThreshold: Double? = nil
    /// Validation warnings from the most recent disk usage parse.
    @Published public var parseWarnings: [String] = []
    /// Date of the most recent successful disk usage parse.
    @Published public var lastParseDate: Date? = nil

    /// Maximum number of trend data points kept in memory.
    private let maxHistoryCount = 60
    /// Timestamps corresponding to each entry in `diskUsageHistory`.
    private var historyTimestamps: [Date] = []
    /// Previous attachment bytes for GC reclamation tracking.
    private var prevAttachmentBytes: Int = 0

    // MARK: - Internal

    let ditto: Ditto

    /// The single shared disk usage subscription.
    private var diskUsageCancellable: AnyCancellable?
    /// Collection store observer for doc count / payload.
    private var storeObserver: DittoStoreObserver?
    /// Sync subscription for the selected collection.
    private var subscription: DittoSyncSubscription?

    /// UserDefaults key for persisting the health threshold across sessions.
    private static let thresholdKey = "com.ditto.diskUsage.healthThresholdBytes"

    /// Health metric threshold in bytes. Persisted to UserDefaults so the
    /// user's choice survives app restarts.
    @Published public var unhealthySizeInBytes: Int {
        didSet {
            UserDefaults.standard.set(unhealthySizeInBytes, forKey: Self.thresholdKey)
        }
    }

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    // MARK: - Init

    /// - Parameters:
    ///   - ditto: A configured Ditto instance.
    ///   - healthThresholdBytes: The byte count above which disk usage is
    ///     considered unhealthy. Defaults to 500 MB.
    public init(ditto: Ditto, healthThresholdBytes: Int = 500_000_000) {
        self.ditto = ditto
        // Restore persisted threshold; fall back to the provided default.
        let stored = UserDefaults.standard.integer(forKey: Self.thresholdKey)
        self.unhealthySizeInBytes = stored > 0 ? stored : healthThresholdBytes
        startDiskUsageObservation()
        Task { @MainActor in
            await self.loadCollections()
            self.isLoading = false
        }
    }

    // MARK: - Single Disk Usage Subscription

    /// One publisher subscription that feeds both the flat listing and the
    /// categorized breakdown.
    private func startDiskUsageObservation() {
        diskUsageCancellable = ditto.diskUsage
            .diskUsagePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] diskUsageItem in
                guard let self else { return }
                Task { @MainActor in
                    self.updateFileListing(from: diskUsageItem)
                    self.updateBreakdown(from: diskUsageItem)
                }
            }
    }

    // MARK: - Flat File Listing (from existing DiskUsageViewModel logic)

    @MainActor
    private func updateFileListing(from diskUsageItem: DiskUsageItem) {
        let children = diskUsageItem.childItems
            .map { child in
                DiskUsage(
                    relativePath: child.path,
                    sizeInBytes: child.sizeInBytes,
                    size: Self.byteCountFormatter.string(for: child.sizeInBytes) ?? DittoDiskUsageConstants.error
                )
            }
            .sorted { $0.sizeInBytes > $1.sizeInBytes }

        fileListing = DiskUsageState(
            rootPath: diskUsageItem.path,
            totalSizeInBytes: diskUsageItem.sizeInBytes,
            totalSize: Self.byteCountFormatter.string(for: diskUsageItem.sizeInBytes) ?? DittoDiskUsageConstants.error,
            children: children,
            lastUpdated: Self.dateFormatter.string(from: Date()),
            unhealthySizeInBytes: unhealthySizeInBytes
        )
    }

    // MARK: - Categorized Breakdown (from StorageBreakdownViewModel logic)

    @MainActor
    private func updateBreakdown(from root: DiskUsageItem) {
        var logs = 0
        var walShm = 0
        var repl = 0
        var store = 0
        var attachBytes = 0
        var attachFileCount = 0
        var dbSql = 0

        func walk(_ item: DiskUsageItem) {
            let p = item.path.lowercased()
            if p.contains("/logs/") || p.hasSuffix(".log") {
                logs += item.sizeInBytes
            }
            if p.hasSuffix(".db-wal") || p.hasSuffix(".db-shm")
                || p.hasSuffix("-wal") || p.hasSuffix("-shm") {
                walShm += item.sizeInBytes
            }
            // Track main SQLite database files under ditto_store
            if p.contains(DittoDiskUsageConstants.dittoStorePath),
               (p.hasSuffix(".db") || p.hasSuffix("db.sql") || p.hasSuffix(".sqlite")),
               !p.hasSuffix(".db-wal"), !p.hasSuffix(".db-shm") {
                dbSql += item.sizeInBytes
            }
            for child in item.childItems { walk(child) }
        }
        walk(root)

        // Extract top-level replication, store, and attachment directory sizes
        for child in root.childItems {
            let shortPath = child.path.lowercased()
            if shortPath.hasSuffix(DittoDiskUsageConstants.dittoReplicationPath) {
                repl = child.sizeInBytes
            } else if shortPath.hasSuffix(DittoDiskUsageConstants.dittoStorePath) {
                store = child.sizeInBytes
            } else if shortPath.hasSuffix(DittoDiskUsageConstants.dittoAttachmentsPath) {
                attachBytes = child.sizeInBytes
                attachFileCount = Self.countLeafFiles(child)
            }
        }

        let total = root.sizeInBytes
        // Use total payload across ALL collections for accurate overhead estimation.
        // Falls back to selected-collection payload until loadCollectionSizes() completes.
        let payload = totalPayloadBytes > 0 ? totalPayloadBytes : breakdown.collectionPayloadBytes
        let meta = max(0, total - (payload + logs + walShm + attachBytes))

        breakdown.totalOnDiskBytes = total
        breakdown.logsBytes = logs
        breakdown.walShmBytes = walShm
        breakdown.metadataOverheadBytes = meta
        breakdown.attachmentBytes = attachBytes
        breakdown.attachmentFileCount = attachFileCount
        replicationBytes = repl
        storeBytes = store

        // Detect GC events: net attachment count or size decreased since last sample.
        //
        // Limitation: these are snapshot-based heuristics. If new attachments arrive
        // between two samples (e.g., via sync) during a GC window, the additions may
        // partially or fully mask the deletions:
        //   sample₁: 100 files / 200 MB
        //   GC deletes 10 files (50 MB), sync adds 3 files (20 MB)
        //   sample₂:  93 files / 170 MB  → detected, but reclaimed = 30 MB (not 50 MB)
        //
        // Therefore gcEventsDetected and gcBytesReclaimed are lower-bound estimates.
        // Without Ditto exposing a GC callback/event, snapshot diffing is the best
        // we can do from the public API.
        if let prevCount = attachmentCountHistory.last, attachFileCount < prevCount {
            gcEventsDetected += 1
        }
        if prevAttachmentBytes > 0 && attachBytes < prevAttachmentBytes {
            gcBytesReclaimed += (prevAttachmentBytes - attachBytes)
        }
        prevAttachmentBytes = attachBytes

        // Track history for sparklines
        appendToHistory(attachFileCount, array: &attachmentCountHistory)
        appendToHistory(total, array: &diskUsageHistory)

        let now = Date()
        historyTimestamps.append(now)
        if historyTimestamps.count > maxHistoryCount {
            historyTimestamps.removeFirst(historyTimestamps.count - maxHistoryCount)
        }

        // Compute growth rate from oldest to newest sample
        if diskUsageHistory.count >= 3,
           let firstTime = historyTimestamps.first,
           let lastTime = historyTimestamps.last,
           let firstBytes = diskUsageHistory.first,
           let lastBytes = diskUsageHistory.last {
            let elapsed = lastTime.timeIntervalSince(firstTime)
            if elapsed > 0 {
                growthRatePerSecond = Double(lastBytes - firstBytes) / elapsed
            }
        }

        // ── db.sql tracking ──
        dbSqlBytes = dbSql

        // ── Growth Prediction: time to threshold ──
        if let rate = growthRatePerSecond, rate > 0 {
            let remaining = Double(unhealthySizeInBytes - total)
            estimatedSecondsToThreshold = remaining > 0 ? remaining / rate : 0
        } else {
            estimatedSecondsToThreshold = nil
        }

        // ── Parse Validation ──
        var warnings: [String] = []
        let childPaths = root.childItems.map { $0.path.lowercased() }

        if !childPaths.contains(where: { $0.hasSuffix(DittoDiskUsageConstants.dittoStorePath) }) {
            warnings.append("Missing expected ditto_store directory")
        }
        if !childPaths.contains(where: { $0.hasSuffix(DittoDiskUsageConstants.dittoReplicationPath) }) {
            warnings.append("Missing expected ditto_replication directory")
        }

        let childSum = root.childItems.reduce(0) { $0 + $1.sizeInBytes }
        if childSum > 0 && total > 0 {
            let sizeRatio = Double(total) / Double(childSum)
            if sizeRatio < 0.5 || sizeRatio > 2.0 {
                warnings.append("Total size diverges from sum of children (ratio: \(String(format: "%.2f", sizeRatio))x)")
            }
        }

        if total == 0 && !root.childItems.isEmpty {
            warnings.append("Root reports 0 bytes but has \(root.childItems.count) child items")
        }

        parseWarnings = warnings
        lastParseDate = Date()
    }

    // MARK: - Collections

    @MainActor
    private func loadCollections() async {
        var names = Set<String>()

        // Approach 1: DQL system table (preferred).
        do {
            let result = try await ditto.store.execute(
                query: "SELECT * FROM system:collections"
            )
            for item in result.items {
                if let name = item.value["name"] as? String {
                    names.insert(name)
                }
            }
        } catch {
            print("[DittoDiskUsage] system:collections query failed: \(error)")
        }

        // Fallback: Legacy collections APIs (only if DQL returned nothing).
        if names.isEmpty {
            for name in ditto.store.collectionNames() {
                names.insert(name)
            }
            for col in ditto.store.collections().exec() {
                names.insert(col.name)
            }
        }

        print("[DittoDiskUsage] Discovered \(names.count) collections: \(names.sorted())")

        self.collections = names.sorted()
        if !collections.isEmpty && !collections.contains(selectedCollection) {
            selectedCollection = collections.first ?? ""
            await rewireForCurrentCollection()
        }
        await loadCollectionSizes()
    }

    /// Queries every collection for a rough payload size and produces a ranked list.
    ///
    /// - Warning: Performs `SELECT *` on each collection and JSON-serializes every
    ///   document to measure byte size. This can cause memory spikes and latency on
    ///   large deployments (many collections or thousands of documents). Consider
    ///   adding `LIMIT` or DQL aggregation if available in future SDK versions.
    @MainActor
    private func loadCollectionSizes() async {
        var sizes: [(name: String, bytes: Int)] = []
        var totalDocs = 0
        for name in collections {
            let escaped = name.replacingOccurrences(of: "`", with: "``")
            let dqlName = "`\(escaped)`"
            do {
                let result = try await ditto.store.execute(query: "SELECT * FROM \(dqlName)")
                totalDocs += result.items.count
                var totalPayload = 0
                for item in result.items {
                    if let data = try? JSONSerialization.data(withJSONObject: item.value, options: []) {
                        totalPayload += data.count
                    }
                }
                sizes.append((name: name, bytes: totalPayload))
            } catch {
                sizes.append((name: name, bytes: 0))
            }
        }
        collectionSizes = sizes.sorted { $0.bytes > $1.bytes }
        totalDocumentCount = totalDocs
        totalPayloadBytes = sizes.reduce(0) { $0 + $1.bytes }
    }

    @MainActor
    public func changeCollection(to name: String) {
        selectedCollection = name
        Task {
            await rewireForCurrentCollection()
        }
    }

    @MainActor
    public func refreshCollections() {
        Task {
            await loadCollections()
        }
    }

    // MARK: - Collection Observer

    @MainActor
    private func rewireForCurrentCollection() async {
        storeObserver?.cancel()
        storeObserver = nil
        subscription?.cancel()
        subscription = nil

        breakdown.documentCount = 0
        breakdown.collectionPayloadBytes = 0
        // Seed with 0 so the first observer callback (which delivers the full
        // dataset) immediately creates a 2-point sparkline (0 → actual count).
        docCountHistory = [0]
        docSizeBuckets = DocSizeBucket.emptyBuckets

        guard !selectedCollection.isEmpty else { return }

        let escaped = selectedCollection.replacingOccurrences(of: "`", with: "``")
        let dqlName = "`\(escaped)`"

        do {
            subscription = try ditto.sync.registerSubscription(
                query: "SELECT * FROM \(dqlName)"
            )

            // Note: The observer callback re-serializes all documents on every
            // change. For very large collections with frequent writes, this may
            // cause latency. A future optimization could use incremental updates.
            storeObserver = try ditto.store.registerObserver(
                query: "SELECT * FROM \(dqlName)"
            ) { [weak self] result in
                guard let self else { return }
                let docs = result.items
                var payloadBytes = 0
                var buckets = DocSizeBucket.emptyBuckets
                for item in docs {
                    if let data = try? JSONSerialization.data(withJSONObject: item.value, options: []) {
                        let size = data.count
                        payloadBytes += size
                        // Classify into buckets
                        switch size {
                        case ..<1_024:
                            buckets[0].count += 1
                        case 1_024..<10_240:
                            buckets[1].count += 1
                        case 10_240..<102_400:
                            buckets[2].count += 1
                        case 102_400..<1_048_576:
                            buckets[3].count += 1
                        default:
                            buckets[4].count += 1
                        }
                    }
                }
                Task { @MainActor in
                    // Incrementally keep totalPayloadBytes fresh for the
                    // selected collection so donut/bloat/overhead don't go stale.
                    let oldPayload = self.breakdown.collectionPayloadBytes
                    let delta = payloadBytes - oldPayload
                    self.totalPayloadBytes = max(0, self.totalPayloadBytes + delta)

                    // Keep the ranking chart entry for this collection current.
                    if let idx = self.collectionSizes.firstIndex(where: { $0.name == self.selectedCollection }) {
                        self.collectionSizes[idx] = (name: self.selectedCollection, bytes: payloadBytes)
                        self.collectionSizes.sort { $0.bytes > $1.bytes }
                    }

                    self.breakdown.documentCount = docs.count
                    self.breakdown.collectionPayloadBytes = payloadBytes
                    self.docSizeBuckets = buckets
                    // Record doc count trend
                    self.appendToHistory(docs.count, array: &self.docCountHistory)
                    // Lightweight metadata recalculation — avoids a full tree walk
                    // and synchronous ditto.diskUsage.exec call on the main thread.
                    self.recalculateMetadata()
                }
            }
        } catch {
            print("[DittoDiskUsage] Failed to observe collection \(selectedCollection): \(error)")
        }
    }

    /// Lightweight recalculation of metadata overhead after payload changes.
    /// Uses values from the last full `updateBreakdown` call to avoid re-walking
    /// the disk usage tree or calling `ditto.diskUsage.exec` on the main thread.
    @MainActor
    private func recalculateMetadata() {
        let payload = totalPayloadBytes > 0 ? totalPayloadBytes : breakdown.collectionPayloadBytes
        breakdown.metadataOverheadBytes = max(0,
            breakdown.totalOnDiskBytes - (payload + breakdown.logsBytes + breakdown.walShmBytes + breakdown.attachmentBytes))
    }

    // MARK: - Helpers

    /// Appends `value` to `array`, trimming the front if it exceeds `maxHistoryCount`.
    private func appendToHistory(_ value: Int, array: inout [Int]) {
        array.append(value)
        if array.count > maxHistoryCount {
            array.removeFirst(array.count - maxHistoryCount)
        }
    }

    /// Recursively counts leaf files (items with no children) under a directory.
    private static func countLeafFiles(_ item: DiskUsageItem) -> Int {
        if item.childItems.isEmpty {
            return item.sizeInBytes > 0 ? 1 : 0
        }
        return item.childItems.reduce(0) { $0 + countLeafFiles($1) }
    }

    // MARK: - Health Metrics

    deinit {
        diskUsageCancellable?.cancel()
        storeObserver?.cancel()
        subscription?.cancel()
    }
}

// MARK: - HealthMetricProvider

extension DiskUsageInspectorViewModel: HealthMetricProvider {
    public var metricName: String {
        DittoDiskUsageConstants.healthMetricName
    }

    public func getCurrentState() -> HealthMetric {
        fileListing?.healthMetric ??
        HealthMetric(
            isHealthy: true,
            details: [DittoDiskUsageConstants.healthMetricName: DittoDiskUsageConstants.noData]
        )
    }
}
