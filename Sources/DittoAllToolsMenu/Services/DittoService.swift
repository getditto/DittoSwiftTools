//
//  DittoService.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import Combine

#warning("TODO: comments")

enum DittoServiceError: Error {
    case noInstance  // Error when trying to interact with a non-initialized Ditto instance
    case identityNotProvided  // Error when identity is required but not provided
    case invalidIdentity(String)  // Error for invalid identity with a custom message
    case initializationFailed(String)  // Error when initialization of Ditto fails
    case syncFailed(String)  // Error when starting sync fails with a custom reason
}


extension DittoServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noInstance:
            return NSLocalizedString("No Ditto instance is available.", comment: "")
        case .identityNotProvided:
            return NSLocalizedString("An identity must be provided to initialize Ditto.", comment: "")
        case .invalidIdentity(let message):
            return NSLocalizedString("Invalid identity: \(message)", comment: "")
        case .initializationFailed(let reason):
            return NSLocalizedString("Ditto initialization failed: \(reason)", comment: "")
        case .syncFailed(let reason):
            return NSLocalizedString("Failed to start sync: \(reason)", comment: "")
        }
    }
}


public class DittoService: ObservableObject {

    // MARK: - Properties
    
    // Optional Ditto instance that can be initialized later
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
        //if let storedIdentityConfiguration = IdentityConfigurationService.shared.loadConfigurationFromKeychain(authDelegate: authDelegate) {
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
        
        clearDittoInstance()
        
#warning("TODO: logging")
        // make sure our log level is set _before_ starting ditto.
        //        configureLogging(with: AppSettings.shared.loggingOption)
        
        let storageDirectoryURL = DittoService.persistenceDirectoryURL(appID: identityConfiguration.identity.appID, useIsolatedDirectories: useIsolatedDirectories)
        self.ditto = Ditto(identity: identityConfiguration.identity, persistenceDirectory: storageDirectoryURL)
        
        guard let ditto = self.ditto else {
            throw DittoServiceError.initializationFailed("Identity type: \(identityConfiguration.identity.identityType), Persistence directory: \(String(describing: storageDirectoryURL?.absoluteString)).")
        }
        
        // Set up offline license token
        if (identityConfiguration.identity.identityType == .offlinePlayground || identityConfiguration.identity.identityType == .sharedKey)
            && !identityConfiguration.supplementaryCredentials.offlineLicenseToken.isEmpty {
            try ditto.setOfflineOnlyLicenseToken(identityConfiguration.supplementaryCredentials.offlineLicenseToken)
        }
        
        do {
            try startSyncEngine()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
#warning("TODO: Diagnostics")
        
        DispatchQueue.main.async {
            // Let the DittoManager finish getting created, then apply initial diagnostics setting
            //            DiagnosticsManager.shared.isEnabled = AppSettings.shared.diagnosticLogsEnabled
        }

#warning("TODO: Set up Live Queries - why is this crashing")
        // setupLiveQueries()
    }
    
    func deinitDitto(clearKeychain: Bool = false) {
        clearDittoInstance()
        
        if clearKeychain {
            IdentityConfigurationService.shared.activeConfiguration = nil
        }
    }
    
    // Method to clear Ditto (for resetting or logging out)
    private func clearDittoInstance() {
        self.ditto?.stopSync()
        self.ditto?.delegate = nil
        self.ditto = nil
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
