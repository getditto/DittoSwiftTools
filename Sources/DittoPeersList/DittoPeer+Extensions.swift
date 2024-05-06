//
//  File.swift
//  
//
//  Created by Walker Erekson on 2/12/24.
//

import Foundation
import DittoSwift
import CryptoKit

@available(iOS 13.0, *)
extension DittoPeer {
    var peerSDKVersion: String {
        let sdk = "SDK "
        if let version = dittoSDKVersion {
            return sdk + "v\(version)"
        }
        return sdk + "N/A"
    }
}


