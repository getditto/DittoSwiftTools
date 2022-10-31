//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation
import DittoSwift


class AuthDelegate: DittoAuthenticationDelegate {
    func authenticationRequired(authenticator: DittoAuthenticator) {
        let provider = DittoManager.shared.config.authenticationProvider
        let token = DittoManager.shared.config.authenticationToken
    
        DittoManager.shared.ditto!.auth?.loginWithToken(token, provider: provider, completion: { err in
            print("Error authenticating \(err?.localizedDescription)")
        })
    }

    func authenticationExpiringSoon(authenticator: DittoAuthenticator, secondsRemaining: Int64) {
        let provider = DittoManager.shared.config.authenticationProvider
        let token = DittoManager.shared.config.authenticationToken
        print("Auth token expiring in \(secondsRemaining)")
        DittoManager.shared.ditto!.auth?.loginWithToken(token, provider: provider, completion: { err in
            print("Error authenticating \(err?.localizedDescription)")
        })
    }
}

/// A singleton which manages our `Ditto` object.
class DittoManager: ObservableObject {

    // MARK: - Properties

    var ditto: Ditto? = Ditto()

    @Published var identityType = IdentityType.onlinePlayground
    @Published var config = DittoConfig(
        appID: "YOUR_APP_ID_HERE",
        playgroundToken: "YOUR_TOKEN_HERE",
        identityType: IdentityType.onlinePlayground,
        offlineLicenseToken: "YOUR_OFFLINE_LICENSE_HERE",
        authenticationProvider: "",
        authenticationToken: "",
        useIsolatedDirectories: true
    )
    @Published var colls = [DittoCollection]()

    // MARK: - Singleton

    /// Singleton instance. All access is via `DittoManager.shared`.
    static var shared = DittoManager()
    var collectionsObserver: DittoLiveQuery?
    var authDelegate = AuthDelegate()

    // MARK: - Private Constructor

    private init() {
        // make sure our log level is set _before_ starting ditto.
        DittoLogger.minimumLogLevel = AppSettings.shared.logLevel
        if let logFileURL = LogManager.shared.logFileURL {
            DittoLogger.setLogFileURL(logFileURL)
        }
    }

    func getPersistenceDir (config: DittoConfig) -> URL? {
        if (!config.useIsolatedDirectories) { return nil }
        print("Giving isolated directory")
        return topLevelDittoDir()
            .appendingPathComponent(config.appID)
            .appendingPathComponent(UUID().uuidString)
    }
    // MARK: - Functions

    func restartDitto() throws {
        self.ditto!.stopSync()
        self.ditto = nil
        let persistenceDir = getPersistenceDir(config: config)
    
        switch (self.identityType) {
        case IdentityType.onlinePlayground:
            self.ditto = Ditto(identity: .onlinePlayground(appID: self.config.appID, token: self.config.playgroundToken, persistenceDirectory: persistenceDir), persistenceDirectory: persistenceDir)
        case IdentityType.onlineWithAuthentication:
            self.ditto = Ditto(identity: .onlineWithAuthentication(appID: self.config.appID, authenticationDelegate: self.authDelegate, persistenceDirectory: persistenceDir), persistenceDirectory: persistenceDir)
        case IdentityType.offlinePlayground:
            self.ditto = Ditto(identity: .offlinePlayground(appID: self.config.appID, persistenceDirectory: persistenceDir), persistenceDirectory: persistenceDir)
            try self.ditto!.setOfflineOnlyLicenseToken(self.config.offlineLicenseToken)
        }

        self.ditto!.delegate = self
        let newConfig = DittoTransportConfig()
        for transport in AppSettings.shared.enabledTransports {
            switch transport {
            case .bluetooth:
                newConfig.peerToPeer.bluetoothLe.isEnabled = true
            case .wifi:
                newConfig.peerToPeer.lan.isEnabled = true
            case .awdl:
                newConfig.peerToPeer.awdl.isEnabled = true
            case .tcpServer:
                if let server = AppSettings.shared.selectedTCPServer {
                    newConfig.connect.tcpServers.add(server.urlString(formattedFor: .tcp))
                }
            case .websocketServer:
                if let server = AppSettings.shared.selectedWebsocketServer {
                    newConfig.connect.websocketURLs.add(server.urlString(formattedFor: .websocket))
                }
            }
        }
        ditto!.transportConfig = newConfig
        try ditto!.startSync()

        DispatchQueue.main.async {
            // Let the DittoManager finish getting created, then apply initial diagnostics setting
            DiagnosticsManager.shared.isEnabled = AppSettings.shared.diagnosticLogsEnabled
        }
        
        setupLiveQueries()
    }
    
    func setupLiveQueries () {
      self.collectionsObserver = DittoManager.shared.ditto?.store.collections().observe(eventHandler: { event in
         print("collections changed")
         self.colls = DittoManager.shared.ditto?.store.collections().exec() ?? []
       })
    }

}


// MARK: - DittoDelegate

extension DittoManager: DittoDelegate {

    func dittoTransportConditionDidChange(ditto: Ditto,
                                          condition: DittoTransportCondition,
                                          subsystem: DittoConditionSource) {
        print("Condition update from \(subsystem)")

        if condition == .BleDisabled {
            print("BLE disabled")
        } else if condition == .NoBleCentralPermission {
            print("Permission missing for BLE")
        } else if condition == .NoBlePeripheralPermission {
            print("Permission missing for BLE")
        } else if condition == .Ok {
            print("Ok")
        }
    }

    // Test code: currently frequently used by @thombles but otherwise not
    // called from anywhere.
    func dittoIdentityProviderAuthenticationRequest(ditto: Ditto, request: DittoAuthenticationRequest) {
        print("CarsApp: Authentication Request")

        if request.thirdPartyToken == "jellybeans" {
            let success = DittoAuthenticationSuccess()
            success.userID = "tom@ditto.live"
            success.accessExpires = Date().addingTimeInterval(3600)
            success.addWritePermission(forCollection: "test", queryString: "true")
            success.addReadPermission(forCollection: "test", queryString: "true")
            request.allow(success)
        } else {
            request.deny()
        }
    }
}

func topLevelDittoDir() -> URL {
    let fileManager = FileManager.default
    return try! fileManager.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ).appendingPathComponent("ditto_top_level")
}
