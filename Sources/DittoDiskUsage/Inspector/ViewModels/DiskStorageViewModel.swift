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
    @Published public private(set) var healthThresholdBytes: Int

    // Implementation detail — exposed externally via the
    // ``historyTotalBytes`` computed view, not as raw `StorageBreakdown`s.
    @Published private var history: [StorageBreakdown] = []

    // MARK: - Configuration

    public let maxHistorySize: Int

    /// Below this many seconds of history, the growth rate window is too
    /// short to give a useful number.
    public static let growthRateMinElapsedSeconds: TimeInterval = 5

    /// How far back the growth rate averages over. Long enough to smooth
    /// out noise between snapshots, short enough to react to changes.
    public static let growthRateWindowSeconds: TimeInterval = 30

    /// Step size when the user nudges the health threshold up or down.
    public static let thresholdStepBytes: Int = 50_000_000

    /// Smallest threshold a caller can set via ``adjustHealthThreshold(by:)``.
    public static let minimumThresholdBytes: Int = 50_000_000

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
        // Same floor as ``adjustHealthThreshold(by:)`` so callers can't sneak
        // an unusable threshold past the init.
        self.healthThresholdBytes = max(Self.minimumThresholdBytes, healthThresholdBytes)
        self.maxHistorySize = max(2, maxHistorySize)
        self.now = now
        self.animation = animation
        subscribe()
    }

    deinit {
        cancellable?.cancel()
    }

    // MARK: - Public API

    /// Increases or decreases the health threshold by `delta` bytes,
    /// clamping at ``minimumThresholdBytes``.
    public func adjustHealthThreshold(by delta: Int) {
        healthThresholdBytes = max(Self.minimumThresholdBytes, healthThresholdBytes + delta)
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

    /// Estimated seconds until the current usage hits ``healthThresholdBytes``,
    /// using the current ``growthRatePerSecond``. Returns `0` if already over
    /// the threshold and `nil` if the rate isn't known or usage is shrinking.
    public var estimatedSecondsToThreshold: Double? {
        let remaining = healthThresholdBytes - breakdown.totalOnDiskBytes
        guard let rate = growthRatePerSecond, rate > 0 else { return nil }
        guard remaining > 0 else { return 0 }
        return Double(remaining) / rate
    }

    /// Fill ratio of `currentBytes` against the threshold, clamped to `[0, 1]`.
    public var fillRatio: Double {
        guard healthThresholdBytes > 0 else { return 0 }
        let ratio = Double(breakdown.totalOnDiskBytes) / Double(healthThresholdBytes)
        return min(max(ratio, 0), 1)
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

        // `hasReceivedFirstSnapshot` flips inside the animation block so the
        // placeholder → content transition (counter, badge, gauge appearing)
        // fades with the same easeOut as the byte count itself.
        if let animation {
            withAnimation(animation) {
                breakdown = next
                history = nextHistory
                hasReceivedFirstSnapshot = true
            }
        } else {
            breakdown = next
            history = nextHistory
            hasReceivedFirstSnapshot = true
        }
    }
}
