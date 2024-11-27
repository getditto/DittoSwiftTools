// 
//  AuthenticationDelegate.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


public class AuthenticationDelegate: DittoAuthenticationDelegate {
    
    public func authenticationRequired(authenticator: DittoAuthenticator) {
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            print("No active identity configuration found.")
            return
        }
        guard let authToken = identityConfiguration.supplementaryCredentials.authToken,
              let authProvider = identityConfiguration.supplementaryCredentials.authProvider else {
            print("Missing authToken or authProvider in the identity configuration.")
            return
        }
        
        print("Attempting login with \(authToken), \(authProvider)")
        
        authenticator.login(token: authToken, provider: authProvider) { json, error in
            if let err = error {
                print("Error authenticating: \(err.localizedDescription)")
            } else {
                print("Authentication succeeded with response: \(String(describing: json))")
            }
        }
    }
    
    public func authenticationExpiringSoon(authenticator: DittoAuthenticator, secondsRemaining: Int64) {
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            return
        }
        guard let authToken = identityConfiguration.supplementaryCredentials.authToken,
              let authProvider = identityConfiguration.supplementaryCredentials.authProvider else {
            print("Missing authToken or authProvider in the identity configuration.")
            return
        }

        print("Auth token expiring in \(secondsRemaining)")
        
        authenticator.login(token: authToken, provider: authProvider) { json, error in
            if let err = error {
                print("Error authenticating: \(err.localizedDescription)")
            } else {
                print("Authentication succeeded with response: \(String(describing: json))")
            }
        }
    }
}
