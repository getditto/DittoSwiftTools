//
//  DittoIdentity+Extension.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

#warning("TODO: comments")

extension DittoIdentity {
    var appID: String? {
        switch self {
        case .offlinePlayground(let appID, _):
            return appID
        case .onlineWithAuthentication(let appID, _, _, _):
            return appID
        case .onlinePlayground(let appID, _, _, _):
            return appID
        case .sharedKey(let appID, _, _):
            return appID
        case .manual:
            return nil
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }
}


// Create an enum that represents the different identity types without associated values
extension DittoIdentity {
    
    /// This enum represents the different types of DittoIdentity without the associated values. It conforms to CaseIterable, so you can use it to loop through the types or display them in a Picker.
    enum IdentityType: String, CaseIterable {
        case offlinePlayground = "Offline Playground"
        case onlineWithAuthentication = "Online with Authentication"
        case onlinePlayground = "Online Playground"
        case sharedKey = "Shared Key"
        case manual = "Manual"
    }

    // Computed property to get the IdentityType from a DittoIdentity instance
    var identityType: IdentityType {
        switch self {
        case .offlinePlayground:
            return .offlinePlayground
        case .onlineWithAuthentication:
            return .onlineWithAuthentication
        case .onlinePlayground:
            return .onlinePlayground
        case .sharedKey:
            return .sharedKey
        case .manual:
            return .manual
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }

    // Static array to mimic CaseIterable for IdentityType enum
    static var identityTypes: [IdentityType] {
        return IdentityType.allCases
    }
}
