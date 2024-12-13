//
//  AuthenticationDelegate.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

/// A delegate responsible for handling authentication events for the Ditto SDK.
///
/// This class implements the `DittoAuthenticationDelegate` protocol and provides
/// functionality to authenticate users when required and refresh authentication when
/// it is about to expire.
public class AuthenticationDelegate: DittoAuthenticationDelegate {

    /// Called when authentication is required by the Ditto SDK.
    ///
    /// This method retrieves the active identity configuration and attempts to log in
    /// using the stored authentication token and provider. If either is missing, the
    /// process is aborted, and an error message is printed.
    ///
    /// - Parameter authenticator: The `DittoAuthenticator` instance responsible for handling the login process.
    public func authenticationRequired(authenticator: DittoAuthenticator) {
        // Retrieve the current identity configuration
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            print("No active identity configuration found.")
            return
        }

        // Ensure both authToken and authProvider are available
        guard let authToken = identityConfiguration.supplementaryCredentials.authToken,
            let authProvider = identityConfiguration.supplementaryCredentials.authProvider
        else {
            print("Missing authToken or authProvider in the identity configuration.")
            return
        }

        // Log the attempt for debugging purposes
        print("Attempting login with \(authToken), \(authProvider)")

        // Perform login using the provided credentials
        authenticator.login(token: authToken, provider: authProvider) { json, error in
            if let err = error {
                // Log an error if authentication fails
                print("Error authenticating: \(err.localizedDescription)")
            } else {
                // Log a success message with the response
                print("Authentication succeeded with response: \(String(describing: json))")
            }
        }
    }

    /// Called when the authentication is about to expire.
    ///
    /// This method retrieves the active identity configuration and attempts to refresh
    /// authentication using the stored authentication token and provider. If either is
    /// missing, the process is aborted, and an error message is printed.
    ///
    /// - Parameters:
    ///   - authenticator: The `DittoAuthenticator` instance responsible for handling the login process.
    ///   - secondsRemaining: The number of seconds remaining before the current authentication expires.
    public func authenticationExpiringSoon(authenticator: DittoAuthenticator, secondsRemaining: Int64) {
        // Retrieve the current identity configuration
        guard let identityConfiguration = IdentityConfigurationService.shared.activeConfiguration else {
            return
        }

        // Ensure both authToken and authProvider are available
        guard let authToken = identityConfiguration.supplementaryCredentials.authToken,
            let authProvider = identityConfiguration.supplementaryCredentials.authProvider
        else {
            print("Missing authToken or authProvider in the identity configuration.")
            return
        }

        // Log the token expiry time for debugging purposes
        print("Auth token expiring in \(secondsRemaining)")

        // Perform login using the provided credentials to refresh authentication
        authenticator.login(token: authToken, provider: authProvider) { json, error in
            if let err = error {
                // Log an error if authentication fails
                print("Error authenticating: \(err.localizedDescription)")
            } else {
                // Log a success message with the response
                print("Authentication succeeded with response: \(String(describing: json))")
            }
        }
    }
}
