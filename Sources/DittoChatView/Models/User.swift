//
//  User.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import Foundation
import DittoSwift

struct User {
    let _id: String
    let name: String

    init(id: String, name: String) {
        self._id = id
        self.name = name
    }

    init(doc: DittoDocument) {
        self._id = doc.id.stringValue
        self.name = doc["name"].stringValue
    }

    var dict: [String: Any?] {
        return [
            "_id": _id,
            "name": name,
        ]
    }
}
