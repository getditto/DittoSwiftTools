///
//  HeartbeatView+Extensions.swift
//  
//
//  Created by Eric Turner on 2/22/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import DittoSwift
import SwiftUI

//MARK: View Extensions

public struct HeartbeatInfoView: View {
    let info: DittoHeartbeatInfo
    init(_ nfo: DittoHeartbeatInfo) { info = nfo }

    public var body: some View {
        VStack(alignment: .leading) {
            Text("\(String.id): \(info.id)")
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(String.secondsInterval): \(info.secondsInterval) sec")
            Text("\(String.lastUpdatedText): \(info.lastUpdated)")
            Text("\(String.metadata): \(info.metadataString)")
            Text("\(String.presenceSnapshotDirectlyConnectedPeersCount): \(info.presenceSnapshotDirectlyConnectedPeers.isEmpty ? 0 : info.presenceSnapshotDirectlyConnectedPeersCount)")
            if info.presenceSnapshotDirectlyConnectedPeersCount > 0 {
                Text("\(String.remotePeers):\n\(info.peersString)")
            }
            if !info.healthMetrics.isEmpty {
                Text("Health Metrics:\n")
                Text(info.healthMetrics.description)
            }
        }
    }
}

public struct HeartbeatInfoRowItem: View {
    let info: DittoHeartbeatInfo
    public var body: some View {
        HeartbeatInfoView(info)
    }
}



//MARK: Heartbeat Model View Extension

public extension DittoHeartbeatInfo {
    
    var metadataString: String {
        var retStr = ""
        let indent = "     "
        for key in Array(metadata.keys).sorted() {
            let val = metadata[key]
            let valStr = val as? String ?? String(describing: val)
            retStr += "\n\(indent)\(key): \(valStr)"
        }
        
        return retStr
    }
    
    var peersString: String {
        var str = ""
        for cx in presenceSnapshotDirectlyConnectedPeers.sorted(by: { $0.peerKey < $1.peerKey }) {
            str += "\(cx)\n"
        }
        return str
    }
}


//MARK: Heartbeat Model PeerConnection Extension

extension DittoPeerConnection: CustomStringConvertible {

    public var description: String {
        """
             \(String.deviceName): \(deviceName)
             \(String.sdk): \(sdk)
             \(String.isConnectedToDittoCloud): \(isConnectedToDittoCloud)
             \(String.bluetooth): \(bluetooth)
             \(String.p2pWifi): \(p2pWifi)
             \(String.lan): \(lan)
             \(String.peerKey): \(peerKey)
        """
    }
}

