//
//  StorageBreakdown.swift
//  DittoSwiftTools/DittoDiskUsage
//

import Foundation
import DittoSwift
import Combine

public struct StorageBreakdown: Equatable {
    public var collectionPayloadBytes: Int = 0
    public var walShmBytes: Int = 0
    public var logsBytes: Int = 0
    public var metadataOverheadBytes: Int = 0
    public var totalOnDiskBytes: Int = 0
    public var documentCount: Int = 0
    public var attachmentBytes: Int = 0
    public var attachmentFileCount: Int = 0
}

extension StorageBreakdown {
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    public static func formatBytes(_ bytes: Int) -> String {
        byteCountFormatter.string(for: bytes) ?? "\(bytes) bytes"
    }
}

public class StorageBreakdownViewModel: ObservableObject {

    @Published public var breakdown = StorageBreakdown()
    @Published public var collections: [String] = []
    @Published public var selectedCollection: String = ""
    @Published public var isLoading: Bool = true

    private let ditto: Ditto
    private var diskUsageCancellable: AnyCancellable?
    private var storeObserver: DittoStoreObserver?
    private var subscription: DittoSyncSubscription?

    public init(ditto: Ditto) {
        self.ditto = ditto
        startDiskUsageObservation()
        Task { @MainActor in
            await self.loadCollections()
            self.isLoading = false
        }
    }

    // MARK: - Collections

    @MainActor
    private func loadCollections() async {
        var names: [String] = []

        do {
            let result = try await ditto.store.execute(
                query: "SELECT * FROM system:collections"
            )
            for item in result.items {
                if let name = item.value["name"] as? String {
                    names.append(name)
                }
            }
        } catch {
            print("[DittoDiskUsage] system:collections query failed: \(error)")
        }

        if names.isEmpty {
            let legacyCollections = ditto.store.collectionNames()
            names = legacyCollections
        }

        self.collections = names.sorted()
        if !self.collections.isEmpty && !self.collections.contains(self.selectedCollection) {
            self.selectedCollection = self.collections.first ?? ""
            await rewireForCurrentCollection()
        }
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

    // MARK: - Store Observer

    @MainActor
    private func rewireForCurrentCollection() async {
        storeObserver?.cancel()
        storeObserver = nil
        subscription?.cancel()
        subscription = nil

        breakdown.documentCount = 0
        breakdown.collectionPayloadBytes = 0

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
                for item in docs {
                    if let data = try? JSONSerialization.data(withJSONObject: item.value, options: []) {
                        payloadBytes += data.count
                    }
                }
                Task { @MainActor in
                    self.breakdown.documentCount = docs.count
                    self.breakdown.collectionPayloadBytes = payloadBytes
                    self.recomputeBreakdown()
                }
            }
        } catch {
            print("[DittoDiskUsage] Failed to observe collection \(selectedCollection): \(error)")
        }
    }

    // MARK: - Disk Usage Observation

    private func startDiskUsageObservation() {
        diskUsageCancellable = ditto.diskUsage
            .diskUsagePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let self else { return }
                Task { @MainActor in
                    self.breakdown.totalOnDiskBytes = item.sizeInBytes
                    self.recomputeBreakdown()
                }
            }
    }

    @MainActor
    private func recomputeBreakdown() {
        let root = ditto.diskUsage.exec

        var logs = 0
        var walShm = 0

        func walk(_ item: DiskUsageItem) {
            let p = item.path.lowercased()
            if p.contains("/logs/") || p.hasSuffix(".log") {
                logs += item.sizeInBytes
            }
            if p.hasSuffix(".db-wal") || p.hasSuffix(".db-shm")
                || p.hasSuffix("-wal") || p.hasSuffix("-shm") {
                walShm += item.sizeInBytes
            }
            for child in item.childItems { walk(child) }
        }
        walk(root)

        let total = root.sizeInBytes
        let payload = breakdown.collectionPayloadBytes
        let meta = max(0, total - (payload + logs + walShm))

        breakdown.totalOnDiskBytes = total
        breakdown.logsBytes = logs
        breakdown.walShmBytes = walShm
        breakdown.metadataOverheadBytes = meta
    }

    deinit {
        diskUsageCancellable?.cancel()
        storeObserver?.cancel()
        subscription?.cancel()
    }
}
