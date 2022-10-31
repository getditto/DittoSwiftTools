//
//  DittoPresenceViewerExampleApp.swift
//  DittoPresenceViewerExample
//
//  Created by Ben Chatelain on 10/1/22.
//

import DittoPresenceViewer
import DittoSwift
import SwiftUI

@main
struct DittoPresenceViewerExampleApp: App {
    let ditto: Ditto
    let appID = "YOUR_APP_ID_HERE"
    let playgroundToken = "YOUR_TOKEN_HERE"

    init() {
        let identity: DittoIdentity = .onlinePlayground(appID: appID, token: playgroundToken)
        ditto = Ditto(identity: identity)
        try! ditto.startSync()
    }

    var body: some Scene {
        PresenceView(ditto: ditto)
    }
}
