// 
//  Credentials.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


/// A representation of the credentials required to initialize a Ditto instance.
///
/// The `Credentials` structure encapsulates the `DittoIdentity` object
/// and any supplementary credentials needed for specific identity types.
/// It is used to configure and manage the identity settings for a Ditto instance.
struct Credentials {

    // - MARK: Ditto Identity

    /// The core identity used to configure the Ditto instance.
    ///
    /// This includes information such as the identity type (e.g., `offlinePlayground`,
    /// `onlinePlayground`, `sharedKey`, etc.) and any associated parameters required
    /// for initialization (e.g., App ID, site ID, or shared key).
    let identity: DittoIdentity

    // - MARK: Supplementary Credentials
    
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
