//
//  CollectionInspectionViewModel.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation
import SwiftUI
import DittoSwift

/// Owns the opt-in collection scan and sample state for the Inspector. Both
/// halves use one-shot `store.execute` DQL — no observers, no subscriptions.
@MainActor
public final class CollectionInspectionViewModel: ObservableObject {

    // MARK: - Scan state

    @Published public private(set) var discoveredCollections: [String] = []
    @Published public private(set) var collectionScanStates: [String: CollectionScanState] = [:]
    @Published public private(set) var selectedCollection: String?
    @Published public private(set) var isScanningCollections: Bool = false
    @Published public private(set) var hasScannedCollections: Bool = false
    @Published public private(set) var scanError: Error?

    // MARK: - Sample state

    @Published public private(set) var collectionSamples: [String: CollectionSample] = [:]
    @Published public private(set) var isSamplingCollection: Bool = false
    @Published public private(set) var sampleError: Error?

    /// Max documents per sample. Caps memory and keeps the query fast.
    public static let sampleLimit: Int = 1_000

    // MARK: - Derived state

    /// Last scanned document count for the currently selected collection.
    /// `nil` if no collection is selected or the count is still pending /
    /// failed.
    public var totalDocsForSelected: Int? {
        guard let name = selectedCollection,
              case let .counted(total) = collectionScanStates[name] else {
            return nil
        }
        return total
    }

    /// Cached sample for the currently selected collection, if any.
    public var sampleForSelected: CollectionSample? {
        guard let name = selectedCollection else { return nil }
        return collectionSamples[name]
    }

    // MARK: - Private

    private let scanner: CollectionScanning
    private let sampler: CollectionSampling
    private var scanTask: Task<Void, Never>?
    private var sampleTask: Task<Void, Never>?

    public convenience init(ditto: Ditto, now: @escaping () -> Date = Date.init) {
        self.init(
            scanner: CollectionScanner(ditto: ditto),
            sampler: CollectionSampler(ditto: ditto, now: now)
        )
    }

    /// Designated init. Internal so tests can swap in fakes without
    /// exposing the protocols in the public API.
    internal init(scanner: CollectionScanning, sampler: CollectionSampling) {
        self.scanner = scanner
        self.sampler = sampler
    }

    deinit {
        scanTask?.cancel()
        sampleTask?.cancel()
    }

    // MARK: - Public API

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

    /// Samples the currently selected collection. No-op if nothing is
    /// selected or a sample is already running.
    public func sampleSelectedCollection() {
        guard !isSamplingCollection, let name = selectedCollection else { return }
        // Set state synchronously so a rapid double-tap is rejected by the
        // guard above before a second task is scheduled.
        isSamplingCollection = true
        sampleError = nil
        sampleTask = Task { [weak self] in
            await self?.performSample(of: name)
        }
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
        // Drop cached samples for collections that aren't here anymore so
        // memory stays tidy across re-scans.
        let validNames = Set(names)
        collectionSamples = collectionSamples.filter { validNames.contains($0.key) }
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

    // MARK: - Sample implementation

    private func performSample(of collection: String) async {
        // `isSamplingCollection` and `sampleError` are already set
        // synchronously by ``sampleSelectedCollection()``.
        defer { isSamplingCollection = false }

        let sample: CollectionSample
        do {
            sample = try await sampler.sample(collection, limit: Self.sampleLimit)
        } catch {
            // Same cancellation rule as the scan path — silent on cancel.
            if Task.isCancelled { return }
            sampleError = error
            return
        }

        if Task.isCancelled { return }
        var next = collectionSamples
        next[collection] = sample
        collectionSamples = next
    }
}
