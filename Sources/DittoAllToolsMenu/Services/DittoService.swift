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

    // MARK: - Init

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

    // MARK: -

    #warning("TODO: check docs syntax for param types")
    /// Initializes the Ditto instance with the given identity configuration.
    ///
    /// - Parameters:
    ///   - identityConfiguration: The identity configuration used to initialize Ditto.
    ///   - useIsolatedDirectories: Whether to use isolated directories for persistence.
    /// - Throws: `DittoServiceError` if initialization fails.
    func initializeDitto(with identityConfiguration: IdentityConfiguration, useIsolatedDirectories: Bool = true) throws {

        // clear existing instance
        resetDitto()

        do {
            // Determine the persistence directory based on the app ID and directory isolation preference
            let storageDirectoryURL = try DittoService.persistenceDirectoryURL(
                appID: identityConfiguration.identity.appID,
                useIsolatedDirectories: useIsolatedDirectories)

            // Attempt to initialize the Ditto instance with the provided identity configuration
            self.ditto = Ditto(
                identity: identityConfiguration.identity,
                persistenceDirectory: storageDirectoryURL)

            // Ensure the Ditto instance was successfully created
            guard let ditto = self.ditto else {
                throw DittoServiceError.initializationFailed(
                    "Identity type: \(identityConfiguration.identity.identityType), "
                        + "Persistence directory: \(storageDirectoryURL.absoluteString)."
                )
            }

            print("Ditto instance initialized successfully.")

            // Now that we know that it works, we can save it as the active configuration
            IdentityConfigurationService.shared.activeConfiguration = identityConfiguration

            // Conditionally set the offline license token if required by the identity type
            try setOfflineLicenseTokenIfNeeded(for: identityConfiguration, on: ditto)

            // Attempt to start the sync engine
            try startSyncEngine()

            try setupLiveQueries()

            print("Ditto instance initialized successfully.")

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

    /// Method to clear Ditto instance, and optionally clear the active configuration (will delete credentials, and the user will have to re-enter them.)
    func resetDitto(clearingActiveConfiguration: Bool = false) {
        self.ditto?.delegate = nil
        self.ditto = nil

        if clearingActiveConfiguration {
            IdentityConfigurationService.shared.activeConfiguration = nil
        }
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
    }

    // MARK: - Sync Engine Control

    /// Starts the sync engine on the initialized Ditto instance.
    func startSyncEngine() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }

        ditto.delegate = self

        do {
            try ditto.startSync()
        } catch {
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
}

// MARK: - Persistence Directory Management

extension DittoService {
    static func persistenceDirectoryURL(appID: String? = "", useIsolatedDirectories: Bool = false) throws -> URL {
        do {
            #if os(tvOS)
                let persistenceDirectory: FileManager.SearchPathDirectory = .cachesDirectory
            #else
                let persistenceDirectory: FileManager.SearchPathDirectory = .documentDirectory
            #endif

            var rootDirectoryURL = try FileManager.default.url(
                for: persistenceDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("ditto")

            if let appID = appID, !appID.isEmpty {
                rootDirectoryURL = rootDirectoryURL.appendingPathComponent(appID)
            }

            if useIsolatedDirectories {
                rootDirectoryURL = rootDirectoryURL.appendingPathComponent(UUID().uuidString)
            }

            return rootDirectoryURL
        } catch {
            throw DittoServiceError.initializationFailed("Failed to get persistence directory: \(error.localizedDescription)")
        }
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
