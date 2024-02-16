//
//  File.swift
//  
//
//  Created by Walker Erekson on 2/15/24.
//

import Foundation
import DittoSwift

struct Settings {
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
    
//    var sessionStartedAtFormatted: Date {
//        return Date(timeIntervalSince1970: TimeInterval(sessionStartedAt))
//    }
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

extension DittoDocument {
    func toSettings() -> Settings {
        return Settings(
            expectedPeers: Int(self["expectedPeers"].stringValue)!,
            reportApiEnabled: Bool(self["reportApiEnabled"].stringValue)!,
            hasSeenExpectedPeers: Bool(self["hasSeenExpectedPeers"].stringValue)!,
            sessionStartedAt: self["sessionStartedAt"].stringValue
        )
    }
}
