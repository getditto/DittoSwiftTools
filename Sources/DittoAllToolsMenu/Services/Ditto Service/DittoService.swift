//
//  DittoService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

#warning("TODO: comments")

public class DittoService: ObservableObject {

    // MARK: - Properties

    /// Optional Ditto instance that can be initialized later
    @Published public private(set) var ditto: Ditto?

    @Published var collections = [DittoCollection]()

    var collectionsSubscription: DittoSubscription?
    var collectionsObserver: DittoLiveQuery?

    // MARK: - Singleton

    public static let shared = DittoService()

    private init() {

        // configure logging
        DittoLogger.minimumLogLevel = DittoLogLevel.restoreFromStorage()
        DittoLogger.enabled = true

        // start ditto
        if let activeIdentityConfiguration = IdentityConfigurationService.shared.activeConfiguration {
            do {
                try initializeDitto(with: activeIdentityConfiguration)
            } catch {
                assertionFailure("Failed to initialize Ditto: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Ditto Instance Management

    /// Initializes the Ditto instance with the given identity configuration.
    ///
    /// - Parameters:
    ///   - identityConfiguration: The identity configuration used to initialize Ditto.
    ///   - useIsolatedDirectories: Whether to use isolated directories for persistence.
    /// - Throws: `DittoServiceError` if initialization fails.
    func initializeDitto(with identityConfiguration: IdentityConfiguration, useIsolatedDirectories: Bool = true) throws {
        
        // clear existing instance
        destroyDittoInstance()

        do {
            // Determine the persistence directory based on the app ID and directory isolation preference
            let storageDirectoryURL = try DittoService.persistenceDirectoryURL(
                appID: identityConfiguration.identity.appID,
                useIsolatedDirectories: useIsolatedDirectories)

            // Attempt to initialize the Ditto instance with the provided identity configuration
            ditto = Ditto(
                identity: identityConfiguration.identity,
                persistenceDirectory: storageDirectoryURL
            )
            
            // Unwrap to ensure the value is valid and available throughout the rest of the method
            guard let ditto else {
                throw DittoServiceError.noInstance
            }

            print("Ditto instance initialized successfully.")

            // Now that we know that it works, we can save it as the active configuration
            IdentityConfigurationService.shared.activeConfiguration = identityConfiguration

            // Conditionally set the offline license token if required by the identity type
            try setOfflineLicenseTokenIfNeeded(for: identityConfiguration, on: ditto)

            // Attempt to start the sync engine
            try startSyncEngine()

            try setupLiveQueries()
            
            print("Ditto initialization process completed successfully.")

        } catch let error as DittoServiceError {
            // log and rethrow known service errors
            print("Ditto initialization failed: \(error.localizedDescription)")
            throw error
        } catch {
            throw DittoServiceError.initializationFailed("Unexpected error: \(error.localizedDescription)")
        }

        #warning("TODO: Add diagnostics and live query setup")
        //        DispatchQueue.main.async {
        //            // Configure diagnostics if needed
        //            // DiagnosticsManager.shared.isEnabled = AppSettings.shared.diagnosticLogsEnabled
        //        }
    }

    /// Clears the current Ditto instance and optionally removes the active configuration.
    ///
    /// This method deallocates the existing `Ditto` instance by setting it to `nil` and optionally clears the
    /// active configuration from the `IdentityConfigurationService`. Clearing the configuration will delete
    /// credentials, requiring the user to re-enter them in future operations.
    ///
    /// - Parameter clearConfig: A Boolean value indicating whether the active configuration
    ///   should also be cleared. If `true`, credentials associated with the active configuration will be
    ///   removed. Defaults to `false`.
    func destroyDittoInstance(clearConfig: Bool = false) {
        
        collectionsObserver?.stop()
        collectionsObserver = nil
        
        collectionsSubscription?.cancel()
        collectionsSubscription = nil
                
        stopSyncEngine()
        
        // Remove the delegate to prevent further interactions with the Ditto instance
        ditto?.delegate = nil
        
        // Deallocate the Ditto instance by setting it to nil
        ditto = nil

        // If requested, clear the active configuration from the identity service
        if clearConfig {
            IdentityConfigurationService.shared.activeConfiguration = nil
        }
        
        print("Ditto instance destroyed successfully. Ditto = \(String(describing: ditto))")
    }

    // MARK: - Private Helper Methods

    /// Helper method to set the offline license token if required
    private func setOfflineLicenseTokenIfNeeded(for config: IdentityConfiguration, on ditto: Ditto) throws {
        let identity = config.identity
        guard identity.identityType == .offlinePlayground || identity.identityType == .sharedKey else { return }

        let credentials = config.supplementaryCredentials
        guard let offlineLicenseToken = credentials.offlineLicenseToken, !offlineLicenseToken.isEmpty else {
            throw DittoServiceError.invalidIdentity("Offline license token is required but not provided.")
        }

        do {
            try ditto.setOfflineOnlyLicenseToken(offlineLicenseToken)
        } catch {
            throw DittoServiceError.initializationFailed("Could not set offline license token.")
        }
    }

    #warning("TODO: What does subscribing to all collections do, in the context of the AllToolsMenu?")
    private func setupLiveQueries() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }

        self.collectionsSubscription = ditto.store.collections().subscribe()
        self.collectionsObserver = ditto.store.collections().observeLocal(eventHandler: { event in
            self.collections = ditto.store.collections().exec()
        })
        
        print("Ditto live queries started up successfully.")
    }

    // MARK: - Sync Engine Control

    /// Starts the sync engine on the initialized Ditto instance.
    func startSyncEngine() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }

        ditto.delegate = self

        do {
            try ditto.startSync()
            print("Ditto sync engine started successfully.")
        } catch {
            throw DittoServiceError.syncFailed(error.localizedDescription)
        }
    }

    /// Stops the sync engine on the Ditto instance.
    func stopSyncEngine() {
        guard let ditto = ditto else { return }

        if !ditto.isSyncActive {
            return
        }
        
        ditto.stopSync()
        print("Ditto sync engine stopped successfully.")
    }

    /// Restarts the sync engine by stopping and starting it again.
    func restartSyncEngine() throws {
        stopSyncEngine()
        try startSyncEngine()
    }
}

// MARK: - DittoDelegate

extension DittoService: DittoDelegate {

    public func dittoTransportConditionDidChange(
        ditto: Ditto,
        condition: DittoTransportCondition,
        subsystem: DittoConditionSource
    ) {
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
