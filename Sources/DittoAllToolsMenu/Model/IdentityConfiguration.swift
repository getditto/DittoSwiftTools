// 
//  IdentityConfiguration.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift


/// A representation of the configuration required to initialize a Ditto instance.
///
/// The `IdentityConfiguration` structure encapsulates the `DittoIdentity` object
/// and any supplementary credentials needed for specific identity types.
/// It is used to configure and manage the identity settings for a Ditto instance.
struct IdentityConfiguration {
    
    /// The core identity used to configure the Ditto instance.
    ///
    /// This includes information such as the identity type (e.g., `offlinePlayground`,
    /// `onlinePlayground`, `sharedKey`, etc.) and any associated parameters required
    /// for initialization (e.g., App ID, site ID, or shared key).
    let identity: DittoIdentity
    
    /// Additional credentials required for certain identity types.
    ///
    /// These credentials supplement the `DittoIdentity` object, providing
    /// values such as authentication tokens or offline license tokens.
    let supplementaryCredentials: SupplementaryCredentials
}
