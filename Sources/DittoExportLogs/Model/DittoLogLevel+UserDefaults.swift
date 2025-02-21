//
//  DittoLogLevel+UserDefaults.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


public extension DittoLogLevel {
    /// The raw value key used for storing and retrieving the log level.
    private static let storageKey = "DittoLogger.minimumLogLevel"

    /// Saves the current log level to UserDefaults.
    func saveToStorage() {
        UserDefaults.standard.set(self.rawValue, forKey: DittoLogLevel.storageKey)
    }

    /// Restores the log level from UserDefaults, defaulting to `.info` if no value is found.
    static func restoreFromStorage() -> DittoLogLevel {
        let rawValue = UserDefaults.standard.integer(forKey: storageKey)
        return DittoLogLevel(rawValue: rawValue) ?? .error
    }
}
