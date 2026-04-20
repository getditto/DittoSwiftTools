//
//  DiskUsageInspectorViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Uses only the public `diskUsagePublisher()` API — no internal file parsing.
//  Per-collection insights are strictly opt-in, capped, and use one-shot queries
//  (`store.execute`) — never `registerSubscription`, which would pull data from
//  peers and hold full docsets resident in memory.

import Foundation
import Combine
import DittoSwift
import DittoHealthMetrics

/// Errors produced by the opt-in collection scan. Surfaced via logs and
/// `collectionsWithFailedCount`; not thrown across public API boundaries.
enum DiskUsageScanError: Error {
    case emptyResult
    case unexpectedResultFormat
}

/// A snapshot of a single collection produced by an explicit, capped sample.
/// Never kept live via an observer — re-run via `sampleSelectedCollection()`.
public struct CollectionSample {
    public let name: String
    /// Document count in the sample (`<= sampleLimit`).
    public let sampledCount: Int
    /// Aggregate JSON byte size of sampled documents.
    public let sampleBytes: Int
    /// Size-bucket histogram over the sample.
    public let buckets: [DocSizeBucket]
    /// True when the collection has more docs than were sampled.
    public let wasTruncated: Bool
    public let scannedAt: Date
}

public class DiskUsageInspectorViewModel: ObservableObject {

    // MARK: - Published State

    @Published var fileListing: DiskUsageState? = DiskUsageState.defaultState
    @Published public var breakdown = StorageBreakdown()
    @Published public var diskUsageHistory: [Int] = []
    @Published public var attachmentBytesHistory: [Int] = []
    /// Noisy session-level indicator; sensitive to GC drops and bulk imports.
    @Published public var growthRatePerSecond: Double? = nil
    /// Lower-bound estimate — concurrent sync additions can mask GC deletions.
    @Published public var gcEventsDetected: Int = 0
    /// Timestamp of the most recent GC event detected.
    @Published public var lastGCEventDate: Date? = nil
    /// Lower-bound net bytes — concurrent additions reduce the observed delta.
    @Published public var gcBytesReclaimed: Int = 0
    /// Linear extrapolation of growthRatePerSecond; inherits its noise.
    @Published public var estimatedSecondsToThreshold: Double? = nil
    @Published public var parseWarnings: [String] = []
    @Published public var lastParseDate: Date? = nil

    // MARK: - Opt-in Collection Scan State

    @Published public var collections: [String] = []
    @Published public var selectedCollection: String = ""
    /// Populated by `scanCollections()`. Only collections whose `COUNT(*)` succeeded
    /// appear here — missing entries indicate a failed or not-yet-run count.
    @Published public var collectionCounts: [String: Int] = [:]
    /// Collections whose count query failed during the most recent scan.
    @Published public var collectionsWithFailedCount: [String] = []
    /// Populated by `sampleSelectedCollection()`. Keyed by collection name.
    @Published public var collectionSamples: [String: CollectionSample] = [:]
    @Published public var isScanningCollections: Bool = false
    @Published public var isSamplingCollection: Bool = false
    @Published public var lastCollectionScanDate: Date? = nil

    /// Hard cap for per-collection sampling. Full enumeration is never performed.
    public static let sampleLimit: Int = 1000

    private let maxHistoryCount = 60
    private var historyTimestamps: [Date] = []
    private var prevAttachmentBytes: Int = 0

    // MARK: - Internal

    let ditto: Ditto

    private var diskUsageCancellable: AnyCancellable?

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

    // MARK: - Flat File Listing

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

    // MARK: - Categorized Breakdown (top-level children only)

    @MainActor
    private func updateBreakdown(from root: DiskUsageItem) {
        var store = 0
        var attachBytes = 0
        var logs = 0
        var repl = 0

        for child in root.childItems {
            let p = child.path.lowercased()
            if p.hasSuffix(DittoDiskUsageConstants.dittoStorePath) {
                store = child.sizeInBytes
            } else if p.hasSuffix(DittoDiskUsageConstants.dittoAttachmentsPath) {
                attachBytes = child.sizeInBytes
            } else if p.hasSuffix(DittoDiskUsageConstants.dittoLogsPath) {
                logs = child.sizeInBytes
            } else if p.hasSuffix(DittoDiskUsageConstants.dittoReplicationPath) {
                repl = child.sizeInBytes
            }
        }

        let total = root.sizeInBytes

        breakdown.totalOnDiskBytes = total
        breakdown.storeBytes = store
        breakdown.attachmentBytes = attachBytes
        breakdown.logsBytes = logs
        breakdown.replicationBytes = repl

        // GC detection: byte-based — concurrent sync additions can mask deletions.
        // A significant attachment-bytes drop (>10 KB) indicates GC reclaimed space.
        let bytesDelta = prevAttachmentBytes - attachBytes
        if prevAttachmentBytes > 0 && bytesDelta > 10_240 {
            gcEventsDetected += 1
            gcBytesReclaimed += bytesDelta
            lastGCEventDate = Date()
        }
        prevAttachmentBytes = attachBytes

        appendToHistory(attachBytes, array: &attachmentBytesHistory)
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

    // MARK: - Opt-in Collection Scanning
    //
    // Both methods below use one-shot `store.execute` queries against the local
    // store. They do NOT register subscriptions or observers, so they don't
    // trigger sync traffic and don't keep documents resident in memory past
    // the call. Documents are dematerialized as soon as they're inspected.

    /// Discovers collection names via the public `system:collections` DQL
    /// surface and runs a cheap `COUNT(*)` against each. Triggered only by
    /// explicit user action ("Scan Collections" button).
    @MainActor
    public func scanCollections() async {
        guard !isScanningCollections else { return }
        isScanningCollections = true
        defer { isScanningCollections = false }

        let sortedNames: [String]
        do {
            sortedNames = try await fetchCollectionNames().sorted()
        } catch {
            print("[DittoDiskUsage] system:collections query failed: \(error)")
            return
        }

        var counts: [String: Int] = [:]
        var failed: [String] = []
        for name in sortedNames {
            do {
                counts[name] = try await fetchCount(for: name)
            } catch {
                failed.append(name)
                print("[DittoDiskUsage] count query failed for \(name): \(error)")
            }
        }

        self.collections = sortedNames
        self.collectionCounts = counts
        self.collectionsWithFailedCount = failed
        if !sortedNames.contains(selectedCollection) {
            self.selectedCollection = sortedNames.first ?? ""
        }
        self.lastCollectionScanDate = Date()
    }

    /// Samples up to `sampleLimit` documents from the currently selected
    /// collection and builds a size histogram. Opt-in — invoke explicitly.
    @MainActor
    public func sampleSelectedCollection() async {
        guard !isSamplingCollection else { return }
        let name = selectedCollection
        guard !name.isEmpty else { return }

        isSamplingCollection = true
        defer { isSamplingCollection = false }

        do {
            let sample = try await buildSample(for: name, limit: Self.sampleLimit)
            collectionSamples[name] = sample
        } catch {
            print("[DittoDiskUsage] sample query failed for \(name): \(error)")
        }
    }

    @MainActor
    public func selectCollection(_ name: String) {
        selectedCollection = name
    }

    // MARK: - Scan Helpers

    /// `system:collections` is the documented DQL virtual collection that
    /// enumerates user collections — preferred over any internal introspection.
    private func fetchCollectionNames() async throws -> Set<String> {
        let result = try await ditto.store.execute(
            query: "SELECT * FROM system:collections"
        )
        var names = Set<String>()
        for item in result.items {
            if let name = item.value["name"] as? String {
                names.insert(name)
            }
            item.dematerialize()
        }
        return names
    }

    private func fetchCount(for collection: String) async throws -> Int {
        let dqlName = Self.escapeIdentifier(collection)
        let result = try await ditto.store.execute(
            query: "SELECT COUNT(*) AS total FROM \(dqlName)"
        )
        defer { result.items.forEach { $0.dematerialize() } }
        guard let item = result.items.first else {
            throw DiskUsageScanError.emptyResult
        }
        if let n = item.value["total"] as? Int { return n }
        if let n = item.value["total"] as? Int64 { return Int(n) }
        if let n = item.value["total"] as? Double { return Int(n) }
        throw DiskUsageScanError.unexpectedResultFormat
    }

    private func buildSample(for collection: String, limit: Int) async throws -> CollectionSample {
        let dqlName = Self.escapeIdentifier(collection)
        var buckets: [DocSizeBucket] = Self.emptySizeBuckets()
        var totalBytes = 0
        var sampledCount = 0

        let result = try await ditto.store.execute(
            query: "SELECT * FROM \(dqlName) LIMIT \(limit)"
        )
        for item in result.items {
            let size = item.jsonData().count
            totalBytes += size
            let bucketIndex = Self.bucketIndex(forSize: size)
            buckets[bucketIndex].count += 1
            item.dematerialize()
            sampledCount += 1
        }

        let knownTotal = collectionCounts[collection]
        let wasTruncated: Bool
        if let knownTotal = knownTotal {
            wasTruncated = knownTotal > sampledCount
        } else {
            wasTruncated = sampledCount >= limit
        }

        return CollectionSample(
            name: collection,
            sampledCount: sampledCount,
            sampleBytes: totalBytes,
            buckets: buckets,
            wasTruncated: wasTruncated,
            scannedAt: Date()
        )
    }

    private static func escapeIdentifier(_ name: String) -> String {
        "`\(name.replacingOccurrences(of: "`", with: "``"))`"
    }

    private static func emptySizeBuckets() -> [DocSizeBucket] {
        [
            DocSizeBucket(id: "tiny",   label: "< 1 KB",        count: 0),
            DocSizeBucket(id: "small",  label: "1 – 10 KB",     count: 0),
            DocSizeBucket(id: "medium", label: "10 – 100 KB",   count: 0),
            DocSizeBucket(id: "large",  label: "100 KB – 1 MB", count: 0),
            DocSizeBucket(id: "xlarge", label: "> 1 MB",        count: 0),
        ]
    }

    private static func bucketIndex(forSize size: Int) -> Int {
        switch size {
        case ..<1_024:            return 0
        case 1_024..<10_240:      return 1
        case 10_240..<102_400:    return 2
        case 102_400..<1_048_576: return 3
        default:                  return 4
        }
    }

    // MARK: - History Helpers

    private func appendToHistory(_ value: Int, array: inout [Int]) {
        array.append(value)
        if array.count > maxHistoryCount {
            array.removeFirst(array.count - maxHistoryCount)
        }
    }

    // MARK: - Cleanup

    deinit {
        diskUsageCancellable?.cancel()
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
