//
//  ByteCountFormatting.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

enum ByteCountFormatting {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    static func string(forBytes bytes: Int) -> String {
        formatter.string(for: bytes) ?? "\(bytes) bytes"
    }
}

extension Int {
    var formattedByteCount: String {
        ByteCountFormatting.string(forBytes: self)
    }
}
