//
//  DQLIdentifier.swift
//  DittoSwiftTools/DittoDiskUsage
//
//  Created by Rohith Sriram on 4/21/26.
//

import Foundation

/// Helpers for safely embedding identifiers in DQL query strings.
enum DQLIdentifier {
    /// Backtick-wraps an identifier, doubling any embedded backticks.
    static func escape(_ name: String) -> String {
        "`\(name.replacingOccurrences(of: "`", with: "``"))`"
    }
}
