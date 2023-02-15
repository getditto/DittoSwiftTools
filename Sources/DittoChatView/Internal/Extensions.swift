//
//  Extensions.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import Foundation

extension UserDefaults {

    var userID: String? {
        get {
            return self.string(forKey: "ditto-chat-userID")
        } set {
            self.setValue(newValue, forKey: "ditto-chat-userID")
        }
    }

    var userName: String? {
        get {
            return self.string(forKey: "ditto-chat-userName")
        } set {
            self.setValue(newValue, forKey: "ditto-chat-userName")
        }
    }
}
