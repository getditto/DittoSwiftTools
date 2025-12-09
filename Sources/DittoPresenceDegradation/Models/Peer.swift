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

func toPeer(queryResultItem: DittoQueryResultItem) -> Peer {
    return Peer(
        name: queryResultItem.value["_id"] as? String ?? "",
        transportInfo: PeerTransportInfo(
            bluetoothConnections: Int(queryResultItem.value["bluetoothConnections"] as? String ?? "0") ?? 0,
            lanConnections: Int(queryResultItem.value["lanConnections"] as? String ?? "0") ?? 0,
            p2pConnections: Int(queryResultItem.value["p2pConnections"] as? String ?? "0") ?? 0,
            cloudConnections: Int(queryResultItem.value["cloudConnections"] as? String ?? "0") ?? 0
        ),
        connected: Bool(queryResultItem.value["connected"] as? String ?? "false") ?? false,
        lastSeen: Int(queryResultItem.value["lastSeen"] as? String ?? "0") ?? 0,
        key: queryResultItem.value["key"] as? String ?? ""
    )
}


func getDateFromTimestamp(_ timestamp: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    formatter.locale = Locale.current
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    return formatter.string(from: date)
}
