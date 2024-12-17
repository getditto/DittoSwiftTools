// 
//  FormInputData.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift


/// Represents user input data required to configure and validate a Ditto identity.
///
/// This structure collects all the necessary fields required to create and validate
/// a `DittoIdentity` configuration. The `validate()` method ensures the integrity
/// of the input data based on the selected identity type.
struct FormInputData {
    
    /// The selected type of identity for Ditto.
    var identityType: DittoIdentity.IdentityType = .onlinePlayground
    
    /// The App ID associated with the identity.
    /// - Must not be empty for most identity types.
    var appID: String = ""
    
    /// The offline license token used for offline playground identities.
    /// - Must be a valid UUID.
    var offlineLicenseToken: String = ""
    
    /// The authentication token used for online playground identities.
    /// - Must be a valid UUID.
    var playgroundToken: String = ""
    
    /// Indicates whether Ditto Cloud Sync is enabled.
    /// - Applies to specific identity types that support cloud synchronization.
    var enableDittoCloudSync: Bool = true
    
    /// The authentication provider used for online identities.
    /// - Optional; leave empty if not required by the identity type.
    var authProvider: String = ""
    
    /// The authentication token used for online identities.
    /// - Must be a valid UUID if provided.
    var authToken: String = ""
    
    /// A custom authentication URL provided for specific identity types.
    /// - Must be a valid URL if not empty.
    var customAuthURLString: String = ""
    
    /// The site ID used for shared key and offline playground identities.
    /// - Optional; defaults to 0 if not required.
    var siteID: UInt64 = 0
    
    /// The shared key used for shared key identities.
    /// - Must be a valid UUID if provided.
    var sharedKey: String = ""
    
    /// The certificate configuration used for manual identities.
    /// - Required for manual identities; must not be empty.
    var certificateConfig: String = ""
    
    /// Validates the input fields of this structure based on the selected identity type.
    ///
    /// The validation logic checks for required fields and format constraints
    /// (e.g., non-empty strings, valid UUIDs, and properly formatted URLs).
    /// - Returns: An array of error messages. If no errors are found, the array is empty.
    func validate() -> [String] {
        var errors: [String] = []

        if identityType != .manual {
            // App ID is required and must be a valid UUID for most identity types
            if appID.isEmpty || UUID(uuidString: appID) == nil {
                errors.append("App ID must be a valid UUID.")
            }
        }
        
        // Validate fields specific to the selected identity type
        switch identityType {
        case .offlinePlayground:
            // Offline license token is required and must be a valid UUID
            if offlineLicenseToken.isEmpty || UUID(uuidString: offlineLicenseToken) == nil {
                errors.append("Offline license token must be a valid UUID.")
            }

        case .onlineWithAuthentication:
            // Validate custom authentication URL, if provided
            if !customAuthURLString.isEmpty {
                if let urlComponents = URLComponents(string: customAuthURLString),
                   urlComponents.scheme != nil, // Ensure a scheme like "https"
                   urlComponents.host != nil {  // Ensure a host like "example.com"
                    // URL is valid, proceed
                } else {
                    errors.append("The Custom Auth URL provided is not a valid format.")
                }
            }
            // Validate authentication token, if provided
            if !authToken.isEmpty {
                if UUID(uuidString: authToken) == nil {
                    errors.append("Auth Token must be a valid UUID.")
                }
            }


        case .onlinePlayground:
            // Playground token is required and must be a valid UUID
            if playgroundToken.isEmpty || UUID(uuidString: playgroundToken) == nil {
                errors.append("Online Playground auth token must be a valid UUID.")
            }
            // Validate custom authentication URL, if provided
            if !customAuthURLString.isEmpty {
                if let urlComponents = URLComponents(string: customAuthURLString),
                   urlComponents.scheme != nil, // Ensure a scheme like "https"
                   urlComponents.host != nil {  // Ensure a host like "example.com"
                    // URL is valid, proceed
                } else {
                    errors.append("The Custom Auth URL provided is not a valid format.")
                }
            }
            
        case .sharedKey:
            // Shared key is required and must be a valid UUID
            if sharedKey.isEmpty || UUID(uuidString: sharedKey) == nil {
                errors.append("Shared Key must be a valid UUID.")
            }
            // Offline license token is required and must be a valid UUID
            if offlineLicenseToken.isEmpty || UUID(uuidString: offlineLicenseToken) == nil {
                errors.append("Offline license token must be a valid UUID.")
            }

        case .manual:
            // Certificate configuration is required and must not be empty
            if certificateConfig.isEmpty {
                errors.append("A Certificate Config is required.")
            }
        }

        return errors
    }
}
