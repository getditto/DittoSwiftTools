//
//  KeychainService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import Security

/// A service to save, load, and delete Credentials from the Keychain.
public class KeychainService {

    // Keys used to store data in the Keychain
    static let DITTO_CREDENTIALS_KEY = "live.ditto.tools.dittoIdentity"

    // MARK: - Save Credentials to Keychain

    /// Saves the credentials to the Keychain.
    /// - Parameter credentials: The Credentials to save.
    /// - Returns: `true` if the save was successful, otherwise `false`.
    static func saveCredentialsToKeychain(_ credentials: Credentials) -> Bool {
        let credentialsData = serializeCredentials(credentials)
        return saveToKeychain(data: credentialsData, key: DITTO_CREDENTIALS_KEY)
    }

    // MARK: - Load Credentials from Keychain

    /// Loads the credentials from the Keychain.
    /// - Parameter authDelegate: The authentication delegate for credentials reconstruction.
    /// - Returns: The loaded credentials, or `nil` if loading fails.
    static func loadCredentialsFromKeychain(authDelegate: AuthenticationDelegate?) -> Credentials? {
        guard let credentialsData = loadFromKeychain(key: DITTO_CREDENTIALS_KEY) else { return nil }
        return deserializeCredentials(from: credentialsData, authDelegate: authDelegate)
    }

    // MARK: - Remove Credentials from Keychain

    /// Removes the credentials from the Keychain.
    /// - Returns: `true` if the removal was successful, otherwise `false`.
    static func removeCredentialsFromKeychain() -> Bool {
        return deleteFromKeychain(key: DITTO_CREDENTIALS_KEY)
    }
}

extension KeychainService {

    // MARK: - Serialization and Deserialization

    /// Converts `Credentials` into a storable dictionary.
    private static func serializeCredentials(_ credentials: Credentials) -> [String: Any] {
        var data: [String: Any] = extractIdentityValues(from: credentials.identity)
        data["authProvider"] = credentials.authProvider ?? ""
        data["authToken"] = credentials.authToken ?? ""
        data["offlineLicenseToken"] = credentials.offlineLicenseToken ?? ""
        return data
    }

    /// Reconstructs `Credentials` from a dictionary.
    private static func deserializeCredentials(from data: [String: Any], authDelegate: AuthenticationDelegate?) -> Credentials? {
        guard let identity = reconstructIdentity(from: data, authDelegate: authDelegate) else { return nil }
        return Credentials(
            identity: identity,
            authProvider: data["authProvider"] as? String ?? "",
            authToken: data["authToken"] as? String ?? "",
            offlineLicenseToken: data["offlineLicenseToken"] as? String ?? ""
        )
    }

    /// Extracts identity values into a dictionary.
    private static func extractIdentityValues(from identity: DittoIdentity) -> [String: Any] {
        switch identity {
        case .offlinePlayground(let appID, let siteID):
            return ["type": "offlinePlayground", "appID": appID ?? "", "siteID": siteID ?? 0]
        case .onlineWithAuthentication(let appID, _, let enableCloudSync, let customAuthURL):
            return [
                "type": "onlineWithAuthentication", "appID": appID, "enableCloudSync": enableCloudSync,
                "customAuthURL": customAuthURL?.absoluteString ?? "",
            ]
        case .onlinePlayground(let appID, let token, let enableCloudSync, let customAuthURL):
            return [
                "type": "onlinePlayground", "appID": appID, "token": token, "enableCloudSync": enableCloudSync,
                "customAuthURL": customAuthURL?.absoluteString ?? "",
            ]
        case .sharedKey(let appID, let sharedKey, let siteID):
            return ["type": "sharedKey", "appID": appID, "sharedKey": sharedKey, "siteID": siteID ?? 0]
        case .manual(let certificateConfig):
            return ["type": "manual", "certificateConfig": certificateConfig]
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }

    /// Reconstructs a `DittoIdentity` from a dictionary.
    private static func reconstructIdentity(from data: [String: Any], authDelegate: AuthenticationDelegate?) -> DittoIdentity? {
        guard let type = data["type"] as? String else { return nil }
        switch type {
        case "offlinePlayground":
            let appID = data["appID"] as? String
            let siteID = data["siteID"] as? UInt64
            return .offlinePlayground(appID: appID, siteID: siteID)
        case "onlineWithAuthentication":
            guard let authDelegate = authDelegate else { return nil }
            let appID = data["appID"] as! String
            let enableCloudSync = data["enableCloudSync"] as! Bool
            let customAuthURL = URL(string: data["customAuthURL"] as! String)
            return .onlineWithAuthentication(
                appID: appID, authenticationDelegate: authDelegate, enableDittoCloudSync: enableCloudSync, customAuthURL: customAuthURL)
        case "onlinePlayground":
            let appID = data["appID"] as! String
            let token = data["token"] as! String
            let enableCloudSync = data["enableCloudSync"] as! Bool
            let customAuthURL = URL(string: data["customAuthURL"] as! String)
            return .onlinePlayground(appID: appID, token: token, enableDittoCloudSync: enableCloudSync, customAuthURL: customAuthURL)
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

    // MARK: - Keychain Utilities

    private static func saveToKeychain(data: [String: Any], key: String) -> Bool {
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: jsonData ?? Data(),
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func loadFromKeychain(key: String) -> [String: Any]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        return nil
    }

    private static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
