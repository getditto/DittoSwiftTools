// 
//  IdentityConfigurationService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

#warning("TODO: comments: the only public interface for this is the activeConfiguration, which can be retrieved (it'll attempt to fetch it from Keychain, if there is one) or set to nil, which will remove it from keychain entirely. Everything else is private.")

#warning("TODO: There's also the ability to validate a configuration, which should provide some callback (todo), or perhaps that can just be added to the implementation of setting the activeConfiguration.")

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
            
            // Otherwise, attempt to load it from Keychain using the stored authDelegate
            if let loadedConfiguration = loadConfigurationFromKeychain(authDelegate: authDelegate) {
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
                print("added credentials!")
            } else {
                removeConfigurationFromKeychain()
                print("removed credentials!")
            }
        }
    }
    
    public private(set) var authDelegate = AuthDelegate()

    // MARK: - Keychain Integration

    private func saveConfigurationToKeychain(_ configuration: IdentityConfiguration) {
        if KeychainService.saveConfigurationToKeychain(configuration) {
            print("Saved!")
        }
    }
    
    private func removeConfigurationFromKeychain() {
        if KeychainService.removeConfigurationFromKeychain() {
            print("Configuration removed from Keychain.")
        }
    }

    private func loadConfigurationFromKeychain(authDelegate: AuthDelegate?) -> IdentityConfiguration? {
        if let configuration = KeychainService.loadConfigurationFromKeychain(authDelegate: authDelegate) {
            activeConfiguration = configuration
            return configuration
        }
        return nil
    }
    
    // MARK: - Validation

    func validateIdentity(_ identity: DittoIdentity) -> Bool {
        
#warning("TODO: implement Identity validation, to avoid crashing!")

        // Validate identity before setting it as active
        // (e.g., check required fields or formatting)
        return true // Implement validation logic as needed
    }
}



// MARK: - Auth Delegate

public class AuthDelegate: DittoAuthenticationDelegate {
    
    public func authenticationRequired(authenticator: DittoAuthenticator) {
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            return
        }
        let authToken = identityConfiguration.supplementaryCredentials.authToken
        let authProvider = identityConfiguration.supplementaryCredentials.authProvider
        print("login with \(authToken), \(authProvider)")
        authenticator.login(token: authToken, provider: authProvider) {json, error in
            if let err = error {
                print("Error authenticating \(String(describing: err.localizedDescription))")
            }
        }
    }
    
    public func authenticationExpiringSoon(authenticator: DittoAuthenticator, secondsRemaining: Int64) {
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            return
        }
        let authToken = identityConfiguration.supplementaryCredentials.authToken
        let authProvider = identityConfiguration.supplementaryCredentials.authProvider
        print("Auth token expiring in \(secondsRemaining)")
        authenticator.login(token: authToken, provider: authProvider) {json, error in
            if let err = error {
                print("Error authenticating \(String(describing: err.localizedDescription))")
            }
        }
    }
}
