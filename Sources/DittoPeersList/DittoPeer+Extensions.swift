//
//  DittoPeer+Extensions.swift
//  
//
//  Created by Walker Erekson on 2/12/24.
//

import Foundation
import DittoSwift
import CryptoKit

extension DittoPeer {
    var peerSDKVersion: String {
        let sdk = "SDK "
        if let version = dittoSDKVersion {
            return sdk + "v\(version)"
        }
        return sdk + "N/A"
    }
}


