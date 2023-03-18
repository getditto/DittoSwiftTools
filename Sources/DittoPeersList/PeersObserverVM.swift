///
//  PeersObserverVM.swift
//  DittoChat
//
//  Created by Eric Turner on 3/7/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI

@available(iOS 15, *)
@MainActor public class PeersObserverVM: ObservableObject {
    @Published var peers: [DittoPeer]
    @Published var localPeer: DittoPeer
    @Published var isPaused = false
    private var peersObserver: DittoSwift.DittoObserver? = nil
    private let ditto: Ditto

    public init(ditto: Ditto) {
        self.ditto = ditto
        self.peers = [DittoPeer]()
        self.localPeer = ditto.presence.graph.localPeer
        observePeers()
    }
    
    public func observePeers() {
        peersObserver = ditto.presence.observe {[weak self] graph in
            guard self?.isPaused == false else { return }
            DispatchQueue.main.async {
                self?.localPeer = graph.localPeer
                
//                let oldPeers = self?.peers
                self?.peers.removeAll()
                for peer in graph.remotePeers {

                    if !(self?.peers.contains(where: { $0.address == peer.address }) ?? false) {
                        self?.peers.append(peer)
                    }
                }
                
                /* debug print
                if oldPeers != self?.peers {
                    DispatchQueue.main.async {
                        print("DittoService.\(#function): peers changed:\n\(self?.peers ?? [])")
                    }
                }
                 */
            }
        }
    }
    
    func remotePeerAddresses(for peer: DittoPeer, in conxs: [DittoConnection]) -> [DittoAddress] {
        let uniqueAddresses = Set<DittoAddress>(
            conxs.map { remotePeerAddress(for: peer.address, in: $0) }
        )
        return Array(uniqueAddresses).sorted()
    }
    
    func remotePeerAddress(for addr: DittoAddress, in conx: DittoConnection) -> DittoAddress {
        addr == conx.peer1 ? conx.peer2 : conx.peer1
    }
    
    func remotePeerSiteId(for addr: DittoAddress, in conx: DittoConnection) -> String {
        return siteId(for: remotePeerAddress(for: addr, in: conx))
    }
    
    func connectionTypes(for addr: DittoAddress, in conxs: [DittoConnection]) -> [DittoConnection] {
        conxs.filter { $0.peer1 == addr || $0.peer2 == addr }
    }
    
    // parse siteID out of DittoAddress description
    func siteId(for peerAddress: DittoSwift.DittoAddress) -> String {
        let prefix = "\(peerAddress)".components(separatedBy: "DittoAddress(siteID: ")
        let addr = String(prefix.last ?? "").components(separatedBy: ",")
        return String(addr.first ?? "[siteID N/A]")
    }
    
    func peerSDKVersion(_ peer: DittoPeer) -> String {
        let sdk = "SDK "
        if let version = peer.dittoSDKVersion {
            return sdk + "v\(version)"
        }
        return sdk + "N/A"
    }
    
    func formattedDistanceString(_ dbl: Double?) -> String {
        Double.metricString(dbl ?? 0, digits: 2)
    }
    
    func cleanup() {
        peersObserver?.stop()
    }
    
    deinit {
//        print("PeersObserverVM -- deinit -- ")
    }
}

// For sorting addresses of remote peers in func remotePeerAddresses() above
extension DittoAddress: Comparable {
    public static func < (lhs: DittoSwift.DittoAddress, rhs: DittoSwift.DittoAddress) -> Bool {
        lhs.hashValue < rhs.hashValue
    }
}

extension Double {
    private static var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }

    static func metricString(_ dbl: Double, digits: Int) -> String {
        let formatter = Self.decimalFormatter
        formatter.maximumFractionDigits = digits
        return formatter.string(from: dbl as NSNumber) ?? "N/A"
    }
}
