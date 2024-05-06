///
//  HeartbeatVM.swift
//  DittoSwiftTools
//
//  Created by Eric Turner on 02/01/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import CryptoKit
import DittoSwift
import DittoHealthMetrics
import SwiftUI


public typealias HeartbeatCallback = (DittoHeartbeatInfo) -> Void

@available(iOS 13, *)
public class HeartbeatVM: ObservableObject {
    @Published public var isEnabled = false
    private var hbConfig: DittoHeartbeatConfig?
    private var hbInfo: DittoHeartbeatInfo?
    private var hbCallback: HeartbeatCallback?
    private var hbSubscription: DittoSyncSubscription?
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
            id: config.id,
            schema: String._schemaValue,
            peerKey: ditto.presence.graph.localPeer.peerKeyString,
            secondsInterval: config.secondsInterval,
            sdk: ditto.presence.graph.localPeer.platformSDK,
            metadata: config.metadata ?? [:]
        )
        observePeers()
        startTimer()
        
        hbSubscription = try? ditto.sync.registerSubscription(query: "SELECT * FROM \(String.collectionName)")
    }
    
    public func stopHeartbeat() {
        stopTimer()
        isEnabled = false
        peersObserver?.stop()
        hbSubscription?.cancel()
    }

    private func updateHealthMetrics() {
        guard var hbInfo = hbInfo,
            let hbConfig = hbConfig else { return }
        var newHealthMetrics: [String: HealthMetric] = [:]
        hbConfig.healthMetricProviders.forEach { provider in
            newHealthMetrics[provider.metricName] = provider.getCurrentState()
        }
        hbInfo.healthMetrics = newHealthMetrics
    }

    private func startTimer() {
        guard let config = hbConfig else {
            print("HeartbeatVM.\(#function): config is NIL --> Return")
            return
        }
        
        timer?.connect().cancel()
        timer = Timer.publish(every: TimeInterval(config.secondsInterval), on: .main, in: .common)

        cancellable = timer!
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink {[weak self] date in
                guard let self = self else { return }
                updateHealthMetrics()
                hbInfo?.lastUpdated = DateFormatter.isoDate.string(from: Date())
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
                hbInfo?.presenceSnapshotDirectlyConnectedPeers = connections()
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
        
        do {
            let _ = try ditto.store.collection(String.collectionName).upsert(doc)
        } catch {
            print(
                "HeartbeatVM.\(#function) - ERROR updating collection: " +
                "\(String.collectionName)\n" +
                "error: \(error.localizedDescription)"
            )
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
                peerKey: peer.peerKeyString
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
