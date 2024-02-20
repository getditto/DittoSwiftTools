//
//  File.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import Foundation
import DittoSwift
import CryptoKit
import Combine

@available(iOS 15.0, *)
class PresenceDegradationVM: ObservableObject {
        
    @Published var expectedPeers: Int = 0
    @Published var apiEnabled: Bool = false
    @Published var sessionStartTime: String?
    @Published var isSheetPresented = true
    @Published var localPeer: Peer?
    @Published var remotePeers: [String:Peer]?
    @Published var settings: Settings?
    var ditto: Ditto
    var peersObserver: DittoObserver?

    init(ditto: Ditto) {
        self.ditto = ditto
    }
    
    func startNewSession() {
                
        if(peersObserver != nil) {
            self.peersObserver?.stop()
        }
        
        self.peersObserver = self.ditto.presence.observe { graph in
            DispatchQueue.main.async {
                let seenAt = Date()
                let localPeerTransportInfo = self.resolveTransportInfo(peer: graph.localPeer)
                
                self.localPeer = Peer(
                    name: graph.localPeer.deviceName,
                    transportInfo: localPeerTransportInfo,
                    connected: true,
                    lastSeen: Int(seenAt.timeIntervalSince1970),
                    key: self.hashPeerKeyUseCase(graph.localPeer.peerKey)
                )
                
                for peer in graph.remotePeers {
                    let hashedPeerKey = self.hashPeerKeyUseCase(peer.peerKey)
                    if var remotePeers = self.remotePeers {
                        remotePeers[hashedPeerKey] = Peer(
                            name: peer.deviceName,
                            transportInfo: self.resolveTransportInfo(peer: peer),
                            connected: true,
                            lastSeen: Int(seenAt.timeIntervalSince1970),
                            key: hashedPeerKey
                        )
                        self.remotePeers = remotePeers
                    } else {
                        self.remotePeers = [hashedPeerKey: Peer(
                            name: peer.deviceName,
                            transportInfo: self.resolveTransportInfo(peer: peer),
                            connected: true,
                            lastSeen: Int(seenAt.timeIntervalSince1970),
                            key: hashedPeerKey
                        )]
                    }
                }
                
                if let peers = self.remotePeers?.values {
                    for peer in peers {                    
                        if !graph.remotePeers.contains(where: { self.hashPeerKeyUseCase($0.peerKey) == peer.key}) {
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
    
    func hashPeerKeyUseCase(_ data: Data) -> String {
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func updateSettings() {
        var hasSeenExpectedPeers = false
        
        if(self.remotePeers?.count ?? 0 >= self.expectedPeers) {
            hasSeenExpectedPeers = true
        }
        
        self.settings = Settings(
            expectedPeers: self.expectedPeers,
            reportApiEnabled: self.apiEnabled,
            hasSeenExpectedPeers: hasSeenExpectedPeers,
            sessionStartedAt: self.sessionStartTime ?? ""
        )
    }
}


