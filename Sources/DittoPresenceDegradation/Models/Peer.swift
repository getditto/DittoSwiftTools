//
//  Peer.swift
//  
//
//  Created by Walker Erekson on 2/15/24.
//

import Foundation
import DittoSwift

public struct Peer: Identifiable {
    public var id: String { key }
    public var name: String
    public var transportInfo: PeerTransportInfo
    public var connected: Bool
    public var lastSeen: Int
    public var key: String
    public var lastSeenFormatted: String {
        return getDateFromTimestamp(lastSeen)
    }
}

func toMap(peer: Peer) -> [String: String] {
    return [
        "_id": peer.name,
        "bluetoothConnections": String(peer.transportInfo.bluetoothConnections),
        "lanConnections": String(peer.transportInfo.lanConnections),
        "p2pConnections": String(peer.transportInfo.p2pConnections),
        "cloudConnections": String(peer.transportInfo.cloudConnections),
        "connected": String(peer.connected),
        "lastSeen": String(peer.lastSeen),
        "key": peer.key
    ]
}

func getDateFromTimestamp(_ timestamp: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    formatter.locale = Locale.current
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    return formatter.string(from: date)
}
