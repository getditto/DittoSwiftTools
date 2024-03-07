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


public typealias HeartbeatCallback = (DittoHeartbeatInfo) -> Void

@available(iOS 15, *)
public class HeartbeatVM: ObservableObject {
    @Published var isEnabled = false
    private var hbConfig: DittoHeartbeatConfig?
    private var hbInfo: DittoHeartbeatInfo?
    private var hbCallback: HeartbeatCallback?
    private var hbSubscription: DittoSyncSubscription?
    private var insertQuery: String?
    private var ditto: Ditto
    private var peers = [DittoPeer]()
    private var peersObserver: DittoSwift.DittoObserver?
    private var timer: Timer.TimerPublisher?
    private var cancellable = AnyCancellable({})
    private var infoCurrentValueSubject = CurrentValueSubject<DittoHeartbeatInfo?, Never>(nil)
    private var subjectCancellable = AnyCancellable({})
    public var infoPublisher: AnyPublisher<DittoHeartbeatInfo?, Never> {
        infoCurrentValueSubject.eraseToAnyPublisher()
    }

    public init(ditto: Ditto) {
        self.ditto = ditto
    }
    
    public func startHeartbeat(config: DittoHeartbeatConfig, callback: @escaping HeartbeatCallback) {
        isEnabled = true
        hbConfig = config
        hbCallback = callback
        hbInfo = DittoHeartbeatInfo(
            id: createCompositeId(configId: config.id),
            secondsInterval: config.secondsInterval,
            metadata: config.metadata ?? [:]
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
        timer = Timer.publish(every: Double(config.secondsInterval), on: .main, in: .common)
        
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

        peersObserver = ditto.presence.observe {[weak self] graph in
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                peers = graph.remotePeers
                hbInfo?.peerConnections = connections()
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
        guard let doc = hbInfo?.value else {
            print("DittoHeartbeatVM.\(#function): ERROR updatingCollection: bhInfo is NIL --> Return")
            return
        }
        
        Task {
            do {
                if let query = insertQuery {
                    try await ditto.store.execute(query: query, arguments: ["doc": doc])
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
    
    private func connections() -> [DittoPeerConnection] {
        var connections = [DittoPeerConnection]()
        for peer in self.peers {
            let types = connectionTypeCounts(peer: peer)
            let cx = DittoPeerConnection(
                deviceName: peer.deviceName,
                sdk: peer.platformSDK,
                isConnectedToDittoCloud: peer.isConnectedToDittoCloud,
                bluetooth: types[String.bt] as Int? ?? 0,
                p2pWifi: types[String.p2pWifi] as Int? ?? 0,
                lan: types[String.lan] as Int? ?? 0,
                peerKey: peerKeyHash(peer.peerKey)
            )
            connections.append(cx)
        }
        return connections
    }

    private func connectionTypeCounts(peer: DittoPeer) -> [String: Int] {
        var bt = 0, wifi = 0, lan = 0
        
        for cx in peer.connections {
            switch cx.type {
            case .bluetooth: bt += 1
            case .p2pWiFi: wifi += 1
            case .accessPoint, .webSocket: lan += 1
            @unknown default:
                break
            }
        }
        return [String.bt: bt, String.p2pWifi: wifi, String.lan: lan]
    }
    
    private func createCompositeId(configId: [String: String]) -> [String: String] {
        var compositeId = configId
        compositeId[String.pk] = localPeerKeyString
        return compositeId
    }
    
    private var localPeerKeyString: String {
        peerKeyHash(ditto.presence.graph.localPeer.peerKey)
    }
    
    private func peerKeyHash(_ data: Data) -> String {
        "\(String.pk)\(data.base64EncodedString())"
    }
}


//MARK: Extensions
private extension DittoPeer {
    var platformSDK: String {
        let platform = self.os ?? String.osNA
        let sdk = self.dittoSDKVersion ?? String.sdkVersionNA
        return "\(platform) v\(sdk)"
    }
}

public extension DateFormatter {
    static var isoDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        return f
    }
}


