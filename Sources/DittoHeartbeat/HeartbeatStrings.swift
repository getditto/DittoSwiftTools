///
//  HeartbeatStrings.swift
//
//
//  Created by Eric Turner on 2/22/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Foundation

public extension String {
    static var bt = "bt"
    static var bluetooth = "bluetooth"
    static var deviceName = "deviceName"
    static var deviceNameNA = "deviceName N/A"
    static var hbInfoTitle = "Heartbeat Info"
    static var _id = "_id"
    static var id = "id"
    static var imgPause = "pause.circle"
    static var imgPlay = "play.circle"
    static var isConnectedToDittoCloud = "isConnectedToDittoCloud"
    static var lan = "lan"
    static var lastUpdated = "lastUpdated"
    static var lastUpdatedText = "last updated"
    static var metadata = "metadata"
    static var NA = "N/A"
    static var osNA = "OS: N/A"
    static var p2pWifi = "p2pWifi"
    static var presenceSnapshotDirectlyConnectedPeers = "presenceSnapshotDirectlyConnectedPeers"
    static var pk = "pk"
    static var presenceSnapshotDirectlyConnectedPeersCount = "presenceSnapshotDirectlyConnectedPeersCount"
    static var remotePeers = "remote peers"
    static var secondsInterval = "secondsInterval"
    static var sdk = "sdk"
    static var sdkNA = "sdk N/A"
    static var sdkVersionNA = ": N/A"
    
    static var getStartedText = "To demo the Heartbeat feature, just hit the play button. "
    + "A hearbeat document for this device will be added to the `devices` collection, and mock "
    + "HeartbeatConfig data will be used to update the document every 10 seconds. "
    + "Hearbeat documents for this and other devices with the heartbeat feature enabled "
    + "will appear in a list here.\n\n"
    + "If using the standalone DittoToolsApp, you must first reset the identity to activate "
    + "Ditto. Note that every time the Ditto identity is reset in this way, the Ditto instance will "
    + "be seen as a new local peer and will create a new HeartbeatInfo document with a new unique ID."
}
