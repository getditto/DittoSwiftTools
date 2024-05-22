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
    var name: String
    var transportInfo: PeerTransportInfo
    var connected: Bool
    var lastSeen: Int
    var key: String
    var lastSeenFormatted: String {
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

func toPeer(dittoDocument: DittoDocument) -> Peer {
    return Peer(
        name: dittoDocument["_id"].stringValue,
        transportInfo: PeerTransportInfo(
            bluetoothConnections: Int(dittoDocument["bluetoothConnections"].stringValue)!,
            lanConnections: Int(dittoDocument["lanConnections"].stringValue)!,
            p2pConnections: Int(dittoDocument["p2pConnections"].stringValue)!,
            cloudConnections: Int(dittoDocument["cloudConnections"].stringValue)!
        ),
        connected: Bool(dittoDocument["connected"].stringValue)!,
        lastSeen: Int(dittoDocument["lastSeen"].stringValue)!,
        key: dittoDocument["key"].stringValue
    )
}

func getDateFromTimestamp(_ timestamp: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    formatter.locale = Locale.current
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    return formatter.string(from: date)
}
