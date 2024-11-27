// 
//  SupplementaryCredentials.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//



/// Represents additional credentials required to configure certain Ditto identity types.
///
/// The `SupplementaryCredentials` structure provides optional properties that
/// supplement a `DittoIdentity` object. These credentials may be necessary for
/// authentication, offline license verification, or secure communication.
struct SupplementaryCredentials {
    
    /// The name of the callback method or hook used by the SDK for authentication purposes.
    ///
    /// This property specifies the name of the method or endpoint the SDK should invoke
    /// to handle authentication. If a custom authentication URL is provided, the
    /// `authProvider` acts as the callback or hook for custom authentication workflows.
    /// It is optional and primarily used for identity types like `onlineWithAuthentication`.
    var authProvider: String?
    
    /// The token used to authenticate with the authentication provider.
    ///
    /// This is often provided by the authentication system and required for
    /// secure access to the Ditto service.
    var authToken: String?
    
    /// The offline license token used for offline capabilities.
    ///
    /// Required for `offlinePlayground` and `sharedKey` identities to validate
    /// offline use of the Ditto service.
    var offlineLicenseToken: String?
    
    /// The shared key used for `sharedKey` identities.
    ///
    /// Used to secure data and establish identity for shared key configurations.
    var sharedKey: String?
}
