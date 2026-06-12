//
//  Settings.swift
//  
//
//  Created by Walker Erekson on 2/15/24.
//

import Foundation
import DittoSwift

public struct Settings {
    public let expectedPeers: Int
    public let reportApiEnabled: Bool
    public let hasSeenExpectedPeers: Bool
    public let sessionStartedAt: String

    public init(expectedPeers: Int = 0,
                reportApiEnabled: Bool = false,
                hasSeenExpectedPeers: Bool = false,
                sessionStartedAt: String = "") {
        self.expectedPeers = expectedPeers
        self.reportApiEnabled = reportApiEnabled
        self.hasSeenExpectedPeers = hasSeenExpectedPeers
        self.sessionStartedAt = sessionStartedAt
    }
}

extension Settings {
    func toMap() -> [String: String] {
        return [
            "_id": "settings",
            "expectedPeers": String(expectedPeers),
            "reportApiEnabled": String(reportApiEnabled),
            "hasSeenExpectedPeers": String(hasSeenExpectedPeers),
            "sessionStartedAt": String(sessionStartedAt)
        ]
    }
}

