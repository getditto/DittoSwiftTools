//
//  CountFormatting.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

extension Int {
    /// Localized, grouped decimal count (e.g. `"12,847"`).
    var formattedAsCount: String {
        CountFormatting.string(forCount: self)
    }
}

/// Shared decimal `NumberFormatter` for document-count strings.
enum CountFormatting {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func string(forCount value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
