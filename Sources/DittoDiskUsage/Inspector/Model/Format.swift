//
//  Format.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// Shared formatting helpers. Each method wraps a Foundation formatter
/// behind a static call so we don't churn through formatter instances
/// at render time.
enum Format {
    /// Byte-size strings like `"4.2 MB"` via `ByteCountFormatter`.
    static func bytes(_ bytes: Int) -> String {
        Self.byteFormatter.string(for: bytes) ?? "\(bytes) bytes"
    }

    /// Decimal count strings like `"12,847"` via `NumberFormatter`.
    static func count(_ value: Int) -> String {
        Self.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
