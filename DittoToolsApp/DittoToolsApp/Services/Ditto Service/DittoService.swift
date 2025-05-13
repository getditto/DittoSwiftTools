//
//  DittoService.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import Combine
import DittoSwift

/// A service that manages the lifecycle of a Ditto instance, including initialization, and synchronization.
///
/// `DittoService` is designed as a singleton to provide a centralized interface for working with a Ditto instance
/// within an app. It allows for initializing Ditto with specific credentials, and managing its synchronization engine.
///
/// ## Features
/// - **Singleton Access**: Use `DittoService.shared` to access the single instance.
/// - **Sync Engine Management**: Start, stop, or restart the Ditto synchronization engine.
/// - **Identity Management**: Initialize Ditto with secure Credentials to manage offline license tokens.
///
/// ## Usage:
///   ```swift
///   let dittoService = DittoService.shared
///   try? dittoService.initializeDitto(with: credentials)
///   dittoService.startSyncEngine()
///   ```
///
/// - Note: This service is tightly coupled with the Ditto SDK and requires identity and license configuration.
///
/// ## Topics
/// ### Initialization
/// - `initializeDitto(with:useIsolatedDirectories:)`
/// - `destroyDittoInstance(clearConfig:)`
///
/// ### Synchronization
/// - `startSyncEngine()`
/// - `stopSyncEngine()`
/// - `restartSyncEngine()`
///
/// ### Delegate Handling
/// - `dittoTransportConditionDidChange(ditto:condition:subsystem:)`
public class DittoService: ObservableObject {

    // MARK: - Properties

    /// Optional Ditto instance that can be initialized later
    @Published public private(set) var ditto: Ditto?

    // MARK: - Singleton

    /// Shared instance of the `DittoService`.
    public static let shared = DittoService()

    /// Initializes the `DittoService` singleton.
    ///
    /// The private initializer sets up logging, attempts to restore active Credentials
    /// from storage, and initializes the Ditto instance if possible.
    private init() {

        // Configure Ditto logging
        DittoLogger.enabled = true

        // Attempt to initialize Ditto using the active credentials
        if let activeCredentials = CredentialsService.shared.activeCredentials {
            do {
                try initializeDitto(with: activeCredentials)
            } catch {
                assertionFailure("Failed to initialize Ditto: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Ditto Instance Management

    /// Initializes the Ditto instance with the given Credentials.
    ///
    /// - Parameters:
    ///   - credentials: The credentials used to initialize Ditto.
    ///   - useIsolatedDirectories: A flag indicating whether to use isolated directories for persistence.
    /// - Throws: `DittoServiceError` if initialization fails.
    func initializeDitto(with credentials: Credentials, useIsolatedDirectories: Bool = true) throws {

        // Clear any existing instance before initializing a new one
        destroyDittoInstance()

        do {
            // Determine the persistence directory based on the app ID and directory isolation preference
            let storageDirectoryURL = try DittoService.persistenceDirectoryURL(
                appID: credentials.identity.appID,
                useIsolatedDirectories: useIsolatedDirectories)

            // Attempt to initialize the Ditto instance with the provided credentials
            ditto = Ditto(
                identity: credentials.identity,
                persistenceDirectory: storageDirectoryURL
            )

            // Unwrap to ensure the value is valid and available throughout the rest of the method
            guard let ditto else {
                throw DittoServiceError.noInstance
            }

            print("Ditto instance initialized successfully.")

            // Save the credentials as the active credentials
            CredentialsService.shared.activeCredentials = credentials

            // Conditionally set the offline license token if required by the identity type
            try setOfflineLicenseTokenIfNeeded(for: credentials, on: ditto)

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

    /// Clears the current Ditto instance and optionally removes the active credentials.
    ///
    /// This method deallocates the existing `Ditto` instance by setting it to `nil` and optionally clears the
    /// active credentials from the `CredentialsService`. Clearing the credentials will delete
    /// credentials completely, requiring the user to re-enter them in future operations.
    ///
    /// - Parameter clearingCredentials: A Boolean value indicating whether the active credentials
    ///   should also be cleared. If `true`, the active credentials will be removed. Defaults to `false`.
    func destroyDittoInstance(clearingCredentials: Bool = false) {

        // Stop the sync engine if it is active
        stopSyncEngine()

        // Remove the delegate and deallocate the Ditto instance
        ditto?.delegate = nil
        ditto = nil

        // Optionally clear the active credentials
        if clearingCredentials {
            CredentialsService.shared.activeCredentials = nil
        }

        print("Ditto instance destroyed successfully. Ditto = \(String(describing: ditto))")
    }

    // MARK: - Private Helper Methods

    /// Sets the offline license token on the Ditto instance if required by the identity type.
    private func setOfflineLicenseTokenIfNeeded(for credentials: Credentials, on ditto: Ditto) throws {
        let identity = credentials.identity
        guard identity.identityType == .offlinePlayground || identity.identityType == .sharedKey else { return }

        guard let offlineLicenseToken = credentials.offlineLicenseToken, !offlineLicenseToken.isEmpty else {
            throw DittoServiceError.invalidCredentials("Offline license token is required but not provided.")
        }

        do {
            try ditto.setOfflineOnlyLicenseToken(offlineLicenseToken)
        } catch {
            throw DittoServiceError.initializationFailed("Could not set offline license token.")
        }
    }

    // MARK: - Sync Engine Control

    /// Starts the sync engine on the Ditto instance.
    ///
    /// - Throws: `DittoServiceError` if the sync engine fails to start.
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
    ///
    /// - Throws: `DittoServiceError` if restarting the sync engine fails.
    func restartSyncEngine() throws {
        stopSyncEngine()
        try startSyncEngine()
    }
}

// MARK: - DittoDelegate

extension DittoService: DittoDelegate {

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
