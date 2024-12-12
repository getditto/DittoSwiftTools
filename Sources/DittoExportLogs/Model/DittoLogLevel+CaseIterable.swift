// 
//  DittoLogLevel+CaseIterable.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


extension DittoLogLevel: @retroactive CaseIterable {
    /// Provides an array of all cases in the enum for iteration.
    public static var allCases: [DittoLogLevel] {
        return [.error, .warning, .info, .debug, .verbose]
    }

    /// A list of log levels suitable for display in the user interface.
    ///
    /// This excludes `.verbose` to discourage its use, as it can significantly impact
    /// performance without providing substantial additional debugging value compared
    /// to `.debug`.
    public static var displayableCases: [DittoLogLevel] {
        return allCases.filter { $0 != .verbose }
    }

    /// Returns a user-friendly display name for each log level.
    var displayName: String {
        switch self {
        case .error:
            return "Error"
        case .warning:
            return "Warning"
        case .info:
            return "Info"
        case .debug:
            return "Debug"
        case .verbose:
            return "Verbose"
        @unknown default:
            fatalError("Unknown DittoLogLevel")
        }
    }
}


