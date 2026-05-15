//
//  CollectionScanner.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation
import DittoSwift

/// The DQL operations the view model needs for the scan. A protocol so
/// tests can swap in a fake without a live `Ditto`.
protocol CollectionScanning {
    func discoverCollections() async throws -> [String]
    func fetchCount(for collection: String) async throws -> Int
}

/// Runs the DQL queries for the opt-in collection scan.
///
/// One-shot `store.execute` calls only — no observers, no subscriptions.
///
/// Thread-safe: no mutable state, so concurrent calls are fine.
final class CollectionScanner: CollectionScanning {
    private let ditto: Ditto

    init(ditto: Ditto) {
        self.ditto = ditto
    }

    /// Discovers collections via the documented `system:collections` query.
    func discoverCollections() async throws -> [String] {
        let result = try await ditto.store.execute(query: "SELECT * FROM system:collections")
        let names = result.items.compactMap { item -> String? in
            item.value["name"] as? String
        }
        return Array(Set(names)).sorted()
    }

    /// Returns the document count for a single collection.
    func fetchCount(for collection: String) async throws -> Int {
        let escaped = DQLIdentifier.escape(collection)
        let result = try await ditto.store.execute(
            query: "SELECT COUNT(*) AS total FROM \(escaped)"
        )
        guard let item = result.items.first else {
            throw DiskUsageScanError.emptyResult
        }
        // `item.value` is `[String: Any?]`: outer optional = "key present?",
        // inner = "value non-nil?". Require both.
        guard let entry = item.value["total"], let raw = entry else {
            throw DiskUsageScanError.unexpectedResultFormat
        }
        return try Self.intValue(raw)
    }

    /// DQL returns numbers as `Int`, `Int64`, `Double`, or a bridged
    /// `NSNumber` depending on the platform. Convert to `Int`.
    static func intValue(_ raw: Any) throws -> Int {
        switch raw {
        case let value as Int: return value
        case let value as Int64: return Int(value)
        case let value as Double: return Int(value)
        case let value as NSNumber: return value.intValue
        default: throw DiskUsageScanError.unexpectedResultFormat
        }
    }
}
