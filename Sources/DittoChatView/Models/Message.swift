//
//  Message.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import Foundation
import DittoSwift

struct Message: Hashable, Identifiable {
    let userID: String
    let text: String
    let timestamp: Date

    init(userID: String, text: String, timestamp: Date) {
        self.userID = userID
        self.text = text
        self.timestamp = timestamp
    }

    init(doc: DittoDocument) {
        self.userID = doc["userID"].stringValue
        self.text = doc["text"].stringValue

        let doubleTime = doc["timestamp"].doubleValue
        self.timestamp = Date(timeIntervalSince1970: doubleTime)
    }

    var dict: [String: Any?] {
        return [
            "userID": userID,
            "text": text,
            "timestamp": timestamp.timeIntervalSince1970,
        ]
    }

    var id: String {
        return userID + text + dateString
    }

    func isCurrentUser(id: String) -> Bool {
        return userID == id
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    func getUserName(users: [User]) -> String? {
        var name: String? = nil

        users.forEach { user in
            if user._id == userID {
                name = user.name
            }
        }
        return name
    }
}
