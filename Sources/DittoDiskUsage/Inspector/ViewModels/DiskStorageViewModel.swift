//
//  DiskStorageViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Combine
import Foundation
import SwiftUI
import DittoSwift

/// Defaults for ``DiskStorageViewModel``. Kept outside the `@MainActor`
/// class so default arguments can reference them.
public enum DiskStorageDefaults {
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
public final class DiskStorageViewModel: ObservableObject {

    // MARK: - Published state

    @Published public private(set) var breakdown: StorageBreakdown = .empty
    @Published public private(set) var hasReceivedFirstSnapshot: Bool = false

    // Implementation detail — exposed externally via the
    // ``historyTotalBytes`` computed view, not as raw `StorageBreakdown`s.
    @Published private var history: [StorageBreakdown] = []

    // MARK: - Configuration

    public let healthThresholdBytes: Int
    public let maxHistorySize: Int

    /// Below this many seconds of history, the growth rate window is too
    /// short to give a useful number.
    public static let growthRateMinElapsedSeconds: TimeInterval = 5

    /// How far back the growth rate averages over. Long enough to smooth
    /// out noise between snapshots, short enough to react to changes.
    public static let growthRateWindowSeconds: TimeInterval = 30

    // MARK: - Private

    private let ditto: Ditto
    private let now: () -> Date
    private let animation: Animation?
    private var cancellable: AnyCancellable?

    public init(
        ditto: Ditto,
        healthThresholdBytes: Int = DiskStorageDefaults.healthThresholdBytes,
        maxHistorySize: Int = DiskStorageDefaults.maxHistorySize,
        now: @escaping () -> Date = Date.init,
        animation: Animation? = DiskStorageDefaults.animation
    ) {
        self.ditto = ditto
        self.healthThresholdBytes = healthThresholdBytes
        self.maxHistorySize = max(2, maxHistorySize)
        self.now = now
        self.animation = animation
        subscribe()
    }

    deinit {
        cancellable?.cancel()
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

    /// Average byte growth per second over a rolling time window.
    /// `nil` until there's at least ``growthRateMinElapsedSeconds`` of data.
    /// Using a time window (instead of a sample count) keeps the rate
    /// useful even when snapshots arrive far apart — for example after
    /// the app comes back from a long time in the background.
    public var growthRatePerSecond: Double? {
        guard let last = history.last else { return nil }
        let cutoff = last.capturedAt.addingTimeInterval(-Self.growthRateWindowSeconds)
        // Pick the oldest sample still inside the window. If the most
        // recent samples are far apart (e.g. after backgrounding), the
        // window may contain just `last`, which we treat as "not enough
        // data yet" via the elapsed-time check below.
        guard let first = history.first(where: { $0.capturedAt >= cutoff }) else { return nil }
        let elapsed = last.capturedAt.timeIntervalSince(first.capturedAt)
        guard elapsed >= Self.growthRateMinElapsedSeconds else { return nil }
        return Double(last.totalOnDiskBytes - first.totalOnDiskBytes) / elapsed
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
}
