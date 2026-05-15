//
//  StorageCategory.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// A top-level on-disk storage category, used purely for user-facing glossary
/// copy. The Inspector does not currently bucket bytes per category — that
/// requires SDK support beyond the documented `diskUsagePublisher()` total.
public enum StorageCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case store
    case attachments
    case logs
    case replication

    public var id: String { rawValue }
}
