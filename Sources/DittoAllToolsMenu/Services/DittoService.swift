//
//  DittoService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import Combine

#warning("TODO: comments")


public class DittoService: ObservableObject {

    // MARK: - Properties
    
    /// Optional Ditto instance that can be initialized later
    @Published public private(set) var ditto: Ditto?
    
    @Published var collections = [DittoCollection]()
    
    var collectionsObserver: DittoLiveQuery?
    var collectionsSubscription: DittoSubscription?
        
    @Published var loggingOption: DittoLogger.LoggingOptions {
        didSet {
            configureLogger(for: loggingOption)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    public static let shared = DittoService()

    // MARK: - Init
    
    private init() {
        
        // configure logging
        self.loggingOption = .error
        configureLogger(for: loggingOption)
        
        // observe changes persistently
        $loggingOption
            .sink { [weak self] logOption in
                self?.configureLogger(for: logOption)
            }
            .store(in: &cancellables)
        
        // start ditto
        if let activeIdentityConfiguration = IdentityConfigurationService.shared.activeConfiguration {
        //if let storedIdentityConfiguration = IdentityConfigurationService.shared.loadConfigurationFromKeychain(authenticationDelegate: authenticationDelegate) {
            try? initializeDitto(with: activeIdentityConfiguration)
        }
    }

    // MARK: - Helper Methods

    private func configureLogger(for option: DittoLogger.LoggingOptions) {
        switch option {
        case .disabled:
            DittoLogger.enabled = false
        default:
            DittoLogger.enabled = true
            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: option.rawValue) ?? .error
        }
    }
    
    
    static func persistenceDirectoryURL(appID: String? = "", useIsolatedDirectories: Bool = false) -> URL? {
#if os(tvOS)
        let persistenceDirectory: FileManager.SearchPathDirectory = .cachesDirectory
#else
        let persistenceDirectory: FileManager.SearchPathDirectory = .documentDirectory
#endif
        
        var rootDirectoryURL = try! FileManager.default.url(for: persistenceDirectory, in:.userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ditto")
        
        if let appID = appID {
            rootDirectoryURL = rootDirectoryURL.appendingPathComponent(appID)
        }
        
        if useIsolatedDirectories {
            rootDirectoryURL = rootDirectoryURL.appendingPathComponent(UUID().uuidString)
        }
        
        return rootDirectoryURL
    }

    
    func initializeDitto(with identityConfiguration: IdentityConfiguration, useIsolatedDirectories: Bool = true) throws {
        
        // clear existing instance
        resetDitto()
        
        #warning("TODO: logging")
        // make sure our log level is set _before_ starting ditto.
        // configureLogging(with: AppSettings.shared.loggingOption)
        
        
        // Determine the persistence directory based on the app ID and directory isolation preference
        let storageDirectoryURL = DittoService.persistenceDirectoryURL(
            appID: identityConfiguration.identity.appID,
            useIsolatedDirectories: useIsolatedDirectories
        )
        
        // Attempt to initialize the Ditto instance with the provided identity configuration
        self.ditto = Ditto(
            identity: identityConfiguration.identity,
            persistenceDirectory: storageDirectoryURL
        )
    
        // Ensure the Ditto instance was successfully created
        guard let ditto = self.ditto else {
            throw DittoServiceError.initializationFailed(
                "Identity type: \(identityConfiguration.identity.identityType), " +
                "Persistence directory: \(storageDirectoryURL?.absoluteString ?? "nil")."
            )
        }
        
        print("Ditto instance initialized successfully.")
        
        // Now that we know that it works, we can save it as the active configuration
        IdentityConfigurationService.shared.activeConfiguration = identityConfiguration
        
        // Conditionally set the offline license token if required by the identity type
        try setOfflineLicenseTokenIfNeeded(for: identityConfiguration, on: ditto)
        
        // Attempt to start the sync engine
        do {
            try startSyncEngine()
        } catch {
            assertionFailure("Sync Engine failed to start: \(error.localizedDescription)")
            throw DittoServiceError.syncFailed(error.localizedDescription)
        }
        
        #warning("TODO: Add diagnostics and live query setup")
        DispatchQueue.main.async {
            // Configure diagnostics if needed
            // DiagnosticsManager.shared.isEnabled = AppSettings.shared.diagnosticLogsEnabled
        }

        #warning("TODO: Set up Live Queries - why is this crashing")
        // setupLiveQueries()
    }
    
    /// Method to clear Ditto instance, and optionally clear the active configuration (will delete credentials, and the user will have to re-enter them)
    func resetDitto(clearingActiveConfiguration: Bool = false) {
        self.ditto?.stopSync()
        self.ditto?.delegate = nil
        self.ditto = nil
        
        if clearingActiveConfiguration {
            IdentityConfigurationService.shared.activeConfiguration = nil
        }
    }

    /// Helper method to set the offline license token if required
    private func setOfflineLicenseTokenIfNeeded(for config: IdentityConfiguration, on ditto: Ditto) throws {
        let identity = config.identity
        let credentials = config.supplementaryCredentials
        
        guard identity.identityType == .offlinePlayground || identity.identityType == .sharedKey else { return }
        
        guard let offlineLicenseToken = credentials.offlineLicenseToken, !offlineLicenseToken.isEmpty else {
            throw DittoServiceError.invalidIdentity("Offline license token is required but not provided.")
        }
        
        do {
            try ditto.setOfflineOnlyLicenseToken(offlineLicenseToken)
        } catch {
            print("Failed to set offline license token: \(error.localizedDescription)")
            throw DittoServiceError.initializationFailed("Could not set offline license token.")
        }
    }
    
    /// Starts the sync engine on the initialized Ditto instance.
    func startSyncEngine() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }

        ditto.delegate = self
        
        do {
            try ditto.startSync()
        } catch {
            print("Failed to start sync: \(error.localizedDescription)")
            throw DittoServiceError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Stops the sync engine on the Ditto instance.
    func stopSyncEngine() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }
        
        if !ditto.isSyncActive {
            return
        }
        ditto.stopSync()
    }
    
    /// Restarts the sync engine by stopping and starting it again.
    func restartSyncEngine() throws {
        try stopSyncEngine()
        try startSyncEngine()
    }
    
    func setupLiveQueries () {
        self.collectionsSubscription = DittoService.shared.ditto?.store.collections().subscribe()
        self.collectionsObserver = DittoService.shared.ditto?.store.collections().observeLocal(eventHandler: { event in
            self.collections = DittoService.shared.ditto?.store.collections().exec() ?? []
        })
    }
}


// MARK: - DittoDelegate

extension DittoService: DittoDelegate {
    
    public func dittoTransportConditionDidChange(ditto: Ditto,
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
}
