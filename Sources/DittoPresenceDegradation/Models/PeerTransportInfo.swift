//
//  PeerTransportInfo.swift
//
//
//  Created by Walker Erekson on 2/15/24.
//

import Foundation

public struct PeerTransportInfo {
    public var bluetoothConnections: Int
    public var lanConnections: Int
    public var p2pConnections: Int
    public var cloudConnections: Int

    public init(bluetoothConnections: Int, lanConnections: Int, p2pConnections: Int, cloudConnections: Int) {
        self.bluetoothConnections = bluetoothConnections
        self.lanConnections = lanConnections
        self.p2pConnections = p2pConnections
        self.cloudConnections = cloudConnections
    }
}
