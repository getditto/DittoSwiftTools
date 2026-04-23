//
//  Settings.swift
//  
//
//  Created by Walker Erekson on 2/15/24.
//

import Foundation
import DittoSwift

public struct Settings {
    let expectedPeers: Int
    let reportApiEnabled: Bool
    let hasSeenExpectedPeers: Bool
    let sessionStartedAt: String
    
    init(expectedPeers: Int = 0,
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

extension DittoQueryResultItem {
    func toSettings() -> Settings {
        return Settings(
            expectedPeers: Int(self.value["expectedPeers"] as? String ?? "0")!,
            reportApiEnabled: Bool(self.value["reportApiEnabled"] as? String ?? "false")!,
            hasSeenExpectedPeers: Bool(self.value["hasSeenExpectedPeers"] as? String ?? "false")!,
            sessionStartedAt: self.value["sessionStartedAt"] as? String ?? ""
        )
    }
}

