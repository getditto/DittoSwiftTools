//
//  StorageBreakdown.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation
import DittoSwift

/// A point-in-time snapshot of on-disk storage from `diskUsagePublisher()`.
///
/// Only the SDK-reported total is captured. The Inspector deliberately does
/// not infer per-category bytes from path strings, since that would rely on
/// the SDK's internal directory-naming conventions.
public struct StorageBreakdown: Equatable, Hashable, Sendable {
    public let totalOnDiskBytes: Int
    public let capturedAt: Date

    public init(totalOnDiskBytes: Int = 0, capturedAt: Date = Date(timeIntervalSince1970: 0)) {
        self.totalOnDiskBytes = totalOnDiskBytes
        self.capturedAt = capturedAt
    }

    public static let empty = StorageBreakdown()
}

// MARK: - DittoSwift mapping

extension StorageBreakdown {
    init(item: DiskUsageItem, capturedAt: Date) {
        self.init(totalOnDiskBytes: item.sizeInBytes, capturedAt: capturedAt)
    }
}
