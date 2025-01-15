//
//  DittoIdentity+Extension.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


/// Extension to `DittoIdentity` for extracting associated values and managing identity types.
extension DittoIdentity {
    
    /// Retrieves the `appID` associated with the `DittoIdentity` instance.
    ///
    /// This computed property returns the `appID` value for identity types that include it
    /// (e.g., `offlinePlayground`, `onlineWithAuthentication`, etc.). If the identity type
    /// does not have an `appID` (e.g., `manual`), it returns `nil`.
    ///
    /// - Returns: The `appID` if available, or `nil` for identity types that do not have one.
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



/// Extension to `DittoIdentity` for defining identity types without associated values.
///
/// The `DittoIdentity` enum does not directly conform to the `CaseIterable` protocol
/// because it has associated values, and `CaseIterable` only works with enums
/// that have no associated values. To enable iteration over identity types,
/// this extension introduces a new enum, `IdentityType`, which represents the
/// distinct identity types without any associated values.
extension DittoIdentity {
    
    /// Enum representing the different identity types of `DittoIdentity`.
    ///
    /// This enum simplifies working with identity types by removing the associated values
    /// present in `DittoIdentity`. It conforms to `CaseIterable`, enabling iteration over all
    /// identity types (e.g., for use in a `Picker`).
    enum IdentityType: String, CaseIterable {
        case offlinePlayground = "Offline Playground"
        case onlineWithAuthentication = "Online with Authentication"
        case onlinePlayground = "Online Playground"
        case sharedKey = "Shared Key"
        case manual = "Manual"
    }

    /// Computed property to derive the `IdentityType` from a `DittoIdentity` instance.
    ///
    /// This property maps the current `DittoIdentity` case to its corresponding `IdentityType`.
    /// This allows you to work with the identity type in a simpler, associated-value-free format.
    ///
    /// - Returns: The corresponding `IdentityType` for the current `DittoIdentity` instance.
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

    /// A static property providing all possible identity types.
    ///
    /// This property mirrors the `CaseIterable` functionality for the `IdentityType` enum,
    /// allowing you to access all identity types in a single array.
    ///
    /// - Returns: An array containing all cases of the `IdentityType` enum.
    static var identityTypes: [IdentityType] {
        return IdentityType.allCases
    }
}
