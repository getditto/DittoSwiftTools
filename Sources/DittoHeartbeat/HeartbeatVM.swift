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

public class HeartbeatVM: ObservableObject {
    @Published public var isEnabled = false
    private var hbConfig: DittoHeartbeatConfig?
    private var hbInfo: DittoHeartbeatInfo?
    private var hbCallback: HeartbeatCallback?
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
            peerKey: ditto.presence.graph.localPeer.peerKey,
            secondsInterval: config.secondsInterval,
            sdk: ditto.presence.graph.localPeer.platformSDK,
            metadata: config.metadata ?? [:]
        )
        observePeers()
        startTimer()
    }
    
    public func stopHeartbeat() {
        stopTimer()
        isEnabled = false
        peersObserver?.stop()
    }

    private func updateHealthMetrics() {
        guard let hbConfig = hbConfig else { return }
        var newHealthMetrics: [String: HealthMetric] = [:]
        hbConfig.healthMetricProviders.forEach { provider in
            newHealthMetrics[provider.metricName] = provider.getCurrentState()
        }
        hbInfo?.healthMetrics = newHealthMetrics
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
                hbInfo?.lastUpdated = HeartbeatDateFormatter.isoDate.string(from: Date())
                Task { await self.updateCollection() }
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
    
    private func updateCollection() async {
        guard hbConfig?.publishToDittoCollection == true else { return }
        guard let doc = hbInfo?.value else {
            print("DittoHeartbeatVM.\(#function): ERROR updatingCollection: bhInfo is NIL --> Return")
            return
        }

        do {
            _ = try await ditto.store.execute(
                query: "INSERT INTO \(String.collectionName) DOCUMENTS (:doc) ON ID CONFLICT DO UPDATE",
                arguments: ["doc": doc]
            )
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
            let connectionTypes = HeartbeatConnectionTypes.count(
                peer.connections.map { $0.type.rawValue }
            )
            let cx = DittoPeerConnection(
                deviceName: peer.deviceName,
                sdk: peer.platformSDK,
                isConnectedToDittoCloud: peer.isConnectedToDittoServer,
                bluetooth: connectionTypes[DittoConnectionType.bluetooth.rawValue, default: 0],
                p2pWifi: connectionTypes[DittoConnectionType.p2pWiFi.rawValue, default: 0],
                // The SDK enum calls LAN `accessPoint`. WebSocket is a
                // separate transport in the open-ended connectionTypes map.
                lan: connectionTypes[DittoConnectionType.accessPoint.rawValue, default: 0],
                connectionTypes: connectionTypes,
                peerKey: peer.peerKey
            )
            connections.append(cx)
        }
        return connections
    }

}

enum HeartbeatConnectionTypes {
    static func count<S: Sequence>(_ names: S) -> [String: Int] where S.Element == String {
        names.reduce(into: [:]) { counts, name in
            counts[name, default: 0] += 1
        }
    }
}


//MARK: Extensions
private extension DittoPeer {
    var platformSDK: String {
        let platform = self.os ?? .unknown(os: String.osNA)
        let sdk = self.dittoSDKVersion ?? String.sdkVersionNA
        return "\(platform.stringValue) v\(sdk)"
    }
}

public struct HeartbeatDateFormatter {
    public static var isoDate: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
}
