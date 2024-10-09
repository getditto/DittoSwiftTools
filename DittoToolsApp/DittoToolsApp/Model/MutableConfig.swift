//
//  MutableConfig.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift

struct MutableConfig {
    var appID = ""
    var playgroundToken = ""
    var identityType = IdentityType.onlinePlayground
    var offlineLicenseToken = ""
    var authenticationProvider = ""
    var authenticationToken = ""
    var useIsolatedDirectories = true
}
