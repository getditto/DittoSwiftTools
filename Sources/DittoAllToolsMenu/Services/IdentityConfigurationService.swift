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
    
    var activeConfiguration: IdentityConfiguration? {
        get {
            // If storedConfiguration is already set, return it directly
            if let configuration = storedConfiguration {
                return configuration
            }
            
            // Otherwise, attempt to load it from Keychain using the stored authenticationDelegate
            if let loadedConfiguration = loadConfigurationFromKeychain(authDelegate: authenticationDelegate) {
                storedConfiguration = loadedConfiguration // Cache it for future access
                return loadedConfiguration
            }
            
            // Return nil if nothing is found in Keychain
            return nil
        }
        set {
            storedConfiguration = newValue
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
