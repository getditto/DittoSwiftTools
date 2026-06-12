//
//  DittoService.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

/// A service that manages the lifecycle of a Ditto instance, including initialization, and synchronization.
///
/// `DittoService` is designed as a singleton to provide a centralized interface for working with a Ditto instance
/// within an app. It builds Ditto from values supplied by `Env` (generated from `.env` at build time).
///
/// ## Features
/// - **Singleton Access**: Use `DittoService.shared` to access the single instance.
/// - **Sync Engine Management**: Start, stop, or restart the Ditto synchronization engine.
///
/// ## Usage:
///   ```swift
///   let dittoService = DittoService.shared
///   try? dittoService.initializeDitto()
///   dittoService.startSyncEngine()
///   ```
///
/// ## Topics
/// ### Initialization
/// - `initializeDitto(useIsolatedDirectories:)`
/// - `destroyDittoInstance()`
///
/// ### Synchronization
/// - `startSyncEngine()`
/// - `stopSyncEngine()`
/// - `restartSyncEngine()`
///
/// ### Delegate Handling
/// - `dittoTransportConditionDidChange(ditto:condition:subsystem:)`
@MainActor
public class DittoService: ObservableObject {

    // MARK: - Properties

    /// Optional Ditto instance that can be initialized later
    @Published public private(set) var ditto: Ditto?

    // MARK: - Singleton

    /// Shared instance of the `DittoService`.
    public static let shared = DittoService()

    /// Initializes the `DittoService` singleton.
    ///
    /// The private initializer sets up logging and initializes the Ditto
    /// instance from the `Env` values generated from `.env` at build time.
    private init() {

        // Configure Ditto logging
        DittoLogger.minimumLogLevel = DittoLogLevel.restoreFromStorage()
        DittoLogger.isEnabled = true

        // Initialize Ditto using credentials from `.env`
        do {
            try initializeDitto()
        } catch {
            assertionFailure("Failed to initialize Ditto: \(error.localizedDescription)")
        }
    }

    // MARK: - Ditto Instance Management

    /// Initializes the Ditto instance from the values in `Env` (generated from `.env` at build time).
    ///
    /// - Parameter useIsolatedDirectories: A flag indicating whether to use isolated directories for persistence.
    /// - Throws: `DittoServiceError` if initialization fails.
    func initializeDitto(useIsolatedDirectories: Bool = true) throws {

        // Clear any existing instance before initializing a new one
        destroyDittoInstance()

        do {
            // Validate required values from `.env`
            guard !Env.DITTO_APP_ID.isEmpty, !Env.DITTO_PLAYGROUND_TOKEN.isEmpty else {
                throw DittoServiceError.invalidCredentials(
                    "DITTO_APP_ID or DITTO_PLAYGROUND_TOKEN is empty. Copy .env.sample to .env at the repo root and fill in values."
                )
            }

            guard let authURL = URL(string: Env.DITTO_AUTH_URL) else {
                throw DittoServiceError.invalidCredentials(
                    "DITTO_AUTH_URL is empty or invalid. Set it in .env."
                )
            }

            // Determine the persistence directory based on the app ID and directory isolation preference
            let storageDirectoryURL = try DittoService.persistenceDirectoryURL(
                appID: Env.DITTO_APP_ID,
                useIsolatedDirectories: useIsolatedDirectories)

            // Build the v5 config: server-mode connect points at the auth URL.
            // persistenceDirectory is set so multiple databaseIDs don't collide
            // on disk.
            let config = DittoConfig(
                databaseID: Env.DITTO_APP_ID,
                connect: .server(url: authURL),
                persistenceDirectory: storageDirectoryURL
            )

            // Attempt to initialize the Ditto instance with the provided config
            let openedDitto = try Ditto.openSync(config: config)
            ditto = openedDitto

            print("Ditto instance initialized successfully.")

            // For server connections, install an expiration handler before
            // sync.start() — sync will throw if it's missing.
            openedDitto.auth?.expirationHandler = { ditto, _ in
                ditto.auth?.login(
                    token: Env.DITTO_PLAYGROUND_TOKEN,
                    provider: .development
                ) { userInfo, error in
                    if let error {
                        print("Auth login failed: \(error.localizedDescription)")
                    } else {
                        print("Auth login succeeded: \(String(describing: userInfo))")
                    }
                }
            } as DittoAuthenticationExpirationHandler

            // Start the sync engine
            try startSyncEngine()

            print("Ditto initialization process completed successfully.")

        } catch let error as DittoServiceError {
            // log and rethrow known service errors
            print("Ditto initialization failed: \(error.localizedDescription)")
            throw error
        } catch {
            throw DittoServiceError.initializationFailed("Unexpected error: \(error.localizedDescription)")
        }
    }

    /// Clears the current Ditto instance.
    ///
    /// This method deallocates the existing `Ditto` instance by setting it to `nil`.
    func destroyDittoInstance() {

        // Stop the sync engine if it is active
        stopSyncEngine()

        // Remove the delegate and deallocate the Ditto instance
        ditto?.delegate = nil
        ditto = nil

        print("Ditto instance destroyed successfully. Ditto = \(String(describing: ditto))")
    }

    // MARK: - Sync Engine Control

    /// Starts the sync engine on the Ditto instance.
    ///
    /// - Throws: `DittoServiceError` if the sync engine fails to start.
    func startSyncEngine() throws {
        guard let ditto = ditto else { throw DittoServiceError.noInstance }

        ditto.delegate = self

        do {
            try ditto.sync.start()
            print("Ditto sync engine started successfully.")
        } catch {
            throw DittoServiceError.syncFailed(error.localizedDescription)
        }
    }

    /// Stops the sync engine on the Ditto instance.
    func stopSyncEngine() {
        guard let ditto = ditto else { return }

        if !ditto.sync.isActive {
            return
        }

        ditto.sync.stop()
        print("Ditto sync engine stopped successfully.")
    }

    /// Restarts the sync engine by stopping and starting it again.
    ///
    /// - Throws: `DittoServiceError` if restarting the sync engine fails.
    func restartSyncEngine() throws {
        stopSyncEngine()
        try startSyncEngine()
    }
}

// MARK: - DittoDelegate

extension DittoService: @preconcurrency DittoDelegate {

    /// Handles updates to Ditto's transport condition.
    ///
    /// - Parameters:
    ///   - ditto: The Ditto instance reporting the condition change.
    ///   - condition: The new transport condition.
    ///   - subsystem: The subsystem reporting the condition change.
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
