///
//  HeartbeatModels.swift
//  
//
//  Created by Eric Turner on 2/22/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Foundation

//MARK: HeartbeatConfig
public struct DittoHeartbeatConfig {
    public var id: String
    public var secondsInterval: Int
    public var metadata: [String: Any]?
    
    public init(id: String, secondsInterval: Int, metadata: [String : Any]? = nil) {
        self.id = id
        self.secondsInterval = secondsInterval
        self.metadata = metadata
    }
}

//MARK: HeartbeatInfo
public struct DittoHeartbeatInfo: Identifiable {
    public var id: String
    public var schema: String
    public var peerKey: String
    public var secondsInterval: Int
    public var lastUpdated: String
    public var sdk: String
    public var presenceSnapshotDirectlyConnectedPeersCount: Int { presenceSnapshotDirectlyConnectedPeers.count }
    public var presenceSnapshotDirectlyConnectedPeers: [DittoPeerConnection]
    public var metadata: [String: Any]
    
    public init(
        id: String,
        schema: String,
        peerKey: String,
        secondsInterval: Int = Int.max,
        lastUpdated: String = DateFormatter.isoDate.string(from: Date()),
        sdk: String = "",
        presenceSnapshotDirectlyConnectedPeersCount: Int = 0,
        presenceSnapshotDirectlyConnectedPeers: [DittoPeerConnection] = [],
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.schema = schema
        self.peerKey = peerKey
        self.secondsInterval = secondsInterval
        self.lastUpdated = lastUpdated
        self.sdk = sdk
        self.presenceSnapshotDirectlyConnectedPeers = presenceSnapshotDirectlyConnectedPeers
        self.metadata = metadata
    }
}

public extension DittoHeartbeatInfo {
    init(_ resultItem: [String:Any?]) {
        id = resultItem[String._id] as? String ?? ""
        schema = resultItem[String._schema] as? String ?? ""
        peerKey = resultItem[String.pk] as? String ?? ""
        secondsInterval = resultItem[String.secondsInterval] as? Int ?? 0
        lastUpdated = resultItem[String.lastUpdated] as? String ?? String.NA
        sdk = resultItem[String.sdk] as? String ?? String.NA
        presenceSnapshotDirectlyConnectedPeers = Self.connections(resultItem[String.presenceSnapshotDirectlyConnectedPeers] as? [String:Any] ?? [:])
        metadata = resultItem[String.metadata] as? [String:Any] ?? [:]
    }
    
    fileprivate static func connections(_ cxs: [String:Any]) -> [DittoPeerConnection] {
        cxs.map { (key, val) in DittoPeerConnection(key, cx: val as! [String:Any]) }
    }
    
    var value: [String:Any] {
        [
            String._id: id,
            String._schema: schema,
            String.pk: peerKey,
            String.secondsInterval: secondsInterval,
            String.lastUpdated: lastUpdated,
            String.sdk: sdk,
            String.presenceSnapshotDirectlyConnectedPeersCount: presenceSnapshotDirectlyConnectedPeers.count,
            String.presenceSnapshotDirectlyConnectedPeers: connectionsValue(),
            String.metadata: metadata
        ]
    }
    
    fileprivate func connectionsValue() -> [String:Any] {
        var cxVal = [String:Any]()
        for cx in presenceSnapshotDirectlyConnectedPeers {
            cxVal[cx.peerKey] = cx.value
        }
        return cxVal
    }
}

//MARK: PeerConnection
public struct DittoPeerConnection {
    public var deviceName: String
    public var sdk: String
    public var isConnectedToDittoCloud: Bool
    public var bluetooth: Int
    public var p2pWifi: Int
    public var lan: Int
    public var peerKey: String
}

extension DittoPeerConnection {
    public init(_ key: String, cx: [String:Any]) {
        deviceName = cx[String.deviceName] as? String ?? String.deviceNameNA
        sdk = cx[String.sdk] as? String ?? String.sdkNA
        isConnectedToDittoCloud = cx[String.isConnectedToDittoCloud] as? Bool ?? false
        bluetooth = cx[String.bluetooth] as? Int ?? 0
        p2pWifi = cx[String.p2pWifi] as? Int ?? 0
        lan = cx[String.lan] as? Int ?? 0
        peerKey = key
    }
    
    public var value: [String:Any] {
        [
            String.deviceName: deviceName,
            String.sdk: sdk,
            String.isConnectedToDittoCloud: isConnectedToDittoCloud,
            String.bluetooth: bluetooth,
            String.p2pWifi: p2pWifi,
            String.lan: lan
            /* peerKey: not included in doc values */
        ]
    }
}


//MARK: HeartbeatConfig Mock
public extension DittoHeartbeatConfig {
    static var mock: DittoHeartbeatConfig {
        DittoHeartbeatConfig(
            id: UUID().uuidString,
            secondsInterval: 10,
            metadata: ["metadata-key1": "metadata-value1", "metadata-key2": "metadata-value2"]
        )
    }
}
