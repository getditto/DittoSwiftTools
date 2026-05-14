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
        case .emptyResult: return "The query returned no result."
        case .unexpectedResultFormat: return "The query returned an unexpected result shape."
        }
    }
}
