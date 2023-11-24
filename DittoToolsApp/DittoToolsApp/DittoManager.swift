//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoExportLogs
import DittoSwift
import Foundation

class AuthDelegate: DittoAuthenticationDelegate {
    func authenticationRequired(authenticator: DittoAuthenticator) {
        let provider = DittoManager.shared.config.authenticationProvider
        let token = DittoManager.shared.config.authenticationToken
        print("login with \(token), \(provider)")    
        authenticator.login(token: token, provider: provider) { json, err in
            print("Error authenticating \(String(describing: err?.localizedDescription))")
        }
    }

    func authenticationExpiringSoon(authenticator: DittoAuthenticator, secondsRemaining: Int64) {
        let provider = DittoManager.shared.config.authenticationProvider
        let token = DittoManager.shared.config.authenticationToken
        print("Auth token expiring in \(secondsRemaining)")
        authenticator.login(token: token, provider: provider) { json, err in
            print("Error authenticating \(String(describing: err?.localizedDescription))")
        }
    }
}

struct DittoStartError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}

/// A singleton which manages our `Ditto` object.
class DittoManager: ObservableObject {

    // MARK: - Properties

    var ditto: Ditto? = Ditto()

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
    @Published var loggingOption: DittoLogger.LoggingOptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Singleton

    /// Singleton instance. All access is via `DittoManager.shared`.
    static var shared = DittoManager()
    var collectionsObserver: DittoLiveQuery?
    var collectionsSubscription: DittoSubscription?
    var authDelegate = AuthDelegate()

    // MARK: - Private Constructor

    private init() {
        self.loggingOption = AppSettings.shared.loggingOption
        
        // make sure log level is set _before_ starting ditto
        $loggingOption
            .sink {[weak self] option in
                AppSettings.shared.loggingOption = option
                self?.setupLogging()
            }
            .store(in: &cancellables)
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
        self.ditto?.stopSync()
        self.ditto = nil
        let persistenceDir = getPersistenceDir(config: config)
    
        // make sure our log level is set _before_ starting ditto.
        setupLogging()

        switch (self.config.identityType) {
        case IdentityType.onlinePlayground:
            let appID = UUID(uuidString: self.config.appID)
            let token = UUID(uuidString: self.config.playgroundToken)
            if (appID == nil || token == nil) {
                throw DittoStartError("AppID and Token are not valid UUIDs.")
            }
            self.ditto = Ditto(identity: .onlinePlayground(appID: self.config.appID, token: self.config.playgroundToken), persistenceDirectory: persistenceDir)
        case IdentityType.onlineWithAuthentication:
            self.authDelegate = AuthDelegate()
            let appID = UUID(uuidString: self.config.appID)
            if (appID == nil) {
                throw DittoStartError("AppID is not a valid UUID.")
            }
            self.ditto = Ditto(identity: .onlineWithAuthentication(appID: self.config.appID, authenticationDelegate: self.authDelegate), persistenceDirectory: persistenceDir)
        case IdentityType.offlinePlayground:
            self.ditto = Ditto(identity: .offlinePlayground(appID: self.config.appID), persistenceDirectory: persistenceDir)
            try self.ditto!.setOfflineOnlyLicenseToken(self.config.offlineLicenseToken)
        }
        
        self.ditto!.delegate = self
        
        do {
            try ditto!.startSync()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        DispatchQueue.main.async {
            // Let the DittoManager finish getting created, then apply initial diagnostics setting
            DiagnosticsManager.shared.isEnabled = AppSettings.shared.diagnosticLogsEnabled
        }
        
        setupLiveQueries()
    }
    
    func setupLiveQueries () {
        self.collectionsSubscription = DittoManager.shared.ditto?.store.collections().subscribe()
        self.collectionsObserver = DittoManager.shared.ditto?.store.collections().observeLocal(eventHandler: { event in
            self.colls = DittoManager.shared.ditto?.store.collections().exec() ?? []
       })
    }

    func setupLogging() {
        let logOption = AppSettings.shared.loggingOption
        switch logOption {
        case .disabled:
            DittoLogger.enabled = false
        default:
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: logOption.rawValue)!
            if let logFileURL = DittoLogManager.shared.logFileURL {
                DittoLogger.setLogFileURL(logFileURL)
            }
        }
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
