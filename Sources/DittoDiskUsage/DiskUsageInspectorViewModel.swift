//
//  DiskUsageInspectorViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//

import Foundation
import Combine
import DittoSwift
import DittoHealthMetrics

public struct DocSizeBucket: Identifiable {
    public let id: String
    public let label: String
    public var count: Int

    public static let emptyBuckets: [DocSizeBucket] = [
        DocSizeBucket(id: "tiny",   label: "< 1 KB",        count: 0),
        DocSizeBucket(id: "small",  label: "1 – 10 KB",     count: 0),
        DocSizeBucket(id: "medium", label: "10 – 100 KB",   count: 0),
        DocSizeBucket(id: "large",  label: "100 KB – 1 MB", count: 0),
        DocSizeBucket(id: "xlarge", label: "> 1 MB",        count: 0),
    ]
}

public class DiskUsageInspectorViewModel: ObservableObject {

    // MARK: - Published State

    @Published var fileListing: DiskUsageState? = DiskUsageState.defaultState
    @Published public var breakdown = StorageBreakdown()
    @Published public var collections: [String] = []
    @Published public var selectedCollection: String = ""
    @Published public var isLoading: Bool = true
    @Published public var diskUsageHistory: [Int] = []
    @Published public var docCountHistory: [Int] = []
    @Published public var collectionSizes: [(name: String, bytes: Int)] = []
    @Published public var totalDocumentCount: Int = 0
    /// Kept fresh for the selected collection via incremental deltas; others update on manual refresh.
    @Published public var totalPayloadBytes: Int = 0
    @Published public var docSizeBuckets: [DocSizeBucket] = DocSizeBucket.emptyBuckets
    @Published public var replicationBytes: Int = 0
    @Published public var storeBytes: Int = 0
    /// Noisy session-level indicator; sensitive to GC drops and bulk imports.
    @Published public var growthRatePerSecond: Double? = nil
    @Published public var attachmentCountHistory: [Int] = []
    /// Lower-bound estimate — concurrent sync additions can mask GC deletions.
    @Published public var gcEventsDetected: Int = 0
    /// Lower-bound net bytes — concurrent additions reduce the observed delta.
    @Published public var gcBytesReclaimed: Int = 0
    @Published public var dbSqlBytes: Int = 0
    /// Linear extrapolation of growthRatePerSecond; inherits its noise.
    @Published public var estimatedSecondsToThreshold: Double? = nil
    @Published public var parseWarnings: [String] = []
    @Published public var lastParseDate: Date? = nil

    private let maxHistoryCount = 60
    private var historyTimestamps: [Date] = []
    private var prevAttachmentBytes: Int = 0

    // MARK: - Internal

    let ditto: Ditto

    private var diskUsageCancellable: AnyCancellable?
    private var storeObserver: DittoStoreObserver?
    private var subscription: DittoSyncSubscription?

    private static let thresholdKey = "com.ditto.diskUsage.healthThresholdBytes"

    /// Persisted to UserDefaults.
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

    public init(ditto: Ditto, healthThresholdBytes: Int = 500_000_000) {
        self.ditto = ditto
        let stored = UserDefaults.standard.integer(forKey: Self.thresholdKey)
        self.unhealthySizeInBytes = stored > 0 ? stored : healthThresholdBytes
        startDiskUsageObservation()
        Task { @MainActor in
            await self.loadCollections()
            self.isLoading = false
        }
    }

    // MARK: - Disk Usage Subscription

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

    // MARK: - Categorized Breakdown

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
            if p.contains(DittoDiskUsageConstants.dittoStorePath),
               (p.hasSuffix(".db") || p.hasSuffix("db.sql") || p.hasSuffix(".sqlite")),
               !p.hasSuffix(".db-wal"), !p.hasSuffix(".db-shm") {
                dbSql += item.sizeInBytes
            }
            for child in item.childItems { walk(child) }
        }
        walk(root)

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

        // GC detection: snapshot-based — concurrent sync additions can mask deletions.
        if let prevCount = attachmentCountHistory.last, attachFileCount < prevCount {
            gcEventsDetected += 1
        }
        if prevAttachmentBytes > 0 && attachBytes < prevAttachmentBytes {
            gcBytesReclaimed += (prevAttachmentBytes - attachBytes)
        }
        prevAttachmentBytes = attachBytes

        appendToHistory(attachFileCount, array: &attachmentCountHistory)
        appendToHistory(total, array: &diskUsageHistory)

        let now = Date()
        historyTimestamps.append(now)
        if historyTimestamps.count > maxHistoryCount {
            historyTimestamps.removeFirst(historyTimestamps.count - maxHistoryCount)
        }

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

        dbSqlBytes = dbSql

        if let rate = growthRatePerSecond, rate > 0 {
            let remaining = Double(unhealthySizeInBytes - total)
            estimatedSecondsToThreshold = remaining > 0 ? remaining / rate : 0
        } else {
            estimatedSecondsToThreshold = nil
        }

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
        docCountHistory = [0]
        docSizeBuckets = DocSizeBucket.emptyBuckets

        guard !selectedCollection.isEmpty else { return }

        let escaped = selectedCollection.replacingOccurrences(of: "`", with: "``")
        let dqlName = "`\(escaped)`"

        do {
            subscription = try ditto.sync.registerSubscription(
                query: "SELECT * FROM \(dqlName)"
            )

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
                    let oldPayload = self.breakdown.collectionPayloadBytes
                    let delta = payloadBytes - oldPayload
                    self.totalPayloadBytes = max(0, self.totalPayloadBytes + delta)

                    if let idx = self.collectionSizes.firstIndex(where: { $0.name == self.selectedCollection }) {
                        self.collectionSizes[idx] = (name: self.selectedCollection, bytes: payloadBytes)
                        self.collectionSizes.sort { $0.bytes > $1.bytes }
                    }

                    self.breakdown.documentCount = docs.count
                    self.breakdown.collectionPayloadBytes = payloadBytes
                    self.docSizeBuckets = buckets
                    self.appendToHistory(docs.count, array: &self.docCountHistory)
                    self.recalculateMetadata()
                }
            }
        } catch {
            print("[DittoDiskUsage] Failed to observe collection \(selectedCollection): \(error)")
        }
    }

    @MainActor
    private func recalculateMetadata() {
        let payload = totalPayloadBytes > 0 ? totalPayloadBytes : breakdown.collectionPayloadBytes
        breakdown.metadataOverheadBytes = max(0,
            breakdown.totalOnDiskBytes - (payload + breakdown.logsBytes + breakdown.walShmBytes + breakdown.attachmentBytes))
    }

    // MARK: - Helpers

    private func appendToHistory(_ value: Int, array: inout [Int]) {
        array.append(value)
        if array.count > maxHistoryCount {
            array.removeFirst(array.count - maxHistoryCount)
        }
    }

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
