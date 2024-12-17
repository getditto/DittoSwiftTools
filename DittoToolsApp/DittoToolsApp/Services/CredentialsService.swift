// 
//  CredentialsService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

#warning("TODO: comments: the only public interface for this is the activeConfiguration, which can be retrieved (it'll attempt to fetch it from Keychain, if there is one) or set to nil, which will remove it from keychain entirely. Everything else is private.")

public class CredentialsService {
    
    // Shared Singleton Instance
    public static let shared = CredentialsService()
    
    private init() { }
    
    // Current active credentials
    private var storedCredentials: Credentials?
    
    /// The active credentials used by the app.
    ///
    /// This property retrieves or sets the currently active credentials.
    /// If no configuration is cached in memory (`storedCredentials`), it attempts
    /// to load credentials from the Keychain using the `authenticationDelegate`.
    ///
    /// Setting this property:
    /// - Saves the new configuration to the Keychain if a valid credentials object is provided.
    /// - Removes the credentials from the Keychain if `nil` is assigned.
    ///
    /// Retrieving this property:
    /// - Returns the cached credentials (`storedCredentials`) if available.
    /// - Loads and caches the credentials object from the Keychain if one exists.
    /// - Returns `nil` if no credentials are found.
    ///
    /// - Note: Clearing this property (setting it to `nil`) removes the associated
    ///   credentials from the Keychain.
    ///
    /// Example:
    /// ```swift
    /// if let credentials = CredentialsService.shared.activeCredentials {
    ///     print("Loaded credentials: \(credentials)")
    /// } else {
    ///     print("No active credentials found.")
    /// }
    /// ```
    var activeCredentials: Credentials? {
        get {
            // Return the cached credentials if already set
            if let credentials = storedCredentials {
                return credentials
            }
            
            // Attempt to load the credentials from the Keychain if not cached, using the stored authenticationDelegate
            if let loadedCredentials = loadCredentialsFromKeychain(authDelegate: authenticationDelegate) {
                storedCredentials = loadedCredentials // Cache it for future access
                return loadedCredentials
            }
            
            // Return nil if no credentials are found in Keychain
            return nil
        }
        set {
            // Cache the new credentials in memory
            storedCredentials = newValue
            
            // Save the new credentials to the Keychain, or remove them if nil
            if let newCredentials = newValue {
                saveCredentialsToKeychain(newCredentials)
                print("CredentialsService added credentials!")
            } else {
                removeCredentialsFromKeychain()
                print("CredentialsService removed credentials!")
            }
        }
    }
    
    public private(set) var authenticationDelegate = AuthenticationDelegate()
    
    // MARK: - Keychain Integration
    
    private func saveCredentialsToKeychain(_ credentials: Credentials) {
        if KeychainService.saveCredentialsToKeychain(credentials) {
            print("Saved credentials to Keychain!")
        }
    }
    
    private func removeCredentialsFromKeychain() {
        if KeychainService.removeCredentialsFromKeychain() {
            print("Credentials removed from Keychain.")
        }
    }
    
    private func loadCredentialsFromKeychain(authDelegate: AuthenticationDelegate?) -> Credentials? {
        if let credentials = KeychainService.loadCredentialsFromKeychain(authDelegate: authDelegate) {
            activeCredentials = credentials
            return credentials
        }
        return nil
    }
}
