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

/// Subscribes to the SDK's public `diskUsagePublisher()` and republishes each
/// emission as a ``StorageBreakdown``. Maintains a session-only in-memory
/// history buffer for the growth rate and sparkline trend. Registers no
/// observers or subscriptions on user collections.
@MainActor
public final class DiskUsageInspectorViewModel: ObservableObject {

    @Published public private(set) var breakdown: StorageBreakdown = .empty
    @Published public private(set) var hasReceivedFirstSnapshot: Bool = false

    // Implementation detail — exposed to external callers via the
    // ``historyTotalBytes`` computed view, not as raw `StorageBreakdown`s.
    @Published private var history: [StorageBreakdown] = []

    public let healthThresholdBytes: Int
    public let maxHistorySize: Int

    private let ditto: Ditto
    private let now: () -> Date
    private let animation: Animation?
    private var cancellable: AnyCancellable?

    public init(
        ditto: Ditto,
        // 500 MB default.
        healthThresholdBytes: Int = 500_000_000,
        // ~1 minute of trend at a typical publisher rate. FIFO trim.
        maxHistorySize: Int = 60,
        now: @escaping () -> Date = Date.init,
        animation: Animation? = .easeOut(duration: 0.5)
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

    /// Total on-disk byte counts across the rolling history window, oldest
    /// first. Suitable for sparkline rendering.
    public var historyTotalBytes: [Int] {
        history.map(\.totalOnDiskBytes)
    }

    /// Below this, the per-minute rate is too noisy to display.
    public static let growthRateMinSampleCount: Int = 5

    /// Ensures the window covers real time, not just a burst of samples.
    public static let growthRateMinElapsedSeconds: TimeInterval = 5

    /// Average byte growth per second; `nil` until the window has enough
    /// samples and elapsed time to extrapolate meaningfully.
    public var growthRatePerSecond: Double? {
        guard history.count >= Self.growthRateMinSampleCount,
              let first = history.first,
              let last = history.last else { return nil }
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
