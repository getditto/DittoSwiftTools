//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation

#if DEBUG

// MARK: Mock Data Interface

struct MockData {

    // MARK: Static Functions

    static func runFrequentConnectionChanges(callback: @escaping (String) -> Void) {
        let numPeers = 5

        func generator(lastState: PresenceUpdate?) -> PresenceUpdate {
            let peers = (0...numPeers).map { (site: Int) in Peer.init(siteId: site) }

            let conns = (0...(numPeers - 1)).flatMap { site1 in
                ((site1+1)...numPeers).map { site2 in
                    Connection.init(from: site1, to: site2, type: ConnectionType.random())
                }
            }

            return PresenceUpdate(localPeer: "0", peers: peers, connections: conns)
        }

        let startingState = generator(lastState: nil)
        Self.runChanges(lastState: startingState, generator: generator, callback: callback)
    }

    static func runFrequentRSSIChanges(callback: @escaping (String) -> Void) {
        let numPeers = 5

        func generator(lastState: PresenceUpdate?) -> PresenceUpdate {
            let peers = (0...numPeers).map { (site: Int) in Peer.init(siteId: site) }

            let conns = (0...(numPeers - 1)).flatMap { site1 in
                ((site1 + 1)...numPeers).map { site2 in
                    Connection.init(from: site1, to: site2, type: .bluetooth)
                }
            }

            return PresenceUpdate(localPeer: "0", peers: peers, connections: conns)
        }

        let startingState = generator(lastState: nil)
        Self.runChanges(lastState: startingState, generator: generator, callback: callback)
    }

    static func runLargeMesh(callback: @escaping (String) -> Void) {
        Self.runDynamicMesh(numPeers: 10, connectivity: 4, callback: callback)
    }

    static func runMassiveMesh(callback: @escaping (String) -> Void) {
        Self.runDynamicMesh(numPeers: 50, connectivity: 4, callback: callback)

    }

    // MARK: Private Static Functions

    static func runDynamicMesh(numPeers: Int, connectivity: Int, callback: @escaping (String) -> Void) {
        let percentConnectionsChange = 0.2

        func generator(lastState: PresenceUpdate?) -> PresenceUpdate {
            if let lastState = lastState {
                let numChanges = Int(Double(numPeers) * percentConnectionsChange)
                var newUpdate = lastState

                let connectionsToRemove = lastState
                    .connections
                    .shuffled()
                    .prefix(numChanges)
                    .map { $0.id }
                let connectionsToAdd = (0...(numChanges - 1))
                    .map { _ in Connection(from: .random(in: 0...numPeers), to: .random(in: 0...numPeers), type: .random()) }

                newUpdate.connections = lastState.connections.filter { !connectionsToRemove.contains($0.id) }
                newUpdate.connections += connectionsToAdd

                return newUpdate
            } else {
                let peers = (0...numPeers).map { (site: Int) in Peer.init(siteId: site) }
                let conns = (0...(numPeers - 1)).flatMap { site1 in
                    ((site1 + 1)...numPeers).shuffled().prefix(.random(in: 0...connectivity)).map { site2 in
                        Connection.init(from: site1, to: site2, type: .random())
                    }
                }
                return PresenceUpdate(localPeer: "0", peers: peers, connections: conns)
            }
        }

        let startingState = generator(lastState: nil)
        Self.runChanges(lastState: startingState, generator: generator, callback: callback)
    }

    private static func runChanges(lastState: PresenceUpdate,
                                   generator: @escaping (PresenceUpdate?) -> PresenceUpdate,
                                   callback: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let newState = generator(lastState)

            callback(String.init(data: try! JSONEncoder().encode(newState), encoding: .utf8)!)

            runChanges(lastState: newState, generator: generator, callback: callback)
        }
    }

}

// MARK: Private Types

private func specialChar(_ index: Int) -> String {
    let chars = ["'", "`", "\"", "😄", "👍🏾", "<"]
    return chars[index % chars.count]
}

private struct PresenceUpdate: Codable {
    let localPeer: String
    var peers: [Peer]
    var connections: [Connection]
}

private struct Peer: Codable {
    let id: Int
    let siteId: String
    let deviceName: String
    let os: Os
    let isHydraConnected: Bool
    let dittoSdkVersion: String

    init(siteId: Int) {
        self.id = siteId // Usually a separate network Id - but this is just mock data.
        self.siteId = "\(siteId)"
        self.deviceName = "Device \(specialChar(siteId)) \(siteId)"
        self.os = Os.generate(index: siteId)
        self.isHydraConnected = siteId % 2 == 1
        self.dittoSdkVersion = "1.0.\(siteId)"
    }
}

private enum Os: String, CaseIterable, Codable {
    case generic = "Generic"
    case iOS = "iOS"
    case android = "Android"
    case linux = "Linux"
    case windows = "Windows"
    case macOS = "macOS"

    /// Deterministic generator
    static func generate(index: Int) -> Self {
        return Self.allCases[index % Self.allCases.count]
    }

    /// Random generator
    static func random() -> Self {
        return Self.allCases.randomElement()!
    }
}

private struct Connection: Codable {
    let id: String
    let from: Int
    let to: Int
    let connectionType: ConnectionType
    let approximateDistanceInMeters: Double?

    init(from: Int, to: Int, type: ConnectionType) {
        let distance = (type == .bluetooth && Bool.random())
            ? Double.random(in: 1.0...6.0)
            : nil

        self.id = "\(from)<->\(to):\(type)"
        self.from = from
        self.to = to
        self.connectionType = type
        self.approximateDistanceInMeters = distance
    }
}

private enum ConnectionType: String, CaseIterable, Codable {
    case bluetooth = "Bluetooth"
    case accessPoint = "AccessPoint"
    case p2pWiFi = "P2PWiFi"
    case webSocket = "WebSocket"

    /// Deterministic generator
    static func generate(index: Int) -> Self {
        return Self.allCases[index % Self.allCases.count]
    }

    /// Random generator
    static func random() -> Self {
        Self.allCases.randomElement()!
    }

}

#endif
