//
//  ByteCountFormatting.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// Shared `ByteCountFormatter` for size strings like `"4.2 MB"`.
enum ByteCountFormatting {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    static func format(_ bytes: Int) -> String {
        formatter.string(for: bytes) ?? "\(bytes) bytes"
    }
}
