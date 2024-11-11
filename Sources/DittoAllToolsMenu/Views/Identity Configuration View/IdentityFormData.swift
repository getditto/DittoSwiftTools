// 
//  IdentityFormData.swift
//
//  This file defines a data model used to handle the form data in the identity configuration process.
//  It provides methods to initialize form data from existing identity configurations and to convert form data into a Ditto `IdentityConfiguration`.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI
import DittoSwift

/// A data model that stores the identity configuration data entered in the form.
///
/// `IdentityFormData` contains all fields necessary for configuring different types of identities used in Ditto.
/// It supports various identity types, such as `onlinePlayground`, `offlinePlayground`, and `manual`. This struct
/// also provides functionality to convert between form data and `IdentityConfiguration` instances.
struct IdentityFormData {
    var identityType: DittoIdentity.IdentityType = .onlinePlayground
    var appID: String = ""
    var offlineLicenseToken: String = ""
    var playgroundToken: String = ""
    var enableDittoCloudSync: Bool = true
    var authProvider: String = ""
    var authToken: String = ""
    var customAuthURL: String = ""
    var siteID: UInt64 = 0
    var sharedKey: String = ""
    var certificateConfig: String = ""

    /// Default initializer for an empty identity form data model.
    init() {
    }
    
    /// Initializes `IdentityFormData` with an existing `IdentityConfiguration`.
    ///
    /// This initializer takes an `IdentityConfiguration` object and populates the form fields
    /// based on the values from the configuration. It handles various identity types and their
    /// specific fields.
    /// - Parameter configuration: The existing `IdentityConfiguration` used to populate the form.
    init(with configuration: IdentityConfiguration) {
        self.identityType = configuration.identity.identityType
        
        switch configuration.identity {
        case .onlinePlayground(let appID, let token, let enableDittoCloudSync, let customAuthURL):
            self.appID = appID
            self.playgroundToken = token
            self.enableDittoCloudSync = enableDittoCloudSync
            self.customAuthURL = customAuthURL?.absoluteString ?? ""

        case .onlineWithAuthentication(let appID, _, let enableDittoCloudSync, let customAuthURL):
            self.appID = appID
            self.enableDittoCloudSync = enableDittoCloudSync
            self.customAuthURL = customAuthURL?.absoluteString ?? ""
            self.authProvider = configuration.supplementaryCredentials.authProvider
            self.authToken = configuration.supplementaryCredentials.authToken

        case .offlinePlayground(let appID, let siteID):
            self.appID = appID ?? ""
            self.siteID = siteID ?? 0
            self.offlineLicenseToken = configuration.supplementaryCredentials.offlineLicenseToken

        case .sharedKey(let appID, let sharedKey, let siteID):
            self.appID = appID
            self.sharedKey = sharedKey
            self.siteID = siteID ?? 0

        case .manual(let certificateConfig):
            self.certificateConfig = certificateConfig
            
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }
    
    /// Converts the current form data into an `IdentityConfiguration` object.
    ///
    /// This utility method generates an `IdentityConfiguration` instance based on the values
    /// entered in the form. It creates the appropriate `DittoIdentity` based on the selected identity type,
    /// and adds any necessary supplementary credentials such as authentication tokens or offline license tokens.
    /// - Returns: A fully configured `IdentityConfiguration` object.
    func toIdentityConfiguration() -> IdentityConfiguration {
        let identity: DittoIdentity
        
        // Create the appropriate DittoIdentity based on the form data
        switch self.identityType {
        case .onlinePlayground:
            identity = .onlinePlayground(
                appID: self.appID,
                token: self.playgroundToken,
                enableDittoCloudSync: self.enableDittoCloudSync,
                customAuthURL: URL(string: self.customAuthURL)
            )
            
        case .onlineWithAuthentication:
            identity = .onlineWithAuthentication(
                appID: self.appID,
                authenticationDelegate: IdentityConfigurationService.shared.authDelegate,
                enableDittoCloudSync: self.enableDittoCloudSync,
                customAuthURL: URL(string: self.customAuthURL)
            )
            
        case .offlinePlayground:
            identity = .offlinePlayground(
                appID: self.appID.isEmpty ? nil : self.appID,
                siteID: self.siteID == 0 ? nil : self.siteID
            )
            
        case .sharedKey:
            identity = .sharedKey(
                appID: self.appID,
                sharedKey: self.sharedKey,
                siteID: self.siteID == 0 ? nil : self.siteID
            )
            
        case .manual:
            identity = .manual(certificateConfig: self.certificateConfig)
        }
        
        // Create supplementary credentials (optional)
        let supplementaryCredentials = SupplementaryCredentials(
            authProvider: self.authProvider,
            authToken: self.authToken,
            offlineLicenseToken: self.offlineLicenseToken
        )
        
        // Return the full IdentityConfiguration object
        return IdentityConfiguration(identity: identity, supplementaryCredentials: supplementaryCredentials)
    }
}
