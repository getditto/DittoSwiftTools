//
//  DiskUsageInspectorViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Combine
import Foundation
import SwiftUI
import DittoSwift

/// Defaults for ``DiskUsageInspectorViewModel``. Lifted out of the
/// `@MainActor` class so default arguments can reference them.
public enum DiskUsageInspectorDefaults {
    /// 500 MB default health threshold.
    public static let healthThresholdBytes: Int = 500_000_000

    /// ~1 minute of trend at a typical publisher rate. FIFO trim.
    public static let maxHistorySize: Int = 60

    /// Default animation applied to breakdown updates.
    public static let animation: Animation = .easeOut(duration: 0.5)
}

/// Subscribes to the SDK's public `diskUsagePublisher()` and republishes each
/// emission as a ``StorageBreakdown``. Maintains a session-only in-memory
/// history buffer for the growth rate and sparkline trend. Registers no
/// observers or subscriptions on user collections.
@MainActor
public final class DiskUsageInspectorViewModel: ObservableObject {

    // MARK: - Published state

    @Published public private(set) var breakdown: StorageBreakdown = .empty
    @Published public private(set) var hasReceivedFirstSnapshot: Bool = false

    // Implementation detail — exposed to external callers via the
    // ``historyTotalBytes`` computed view, not as raw `StorageBreakdown`s.
    @Published private var history: [StorageBreakdown] = []

    // MARK: - Collection scan state

    @Published public private(set) var discoveredCollections: [String] = []
    @Published public private(set) var collectionScanStates: [String: CollectionScanState] = [:]
    @Published public private(set) var selectedCollection: String?
    @Published public private(set) var isScanningCollections: Bool = false
    @Published public private(set) var hasScannedCollections: Bool = false
    @Published public private(set) var scanError: Error?

    // MARK: - Configuration

    public let healthThresholdBytes: Int
    public let maxHistorySize: Int

    /// Below this, the per-minute rate is too noisy to display.
    public static let growthRateMinSampleCount: Int = 5

    /// Ensures the window covers real time, not just a burst of samples.
    public static let growthRateMinElapsedSeconds: TimeInterval = 5

    // MARK: - Private

    private let ditto: Ditto
    private let now: () -> Date
    private let animation: Animation?
    private let scanner: CollectionScanning
    private var cancellable: AnyCancellable?
    private var scanTask: Task<Void, Never>?

    public convenience init(
        ditto: Ditto,
        healthThresholdBytes: Int = DiskUsageInspectorDefaults.healthThresholdBytes,
        maxHistorySize: Int = DiskUsageInspectorDefaults.maxHistorySize,
        now: @escaping () -> Date = Date.init,
        animation: Animation? = DiskUsageInspectorDefaults.animation
    ) {
        self.init(
            ditto: ditto,
            scanner: CollectionScanner(ditto: ditto),
            healthThresholdBytes: healthThresholdBytes,
            maxHistorySize: maxHistorySize,
            now: now,
            animation: animation
        )
    }

    /// Designated init. Internal so tests can swap in a fake scanner
    /// without exposing the protocol in the public API.
    internal init(
        ditto: Ditto,
        scanner: CollectionScanning,
        healthThresholdBytes: Int = DiskUsageInspectorDefaults.healthThresholdBytes,
        maxHistorySize: Int = DiskUsageInspectorDefaults.maxHistorySize,
        now: @escaping () -> Date = Date.init,
        animation: Animation? = DiskUsageInspectorDefaults.animation
    ) {
        self.ditto = ditto
        self.scanner = scanner
        self.healthThresholdBytes = healthThresholdBytes
        self.maxHistorySize = max(2, maxHistorySize)
        self.now = now
        self.animation = animation
        subscribe()
    }

    deinit {
        cancellable?.cancel()
        scanTask?.cancel()
    }

    // MARK: - Derived state

    public var healthStatus: HealthStatus {
        HealthStatus(
            currentBytes: breakdown.totalOnDiskBytes,
            thresholdBytes: healthThresholdBytes
        )
    }

    /// Total on-disk bytes across the rolling window, oldest first.
    public var historyTotalBytes: [Int] {
        history.map(\.totalOnDiskBytes)
    }

    /// Average byte growth per second; `nil` until there are enough
    /// samples and enough elapsed time.
    public var growthRatePerSecond: Double? {
        guard history.count >= Self.growthRateMinSampleCount,
              let first = history.first,
              let last = history.last else { return nil }
        let elapsed = last.capturedAt.timeIntervalSince(first.capturedAt)
        guard elapsed >= Self.growthRateMinElapsedSeconds else { return nil }
        return Double(last.totalOnDiskBytes - first.totalOnDiskBytes) / elapsed
    }

    // MARK: - Collection scan API

    /// Kicks off a fresh discovery + count scan. A no-op if one is already
    /// running.
    public func scanCollections() {
        guard !isScanningCollections else { return }
        // Set state synchronously so a rapid double-tap is rejected by the
        // guard above before a second task is scheduled.
        isScanningCollections = true
        scanError = nil
        scanTask = Task { [weak self] in
            await self?.performScan()
        }
    }

    /// Updates the selected collection. Unknown names are ignored — defends
    /// against stale UI bindings.
    public func selectCollection(_ name: String) {
        guard discoveredCollections.contains(name) else { return }
        selectedCollection = name
    }

    // MARK: - Subscription

    private func subscribe() {
        cancellable = ditto.diskUsage
            .diskUsagePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.apply(item)
            }
    }

    private func apply(_ item: DiskUsageItem) {
        let next = StorageBreakdown(item: item, capturedAt: now())
        var nextHistory = history
        nextHistory.append(next)
        if nextHistory.count > maxHistorySize {
            nextHistory.removeFirst(nextHistory.count - maxHistorySize)
        }

        if let animation {
            withAnimation(animation) {
                breakdown = next
                history = nextHistory
            }
        } else {
            breakdown = next
            history = nextHistory
        }
        hasReceivedFirstSnapshot = true
    }

    // MARK: - Scan implementation

    private func performScan() async {
        // `isScanningCollections` and `scanError` are already set
        // synchronously by ``scanCollections()``.
        defer { isScanningCollections = false }

        let names: [String]
        do {
            names = try await scanner.discoverCollections()
        } catch {
            // Cancellation can show up as `CancellationError` or as a
            // generic error once `Task.isCancelled` is true. Treat both
            // as silent — don't surface as a user-visible error.
            if Task.isCancelled { return }
            scanError = error
            hasScannedCollections = true
            return
        }

        guard !Task.isCancelled else { return }

        discoveredCollections = names
        var initialStates: [String: CollectionScanState] = [:]
        for name in names { initialStates[name] = .pending }
        collectionScanStates = initialStates
        if !names.contains(selectedCollection ?? "") {
            selectedCollection = names.first
        }
        // Discovery succeeded — surface the rows even if counts are still
        // in flight or the user cancels mid-loop.
        hasScannedCollections = true

        // Fetch counts in parallel. Each task returns `nil` on failure, so
        // a cancelled task isn't mis-marked as `.failed`.
        await withTaskGroup(of: (String, Int?).self) { group in
            for name in names {
                group.addTask { [scanner] in
                    do {
                        return (name, try await scanner.fetchCount(for: name))
                    } catch {
                        return (name, nil)
                    }
                }
            }
            for await (name, count) in group {
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }
                if let count {
                    collectionScanStates[name] = .counted(count)
                } else {
                    collectionScanStates[name] = .failed
                }
            }
        }
    }
}
