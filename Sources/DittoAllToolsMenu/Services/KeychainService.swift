//
//  KeychainService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import Security


/// A service to save, load, and delete identity configurations from the Keychain.
public class KeychainService {
    
    // Keys used to store data in the Keychain
    static let DITTO_IDENTITY_KEY = "live.ditto.tools.dittoIdentity"
    static let DITTO_SUPPLEMENTARY_CREDENTIALS_KEY = "live.ditto.tools.dittoSupplementaryCredentials"
    
    // MARK: - Save Identity to Keychain
    
    /// Saves the identity configuration to the Keychain.
    /// - Parameter configuration: The identity configuration to save.
    /// - Returns: `true` if the save was successful, otherwise `false`.
    static func saveConfigurationToKeychain(_ configuration: IdentityConfiguration) -> Bool {
        let identityData = extractIdentityValues(from: configuration.identity)
        
        // Save identity to Keychain
        let identitySaveSuccess = saveToKeychain(data: identityData, key: DITTO_IDENTITY_KEY)
        
        // Extract supplementary credentials to be saved to Keychain
        let supplementaryData: [String: Any] = [
            "authProvider": configuration.supplementaryCredentials.authProvider ?? "",
            "authToken": configuration.supplementaryCredentials.authToken ?? "",
            "offlineLicenseToken": configuration.supplementaryCredentials.offlineLicenseToken ?? ""
        ]
        
        // Save supplementary credentials to Keychain
        let supplementarySaveSuccess = saveToKeychain(data: supplementaryData, key: DITTO_SUPPLEMENTARY_CREDENTIALS_KEY)
        
        // Return true if both the identity and supplementary config were saved successfully
        return identitySaveSuccess && supplementarySaveSuccess
    }
    
    // MARK: - Remove Identity from Keychain
    
    /// Removes the identity configuration from the Keychain.
    /// - Returns: `true` if the removal was successful, otherwise `false`.
    static func removeConfigurationFromKeychain() -> Bool {
        let identityDeleteSuccess = deleteFromKeychain(key: DITTO_IDENTITY_KEY)
        let supplementaryDeleteSuccess = deleteFromKeychain(key: DITTO_SUPPLEMENTARY_CREDENTIALS_KEY)
        
        // Return true if both deletions were successful
        return identityDeleteSuccess && supplementaryDeleteSuccess
    }
    
    // MARK: - Load Identity from Keychain
    
    /// Loads the identity configuration from the Keychain.
    /// - Parameter authDelegate: The authentication delegate for the identity.
    /// - Returns: The loaded identity configuration, or `nil` if loading fails.
    static func loadConfigurationFromKeychain(authDelegate: AuthenticationDelegate?) -> IdentityConfiguration? {
        // Load identity data and reconstruct the identity
        guard let identityData = loadFromKeychain(key: DITTO_IDENTITY_KEY),
              let identity = reconstructIdentity(from: identityData, authDelegate: authDelegate) else {
            return nil
        }
        
        // Load supplementary credentials
        let supplementaryData = loadFromKeychain(key: DITTO_SUPPLEMENTARY_CREDENTIALS_KEY)
        let supplementaryCredentials = SupplementaryCredentials(
            authProvider: supplementaryData?["authProvider"] as? String ?? "",
            authToken: supplementaryData?["authToken"] as? String ?? "",
            offlineLicenseToken: supplementaryData?["offlineLicenseToken"] as? String ?? ""
        )
        
        return IdentityConfiguration(identity: identity, supplementaryCredentials: supplementaryCredentials)
    }
}


extension KeychainService {

    // MARK: - Save and Delete Utilities

    /// Saves a dictionary to the Keychain.
    /// - Parameters:
    ///   - data: The data to save as a dictionary.
    ///   - key: The key to associate with the data.
    /// - Returns: `true` if the save was successful, otherwise `false`.
    private static func saveToKeychain(data: [String: Any], key: String) -> Bool {
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: jsonData ?? Data()
        ]

        SecItemDelete(query as CFDictionary)  // Remove existing item if present
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Deletes data from the Keychain.
    /// - Parameter key: The key associated with the data to delete.
    /// - Returns: `true` if the deletion was successful, otherwise `false`.
    private static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: - Serializing Utilities

    /// Converts a `DittoIdentity` into a dictionary for saving.
    /// - Parameter identity: The identity to convert.
    /// - Returns: A dictionary representation of the identity.
    private static func extractIdentityValues(from identity: DittoIdentity) -> [String: Any] {
        switch identity {
        case .offlinePlayground(let appID, let siteID):
            return ["type": "offlinePlayground", "appID": appID ?? "", "siteID": siteID ?? 0]

        case .onlineWithAuthentication(let appID, _, let enableDittoCloudSync, let customAuthURL):
            return ["type": "onlineWithAuthentication", "appID": appID, "enableDittoCloudSync": enableDittoCloudSync, "customAuthURL": customAuthURL?.absoluteString ?? ""]

        case .onlinePlayground(let appID, let token, let enableDittoCloudSync, let customAuthURL):
            return ["type": "onlinePlayground", "appID": appID, "token": token, "enableDittoCloudSync": enableDittoCloudSync, "customAuthURL": customAuthURL?.absoluteString ?? ""]

        case .sharedKey(let appID, let sharedKey, let siteID):
            return ["type": "sharedKey", "appID": appID, "sharedKey": sharedKey, "siteID": siteID ?? 0]

        case .manual(let certificateConfig):
            return ["type": "manual", "certificateConfig": certificateConfig]
        
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }
    
    // MARK: - Deserializing Utilities
    
    /// Loads data from the Keychain and converts it to a dictionary.
    /// - Parameter key: The key associated with the data to load.
    /// - Returns: A dictionary representation of the data, or `nil` if loading fails.
    private static func loadFromKeychain(key: String) -> [String: Any]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return try? JSONSerialization.jsonObject(with: retrievedData, options: []) as? [String: Any]
        }
        
        return nil
    }
    
    /// Reconstructs a `DittoIdentity` from a dictionary.
    /// - Parameters:
    ///   - data: The dictionary to reconstruct from.
    ///   - authDelegate: The authentication delegate required for some identity types.
    /// - Returns: A `DittoIdentity` if reconstruction succeeds, otherwise `nil`.
    private static func reconstructIdentity(from data: [String: Any], authDelegate: AuthenticationDelegate?) -> DittoIdentity? {
        guard let type = data["type"] as? String else { return nil }
        
        switch type {
        case "offlinePlayground":
            let appID = data["appID"] as? String
            let siteID = data["siteID"] as? UInt64
            return .offlinePlayground(appID: appID, siteID: siteID)

        case "onlineWithAuthentication":
            guard let authDelegate = authDelegate else {
                fatalError("Cannot reconstruct Identity from Keychain without a valid AuthDelegate.")
            }
            let appID = data["appID"] as! String
            let enableDittoCloudSync = data["enableDittoCloudSync"] as! Bool
            let customAuthURL = URL(string: data["customAuthURL"] as! String)
            return .onlineWithAuthentication(appID: appID, authenticationDelegate: authDelegate, enableDittoCloudSync: enableDittoCloudSync, customAuthURL: customAuthURL)

        case "onlinePlayground":
            let appID = data["appID"] as! String
            let token = data["token"] as! String
            let enableDittoCloudSync = data["enableDittoCloudSync"] as! Bool
            let customAuthURL = URL(string: data["customAuthURL"] as! String)
            return .onlinePlayground(appID: appID, token: token, enableDittoCloudSync: enableDittoCloudSync, customAuthURL: customAuthURL)

        case "sharedKey":
            let appID = data["appID"] as! String
            let sharedKey = data["sharedKey"] as! String
            let siteID = data["siteID"] as? UInt64
            return .sharedKey(appID: appID, sharedKey: sharedKey, siteID: siteID)

        case "manual":
            let certificateConfig = data["certificateConfig"] as! String
            return .manual(certificateConfig: certificateConfig)

        default:
            return nil
        }
    }
}
