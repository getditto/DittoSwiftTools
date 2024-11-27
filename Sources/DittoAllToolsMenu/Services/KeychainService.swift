//
//  KeychainService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import Security

#warning("TODO: comments")

public class KeychainService {
    
    static let DITTO_IDENTITY_KEY = "live.ditto.tools.dittoIdentity"
    static let DITTO_SUPPLEMENTARY_CREDENTIALS_KEY = "live.ditto.tools.dittoSupplementaryCredentials"
    
    // MARK: - Save Identity to Keychain
    
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
    
    static func removeConfigurationFromKeychain() -> Bool {
        let identityDeleteSuccess = deleteFromKeychain(key: DITTO_IDENTITY_KEY)
        let supplementaryDeleteSuccess = deleteFromKeychain(key: DITTO_SUPPLEMENTARY_CREDENTIALS_KEY)
        
        // Return true if both deletions were successful
        return identityDeleteSuccess && supplementaryDeleteSuccess
    }
    
    // MARK: - Load Identity from Keychain
    
    static func loadConfigurationFromKeychain(authDelegate: AuthenticationDelegate?) -> IdentityConfiguration? {
        guard let identityData = loadFromKeychain(key: DITTO_IDENTITY_KEY),
              let identity = reconstructIdentity(from: identityData, authDelegate: authDelegate) else {
            return nil
        }
        
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
    
    private static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: - Serializing Utilities

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
