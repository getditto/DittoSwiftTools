//
//  CollectionSampler.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation
import DittoSwift

/// Samples a collection's documents and groups them by JSON byte size.
/// A protocol so tests can swap in a fake.
protocol CollectionSampling {
    func sample(_ collection: String, limit: Int) async throws -> CollectionSample
}

/// Runs the DQL query for the opt-in collection sample.
///
/// One-shot `store.execute` only — no observers, no subscriptions. Each
/// item is dematerialized right after its size is read, so memory stays
/// low even for large samples.
///
/// Thread-safe: no mutable state.
final class CollectionSampler: CollectionSampling {
    private let ditto: Ditto
    private let now: () -> Date

    init(ditto: Ditto, now: @escaping () -> Date = Date.init) {
        self.ditto = ditto
        self.now = now
    }

    /// Bucket upper bounds in bytes (exclusive). Powers of four give a
    /// log-scale view across the typical Ditto document range. Anything
    /// at or above the last bound goes in the overflow bucket.
    static let bucketUpperBounds: [Int] = [
        1024,
        4096,
        16384,
        65536,
        262144
    ]

    /// Labels for each bucket; one entry longer than ``bucketUpperBounds``
    /// to cover the overflow tier.
    static let bucketLabels: [(id: String, label: String)] = [
        ("under-1kb", "< 1 KB"),
        ("1-4kb", "1 – 4 KB"),
        ("4-16kb", "4 – 16 KB"),
        ("16-64kb", "16 – 64 KB"),
        ("64-256kb", "64 – 256 KB"),
        ("256kb-plus", "≥ 256 KB")
    ]

    func sample(_ collection: String, limit: Int) async throws -> CollectionSample {
        let escaped = DQLIdentifier.escape(collection)
        let result = try await ditto.store.execute(
            query: "SELECT * FROM \(escaped) LIMIT \(limit)"
        )

        var counts = [Int](repeating: 0, count: Self.bucketLabels.count)
        var sampled = 0

        for item in result.items {
            let bytes = item.jsonString().utf8.count
            counts[Self.bucketIndex(forSizeBytes: bytes)] += 1
            sampled += 1
            // Release the doc's data right after measuring so memory
            // doesn't grow with sample size.
            item.dematerialize()
        }

        let buckets = zip(Self.bucketLabels, counts).map { template, count in
            DocSizeBucket(id: template.id, label: template.label, count: count)
        }

        return CollectionSample(
            collectionName: collection,
            sampledCount: sampled,
            buckets: buckets,
            reachedLimit: sampled >= limit,
            sampledAt: now()
        )
    }

    /// Bucket index for a document size in bytes.
    static func bucketIndex(forSizeBytes size: Int) -> Int {
        for (index, upper) in bucketUpperBounds.enumerated() where size < upper {
            return index
        }
        return bucketUpperBounds.count
    }
}
