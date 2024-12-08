// 
//  DittoServiceError.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Foundation


/// Errors that may occur while interacting with the `DittoService`.
///
/// These errors provide detailed information about failures encountered during
/// the initialization or operation of a Ditto instance, such as missing identity
/// configurations, invalid inputs, or runtime issues.
enum DittoServiceError: Error {

    /// Indicates that no `Ditto` instance is available.
    ///
    /// This error occurs when an attempt is made to interact with the service
    /// without initializing a `Ditto` instance.
    case noInstance

    /// Indicates that an invalid identity was provided.
    ///
    /// - Parameter message: A custom message detailing the reason why the identity is invalid.
    case invalidIdentity(String)

    /// Indicates that the initialization of the `Ditto` instance failed.
    ///
    /// - Parameter reason: A detailed description of why the initialization failed.
    case initializationFailed(String)

    /// Indicates that starting the sync engine failed.
    ///
    /// - Parameter reason: A detailed description of why the sync operation failed.
    case syncFailed(String)
}


/// Provides localized error descriptions for `DittoServiceError`.
extension DittoServiceError: LocalizedError {

    /// A human-readable description of the error.
    public var errorDescription: String? {
        switch self {
        case .noInstance:
            // Error message for missing Ditto instance
            return NSLocalizedString("No Ditto instance is available.", comment: "No instance error")
            
        case .invalidIdentity(let message):
            // Error message for invalid identity with a specific reason
            return NSLocalizedString(message, comment: "Invalid identity error")
            
        case .initializationFailed(let reason):
            // Error message for Ditto initialization failure with a specific reason
            return NSLocalizedString("Ditto initialization failed: \(reason)", comment: "Initialization failure error")
            
        case .syncFailed(let reason):
            // Error message for sync engine failure with a specific reason
            return NSLocalizedString("Failed to start sync: \(reason)", comment: "Sync failure error")
        }
    }
}
