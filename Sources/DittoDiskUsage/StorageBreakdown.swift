//
//  StorageBreakdown.swift
//  DittoSwiftTools/DittoDiskUsage
//

import Foundation

public struct StorageBreakdown: Equatable {
    public var totalOnDiskBytes: Int = 0
    public var storeBytes: Int = 0
    public var attachmentBytes: Int = 0
    public var logsBytes: Int = 0
    public var replicationBytes: Int = 0

    public init() {}
}

extension StorageBreakdown {
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    public static func formatBytes(_ bytes: Int) -> String {
        byteCountFormatter.string(for: bytes) ?? "\(bytes) bytes"
    }
}
