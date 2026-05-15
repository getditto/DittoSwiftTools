//
//  StorageCategory+Visuals.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import SwiftUI

/// User-facing copy for ``StorageCategory``. Kept separate from the model
/// so the enum itself stays SwiftUI-free.
public extension StorageCategory {
    var displayName: LocalizedStringKey {
        switch self {
        case .store: return "Store"
        case .attachments: return "Attachments"
        case .logs: return "Logs"
        case .replication: return "Replication"
        }
    }

    var glossary: LocalizedStringKey {
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
