///
//  HeartbeatVM.swift
//  DittoChat
//
//  Created by Eric Turner on 02/01/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import CryptoKit
import DittoSwift
import SwiftUI

public extension DateFormatter {
    static var isoDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        return f
    }
}

public struct HeartbeatConfig {
    var id: [String: String]
    var interval: TimeInterval
    var collectionName: String
}

public struct HeartbeatInfo {
    var id: [String: String]
    var lastUpdated: String
    var presence: Presence?
}

public struct Presence {
    var peers: [DittoPeer]
    var remotePeersCount: Int
    init(peers: [DittoPeer], remoteCount: Int) {
        self.peers = peers
        self.remotePeersCount = remoteCount
    }
}

public typealias HeartbeatCallback = (HeartbeatInfo) -> Void

@available(iOS 15, *)
public class HeartbeatVM: ObservableObject {
    @Published var isEnabled = false
    private var hbConfig: HeartbeatConfig?
    private var hbInfo: HeartbeatInfo?
    private var hbCallback: HeartbeatCallback?
    private var hbSubscription: DittoSyncSubscription?
    private var insertQuery: String?
    private var ditto: Ditto?
    private var presence: Presence?
    private var peersObserver: DittoSwift.DittoObserver?
    private var timer: Timer.TimerPublisher?
    private var cancellable = AnyCancellable({})
    private var infoCurrentValueSubject = CurrentValueSubject<HeartbeatInfo?, Never>(nil)
    private var subjectCancellable = AnyCancellable({})
    public var infoPublisher: AnyPublisher<HeartbeatInfo?, Never> {
        infoCurrentValueSubject.eraseToAnyPublisher()
    }
    
    //TEST
    var testObserver: DittoStoreObserver?

    
    public init(ditto: Ditto? = nil) {
        self.ditto = ditto
    }
    
    public func startHeartbeat(ditto: Ditto, config: HeartbeatConfig, callback: @escaping HeartbeatCallback) {
        self.ditto = ditto
        isEnabled = true
        hbConfig = config
        hbCallback = callback
        hbInfo = HeartbeatInfo(
            id: createCompositeId(config: config.id),
            lastUpdated: DateFormatter.isoDate.string(from: Date.now),
            presence: nil
        )
        observePeers()
        startTimer()
        
        hbSubscription = try? ditto.sync.registerSubscription(query: "SELECT * FROM \(config.collectionName)")
        insertQuery = "INSERT INTO \(config.collectionName) DOCUMENTS (:doc) ON ID CONFLICT DO UPDATE"
    }
    
    public func stopHeartbeat() {
        stopTimer()
        isEnabled = false
        peersObserver?.stop()
        hbSubscription?.cancel()
    }
    
    private func startTimer() {
        guard let config = hbConfig else {
            print("HeartbeatVM.\(#function): config is NIL --> Return")
            return
        }
        
        timer?.connect().cancel()
        timer = Timer.publish(every: config.interval, on: .main, in: .common)
        
        cancellable = timer!
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink {[weak self] date in
                guard let self = self else { return }
                hbInfo?.lastUpdated = DateFormatter.isoDate.string(from: Date.now)
                updateCollection()
                emit()
            }
    }
    
    private func stopTimer() {
        timer?.connect().cancel()
        timer = nil
    }
    
    private func observePeers() {
        guard isEnabled else { return }
        
        peersObserver = ditto?.presence.observe {[weak self] graph in
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                let peers = graph.remotePeers
                presence = Presence(peers: peers, remoteCount: peers.count)
                hbInfo?.presence = presence
            }
        }
    }
    
    private func emit() {
        infoCurrentValueSubject.send(hbInfo)
        
        if let callback = hbCallback, let info = hbInfo {
            callback(info)
        }
    }
    
    private func updateCollection() {
        guard let config = hbConfig, let info = hbInfo, let presence = info.presence else {
            print("HeartbeatVM.\(#function): hbConfig and/or bhInfo and/or hbInfo.presence is NIL --> Return")
            return
        }
        
        let doc: [String:Any?] = [
            "_id": info.id,
            "interval": "\(Int(config.interval)) sec",
            "remotePeersCount": presence.remotePeersCount,
            "lastUpdated": info.lastUpdated,
            "presence": getConnections()
        ]
        Task {
            do {
                if let query = insertQuery {
                    try await ditto?.store.execute(query: query, arguments: ["doc": doc])
                } else {
                    print("HeartbeatVM.\(#function): ERROR: insertQuery should not be NIL")
                }
            } catch {
                print(
                    "HeartbeatVM.\(#function) - ERROR updating collection: " +
                    "\(hbConfig?.collectionName ?? "collection name N/A")\n" +
                    "error: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func getConnections() -> [String: Any?] {
        guard let info = hbInfo, let presence = info.presence else {
            print("HeartbeatVM.\(#function): bhInfo and/or hbInfo.presence is NIL --> Return")
            return [:]
        }
        
        var connections = [String: Any]()
        
        for peer in presence.peers {
            let types = connectionTypeCounts(peer: peer)
            let connection: [String: Any?] =
            [
                "deviceName": peer.deviceName,
                "isConnectedToDittoCloud": peer.isConnectedToDittoCloud,
                "bluetooth": types["bt"],
                "p2pWifi": types["p2pWifi"],
                "lan": types["lan"]
            ]
            
            connections["dittoPeerKey"] = connection
        }
        
        return connections
    }
    
    private func connectionTypeCounts(peer: DittoPeer) -> [String: Int] {
        var bt = 0
        var wifi = 0
        var lan = 0
        
        for cx in peer.connections {
            switch cx.type {
            case .bluetooth: bt += 1
            case .p2pWiFi: wifi += 1
            case .accessPoint, .webSocket: lan += 1
            @unknown default:
                break
            }
        }
        return ["bt": bt, "p2pWifi": wifi, "lan": lan]
    }
    
    private func createCompositeId(config: [String: String]) -> [String: String] {
        var compositeId = config
        compositeId["dittoPeerKey"] = peerKeyHash(ditto?.presence.graph.localPeer.peerKey ?? Data())
        return compositeId
    }
    
    private func peerKeyHash(_ data: Data) -> String {
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
    
    //TMP: for HeartbeatView
    public var peers: [DittoPeer] {
        hbInfo?.presence?.peers ?? []
    }
    
    /* from orig */
    func isLocalPeer(_ peer: DittoPeer) -> Bool {
        //        peer.peerKey == localPeer.peerKey
        guard let presence = ditto?.presence else { return false }
        return peer.peerKey == presence.graph.localPeer.peerKey
    }
    
    func connectionsWithLocalPeer(_ peer: DittoPeer) -> [DittoConnection] {
        //        peer.connections.filter { $0.peer1 == localPeer.peerKey || $0.peer2 == localPeer.peerKey }
        guard let presence = ditto?.presence else { return [] }
        let localPeer = presence.graph.localPeer
        return peer.connections.filter { $0.peer1 == localPeer.peerKey || $0.peer2 == localPeer.peerKey }
    }
    
    func formattedDistanceString(_ dbl: Double?) -> String {
        Double.metricString(dbl ?? 0, digits: 2)
    }
    
    func cleanup() {
        peersObserver?.stop()
    }
}

@available(iOS 15, *)
extension HeartbeatVM {
    public func test(ditto: Ditto) {
        startHeartbeat(ditto: ditto, config: HeartbeatConfig.mock) { [weak self] info in
            guard let self = self else { return }
            if testObserver == nil {
               startTestObserver()
            }
            print("HeartbeatVM.\(#function): info.presence.peersCount: \(info.presence?.remotePeersCount ?? -1)")
        }
    }
    func startTestObserver() {
        testObserver = try? ditto!.store.registerObserver(
            query: hbSubscription!.queryString,
            arguments: hbSubscription!.queryArguments
        ) { result in
            let _ = result.items.compactMap { print("Heartbeat query item: \($0.value)") }
        }
    }
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

@available(iOS 15, *)
//public extension HeartbeatVM {
////    func test(ditto: Ditto, config: HeartbeatConfig, callback: HeartbeatCallback) {
//    func test(ditto: Ditto) {
//        startHeartbeat(ditto: ditto, config: HeartbeatConfig.mock) { info in
//            print("HeartbeatVM.\(#function): info:\n\(info)")
//        }
//    }
//}
extension HeartbeatConfig {
    static var mock: HeartbeatConfig {
        HeartbeatConfig(
            id: ["location": "loc_abc123", "venue": "ven_def456"],
            interval: 10,
            collectionName: "devices"
        )
    }
}
