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
                self?.peers = graph.remotePeers
            }
        }
    }
    
    func isLocalPeer(_ peer: DittoPeer) -> Bool {
        peer.peerKey == localPeer.peerKey
    }
    
    func connectionsWithLocalPeer(_ peer: DittoPeer) -> [DittoConnection] {
        peer.connections.filter { $0.peer1 == localPeer.peerKey || $0.peer2 == localPeer.peerKey }
    }

    func formattedDistanceString(_ dbl: Double?) -> String {
        Double.metricString(dbl ?? 0, digits: 2)
    }
    
    func cleanup() {
        peersObserver?.stop()
    }
    
//    deinit {
//        print("PeersObserverVM -- deinit -- ")
//    }
}

extension DittoPeer {
    var peerSDKVersion: String {
        let sdk = "SDK "
        if let version = dittoSDKVersion {
            return sdk + "v\(version)"
        }
        return sdk + "N/A"
    }
        
    var addressSiteId: String {
        Self.addressSiteId(self)
    }
    
    static func addressSiteId(_ peer: DittoPeer) -> String {
        // parse siteID out of DittoAddress description
        let prefix = "\(peer.address)".components(separatedBy: "DittoAddress(siteID: ")
        let addr = String(prefix.last ?? "").components(separatedBy: ",")
        return String(addr.first ?? "[siteID N/A]")
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
