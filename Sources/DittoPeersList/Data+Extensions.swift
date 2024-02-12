//
//  File.swift
//  
//
//  Created by Walker Erekson on 2/12/24.
//

import Foundation
import DittoSwift

@available(iOS 13.0, *)
extension Data {
    func peerKeyString(from peer: DittoPeer) -> String {
        return peer.toPeerKeyString(self)
    }
}
