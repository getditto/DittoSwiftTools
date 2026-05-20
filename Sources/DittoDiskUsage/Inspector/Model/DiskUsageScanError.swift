//
//  DiskUsageScanError.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

public enum DiskUsageScanError: Error, LocalizedError, Equatable {
    case emptyResult
    case unexpectedResultFormat

    public var errorDescription: String? {
        switch self {
        case .emptyResult:
            return NSLocalizedString(
                "The query returned no result.",
                comment: "DiskUsageScanError.emptyResult"
            )
        case .unexpectedResultFormat:
            return NSLocalizedString(
                "The query returned an unexpected result shape.",
                comment: "DiskUsageScanError.unexpectedResultFormat"
            )
        }
    }
}
