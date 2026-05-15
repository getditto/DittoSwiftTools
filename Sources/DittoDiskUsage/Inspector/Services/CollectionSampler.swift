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
    /// One row in the bucket definition table — paired upper bound (in
    /// bytes) and the label shown in the histogram. The last entry has
    /// no upper bound and catches everything large.
    struct BucketTemplate {
        let id: String
        let label: String
        let upperBoundBytes: Int?
    }

    private let ditto: Ditto
    private let now: () -> Date

    init(ditto: Ditto, now: @escaping () -> Date = Date.init) {
        self.ditto = ditto
        self.now = now
    }

    /// Bucket definitions in order, smallest first. Powers of four spread
    /// the buckets across the typical Ditto document range; the final
    /// bucket has no upper bound and catches everything ≥ 256 KB.
    static let bucketTemplates: [BucketTemplate] = [
        BucketTemplate(id: "under-1kb", label: "< 1 KB", upperBoundBytes: 1024),
        BucketTemplate(id: "1-4kb", label: "1 – 4 KB", upperBoundBytes: 4096),
        BucketTemplate(id: "4-16kb", label: "4 – 16 KB", upperBoundBytes: 16384),
        BucketTemplate(id: "16-64kb", label: "16 – 64 KB", upperBoundBytes: 65536),
        BucketTemplate(id: "64-256kb", label: "64 – 256 KB", upperBoundBytes: 262144),
        BucketTemplate(id: "256kb-plus", label: "≥ 256 KB", upperBoundBytes: nil)
    ]

    func sample(_ collection: String, limit: Int) async throws -> CollectionSample {
        let escaped = DQLIdentifier.escape(collection)
        let result = try await ditto.store.execute(
            query: "SELECT * FROM \(escaped) LIMIT \(limit)"
        )

        var counts = [Int](repeating: 0, count: Self.bucketTemplates.count)
        var sampled = 0

        for item in result.items {
            let bytes = item.jsonString().utf8.count
            counts[Self.bucketIndex(forSizeBytes: bytes)] += 1
            sampled += 1
            // Release the doc's data right after measuring so memory
            // doesn't grow with sample size.
            item.dematerialize()
        }

        let buckets = zip(Self.bucketTemplates, counts).map { template, count in
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
        for (index, template) in bucketTemplates.enumerated() {
            guard let upper = template.upperBoundBytes else { return index }
            if size < upper { return index }
        }
        return bucketTemplates.count - 1
    }
}
