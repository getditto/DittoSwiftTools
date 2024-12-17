// 
//  IdentityConfigurationService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

#warning("TODO: comments: the only public interface for this is the activeConfiguration, which can be retrieved (it'll attempt to fetch it from Keychain, if there is one) or set to nil, which will remove it from keychain entirely. Everything else is private.")

public class IdentityConfigurationService {
    
    // Shared Singleton Instance
    public static let shared = IdentityConfigurationService()
    
    private init() { }
    
    // Current active configuration
    private var storedConfiguration: IdentityConfiguration?
    
    /// The active identity configuration used by the app.
    ///
    /// This property retrieves or sets the currently active identity configuration.
    /// If no configuration is cached in memory (`storedConfiguration`), it attempts
    /// to load the configuration from the Keychain using the `authenticationDelegate`.
    ///
    /// Setting this property:
    /// - Saves the new configuration to the Keychain if a valid configuration is provided.
    /// - Removes the configuration from the Keychain if `nil` is assigned.
    ///
    /// Retrieving this property:
    /// - Returns the cached configuration (`storedConfiguration`) if available.
    /// - Loads and caches the configuration from the Keychain if one exists.
    /// - Returns `nil` if no configuration is found.
    ///
    /// - Note: Clearing this property (setting it to `nil`) removes the associated
    ///   credentials from the Keychain.
    ///
    /// Example:
    /// ```swift
    /// if let config = IdentityConfigurationService.shared.activeConfiguration {
    ///     print("Loaded configuration: \(config)")
    /// } else {
    ///     print("No active configuration found.")
    /// }
    /// ```
    var activeConfiguration: IdentityConfiguration? {
        get {
            // Return the cached configuration if already set
            if let configuration = storedConfiguration {
                return configuration
            }
            
            // Attempt to load the configuration from the Keychain if not cached, using the stored authenticationDelegate
            if let loadedConfiguration = loadConfigurationFromKeychain(authDelegate: authenticationDelegate) {
                storedConfiguration = loadedConfiguration // Cache it for future access
                return loadedConfiguration
            }
            
            // Return nil if no configuration is found in Keychain
            return nil
        }
        set {
            // Cache the new configuration in memory
            storedConfiguration = newValue
            
            // Save the new configuration to the Keychain, or remove it if nil
            if let newConfiguration = newValue {
                saveConfigurationToKeychain(newConfiguration)
                print("IdentityConfigurationService added credentials!")
            } else {
                removeConfigurationFromKeychain()
                print("IdentityConfigurationService removed credentials!")
            }
        }
    }
    
    public private(set) var authenticationDelegate = AuthenticationDelegate()
    
    // MARK: - Keychain Integration
    
    private func saveConfigurationToKeychain(_ configuration: IdentityConfiguration) {
        if KeychainService.saveConfigurationToKeychain(configuration) {
            print("Saved Identity Configuration to Keychain!")
        }
    }
    
    private func removeConfigurationFromKeychain() {
        if KeychainService.removeConfigurationFromKeychain() {
            print("Configuration removed from Keychain.")
        }
    }
    
    private func loadConfigurationFromKeychain(authDelegate: AuthenticationDelegate?) -> IdentityConfiguration? {
        if let configuration = KeychainService.loadConfigurationFromKeychain(authDelegate: authDelegate) {
            activeConfiguration = configuration
            return configuration
        }
        return nil
    }
}
