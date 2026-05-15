//
//  CollectionSample.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// Result of a collection sample, grouped by JSON byte size.
public struct CollectionSample: Equatable, Hashable, Sendable {
    public let collectionName: String
    public let sampledCount: Int
    public let buckets: [DocSizeBucket]

    /// `true` if the sample hit the limit. Doesn't say whether the
    /// collection was actually truncated — that needs the true count.
    public let reachedLimit: Bool
    public let sampledAt: Date

    public init(
        collectionName: String,
        sampledCount: Int,
        buckets: [DocSizeBucket],
        reachedLimit: Bool,
        sampledAt: Date
    ) {
        self.collectionName = collectionName
        self.sampledCount = sampledCount
        self.buckets = buckets
        self.reachedLimit = reachedLimit
        self.sampledAt = sampledAt
    }
}
