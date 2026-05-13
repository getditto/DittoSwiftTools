//
//  StorageCategory.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// A top-level on-disk storage category, used purely for user-facing glossary
/// copy. The Inspector does not currently bucket bytes per category — that
/// requires SDK support beyond the documented `diskUsagePublisher()` total.
public enum StorageCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case store
    case attachments
    case logs
    case replication

    public var id: String { rawValue }

    public var displayName: LocalizedStringKey {
        switch self {
        case .store: return "Store"
        case .attachments: return "Attachments"
        case .logs: return "Logs"
        case .replication: return "Replication"
        }
    }

    public var glossary: LocalizedStringKey {
        switch self {
        case .store:
            return "Local document data, indexes, and metadata managed by Ditto."
        case .attachments:
            return "Binary attachment files stored alongside documents."
        case .logs:
            return "Diagnostic log files written by the Ditto SDK."
        case .replication:
            return "Working data used by sync to track peers and exchange changes."
        }
    }
}
