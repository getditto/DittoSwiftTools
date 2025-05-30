//
//  PresenceDegradationVM.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import Foundation
import DittoSwift
import CryptoKit
import Combine

class PresenceDegradationVM: ObservableObject {
        
    @Published var expectedPeers: String = ""
    @Published var apiEnabled: Bool = false
    @Published var sessionStartTime: String?
    @Published var isNewSessionView = true
    @Published var localPeer: Peer?
    @Published var remotePeers: [String:Peer]?
    @Published var settings: Settings?
    var ditto: Ditto
    var peersObserver: DittoObserver?
    
    var expectedPeersInt: Int {
        Int(expectedPeers) ?? 0
    }

    init(ditto: Ditto) {
        self.ditto = ditto
    }
    
    func startNewSession() {
                
        self.peersObserver?.stop()
        
        self.peersObserver = self.ditto.presence.observe { graph in
            DispatchQueue.main.async {
                let seenAt = Date()
                let localPeerTransportInfo = self.resolveTransportInfo(peer: graph.localPeer)
                
                self.localPeer = Peer(
                    name: graph.localPeer.deviceName,
                    transportInfo: localPeerTransportInfo,
                    connected: true,
                    lastSeen: Int(seenAt.timeIntervalSince1970),
                    key: graph.localPeer.peerKeyString
                )
                
                for peer in graph.remotePeers {
                    if var remotePeers = self.remotePeers {
                        remotePeers[peer.peerKeyString] = Peer(
                            name: peer.deviceName,
                            transportInfo: self.resolveTransportInfo(peer: peer),
                            connected: true,
                            lastSeen: Int(seenAt.timeIntervalSince1970),
                            key: peer.peerKeyString
                        )
                        self.remotePeers = remotePeers
                    } else {
                        self.remotePeers = [peer.peerKeyString: Peer(
                            name: peer.deviceName,
                            transportInfo: self.resolveTransportInfo(peer: peer),
                            connected: true,
                            lastSeen: Int(seenAt.timeIntervalSince1970),
                            key: peer.peerKeyString
                        )]
                    }
                }
                
                if let peers = self.remotePeers?.values {
                    for peer in peers {                    
                        if !graph.remotePeers.contains(where: { $0.peerKeyString == peer.key}) {
                            self.remotePeers?[peer.key]?.connected = false
                        }
                    }
                }
            }
        }
        
        self.updateSettings()
    }

    func resolveTransportInfo(peer: DittoPeer) -> PeerTransportInfo {
        let lanSet: Set<DittoConnectionType> = [.accessPoint, .webSocket]

        let connections = peer.connections.map{ $0.type }
        let bluetoothConnections = connections.filter { $0 == DittoConnectionType.bluetooth }.count
        let lanConnections = connections.filter { lanSet.contains($0) }.count
        let p2pConnections = connections.filter { $0 == DittoConnectionType.p2pWiFi }.count
        let cloudConnections = peer.isConnectedToDittoCloud ? 1 : 0
        
        return PeerTransportInfo(
            bluetoothConnections: bluetoothConnections,
            lanConnections: lanConnections,
            p2pConnections: p2pConnections,
            cloudConnections: cloudConnections
        )
    }
    
    func updateSettings() {
        var hasSeenExpectedPeers = false
        
        if(self.remotePeers?.count ?? 0 >= expectedPeersInt) {
            hasSeenExpectedPeers = true
        }
        
        self.settings = Settings(
            expectedPeers: self.expectedPeersInt,
            reportApiEnabled: self.apiEnabled,
            hasSeenExpectedPeers: hasSeenExpectedPeers,
            sessionStartedAt: self.sessionStartTime ?? ""
        )
    }
}


