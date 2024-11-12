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









//
//
////
////  DittoService.swift
////

//
///// A singleton which manages our `Ditto` object.
//class DittoManager: ObservableObject {
//
//
//    // MARK: - Properties
//
//
//    @Published var loggingOption: DittoLogger.LoggingOptions
//    private var cancellables = Set<AnyCancellable>()
//

//
//    // MARK: - Private Constructor
//
//    init() {
//        self.loggingOption = AppSettings.shared.loggingOption
//        
//        // make sure log level is set _before_ starting ditto
//        $loggingOption
//            .sink {[weak self] newLoggingOption in
//                self?.updateAppSettings(with: newLoggingOption)
//                self?.configureLogging(with: newLoggingOption)
//            }
//            .store(in: &cancellables)
//        
//        self.ditto = Ditto(persistenceDirectory: DittoManager.persistenceDirectoryURL())
//    }
//    
//    private func updateAppSettings(with loggingOption: DittoLogger.LoggingOptions) {
//        // Update AppSettings with the new logging option
//        AppSettings.shared.loggingOption = loggingOption
//    }
//    
//    private func configureLogging(with loggingOption: DittoLogger.LoggingOptions) {
//        // Set up logging according to the new logging option
//        switch loggingOption {
//        case .disabled:
//            DittoLogger.enabled = false
//        default:
//            DittoLogger.enabled = true
//            DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: loggingOption.rawValue)!
//        }
//    }
//
//
//

//}
//
//

//
//
//
//
//
//
//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import UIKit
//import DittoSwift
//
//
///// A singleton instance which manages the app settings. The persisted settings
///// include enabled transports and list of available servers. These settings are
///// persisted in `UserDefaults` and so are available on subsequent app launches.
/////
///// This should be re-written to use a private Ditto collection as a local store.
//class AppSettings {
//
//    // MARK: - Constants
//
//    private struct UserDefaultsKeys {
//        static let availableServers = "live.ditto.DittoCarsApp.settings.available-servers"
//        static let selectedTCPServerId = "live.ditto.DittoCarsApp.settings.selected-tcp-server-id"
//        static let selectedWebsocketServerId = "live.ditto.DittoCarsApp.settings.selected-websocket-server-id"
//        static let enabledTransports = "live.ditto.DittoCarsApp.settings.enabled-transports"
//        static let backgroundNotificationsEnabled = "live.ditto.DittoCarsApp.settings.background-notifications-enabled"
//        static let diagnosticsLogsEnabled = "live.ditto.DittoCarsApp.settings.diagnostics-logs-enabled"
//        static let loggingOption = "live.ditto.DittoCarsApp.settings.loggingOption"
//    }
//
//    private struct Defaults {
//        /// The default transports to enable if no other settings are saved
//        static let enabledTransports: Set<Transport> = Set(Transport.p2pTransports)
//
//        /// The default server list, used if no other settings are saved
//        static let servers: [Server] = []
//    }
//
//    // MARK: - Properties
//
//    private(set) var servers: [Server] {
//        didSet {
//            let encoded = try! JSONEncoder().encode(self.servers)
//            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.availableServers)
//        }
//    }
//
//    var selectedTCPServer: Server? {
//        didSet {
//            let encoded = try! JSONEncoder().encode(self.selectedTCPServer?.id)
//            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.selectedTCPServerId)
//        }
//    }
//
//    var selectedWebsocketServer: Server? {
//        didSet {
//            let encoded = try! JSONEncoder().encode(self.selectedWebsocketServer?.id)
//            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.selectedWebsocketServerId)
//        }
//    }
//
//    var enabledTransports: Set<Transport> {
//        didSet {
//            let encoded = try! JSONEncoder().encode(self.enabledTransports)
//            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.enabledTransports)
//        }
//    }
//
//    var backgroundNotificationsEnabled: Bool {
//        didSet {
//            UserDefaults.standard.set(self.backgroundNotificationsEnabled,
//                                      forKey: UserDefaultsKeys.backgroundNotificationsEnabled)
//
//            if !oldValue && self.backgroundNotificationsEnabled {
//                AuthorizationsManager.shared.requestNotificationAuthorization()
//            }
//        }
//    }
//
//    var diagnosticLogsEnabled: Bool {
//        didSet {
//            UserDefaults.standard.set(self.diagnosticLogsEnabled, forKey: UserDefaultsKeys.diagnosticsLogsEnabled)
//            DiagnosticsManager.shared.isEnabled = self.diagnosticLogsEnabled
//        }
//    }
//
//    /// This property is initialized in the private init() below, setting UserDefaults with a default value, .debug, if not yet set.
//    var loggingOption: DittoLogger.LoggingOptions {
//        didSet {
//            UserDefaults.standard.set(self.loggingOption.rawValue, forKey: UserDefaultsKeys.loggingOption)
//        }
//    }
//
//    // MARK: - Singleton
//
//    /// Singleton instance. All access is via `AppSettings.shared`.
//    static var shared = AppSettings()
//
//    // MARK: - Functions & Computed Properties
//
//    func removeServer(_ server: Server) {
//        self.servers.removeAll(where: { $0.id == server.id })
//
//        // Maybe the server being removed was in use as our selected websocket or tcp
//        // server. If so, remove it.
//        if self.selectedWebsocketServer == server {
//            self.selectedWebsocketServer = nil
//        }
//        if self.selectedTCPServer == server {
//            self.selectedTCPServer = nil
//        }
//    }
//
//    /// Adds a new server, or updates an existing server with the same `id`.
//    func addOrAmendServer(_ server: Server) {
//        if let existingIndex = self.servers.firstIndex(where: { $0.id == server.id }) {
//            servers[existingIndex] = server
//        } else {
//            self.servers.append(server)
//        }
//
//        // Maybe a current selection has been invalidated (i.e. our websocket server was
//        // amended such that its websocket port was removed).
//        if self.selectedWebsocketServer == server {
//            self.selectedWebsocketServer = server.websocketPort == nil ? nil : server
//        }
//        if self.selectedTCPServer == server {
//            self.selectedTCPServer = server.tcpPort == nil ? nil : server
//        }
//    }
//
//    func setTransportEnabled(_ transport: Transport, enabled: Bool) {
//        if enabled {
//            self.enabledTransports.insert(transport)
//        } else {
//            self.enabledTransports.remove(transport)
//        }
//    }
//
//    func isTransportEnabled(_ transport: Transport) -> Bool {
//        return self.enabledTransports.contains(transport)
//    }
//
//    func populateDefaultServers() -> Int {
//        var numAdded = 0
//        for server in Defaults.servers {
//            if !self.servers.contains(where: { $0.id == server.id }) {
//                numAdded += 1
//            }
//            self.addOrAmendServer(server)
//        }
//
//        return numAdded
//    }
//
//    var areAllDefaultServersPresent: Bool {
//        return Set(self.servers.map { $0.id }).isSuperset(of: Set(Defaults.servers.map { $0.id }))
//    }
//
//    // MARK: - Private Functions
//
//    private init() {
//        self.servers = Self.loadJSON(key: UserDefaultsKeys.availableServers, defaultValue: Defaults.servers)
//        self.enabledTransports = Self.loadJSON(key: UserDefaultsKeys.enabledTransports,
//                                               defaultValue: Defaults.enabledTransports)
//
//        let tcpServerId: UUID? = Self.loadJSON(key: UserDefaultsKeys.selectedTCPServerId, defaultValue: nil)
//        self.selectedTCPServer = self.servers.first(where: { $0.id == tcpServerId })
//
//        let websocketServerId: UUID? = Self.loadJSON(key: UserDefaultsKeys.selectedWebsocketServerId, defaultValue: nil)
//        self.selectedWebsocketServer = self.servers.first(where: { $0.id == websocketServerId })
//
//        self.backgroundNotificationsEnabled = UserDefaults.standard.bool(
//            forKey: UserDefaultsKeys.backgroundNotificationsEnabled)
//        self.diagnosticLogsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.diagnosticsLogsEnabled)
//
//        if let logOption = UserDefaults.standard.object(forKey: UserDefaultsKeys.loggingOption) as? Int {
//            self.loggingOption = DittoLogger.LoggingOptions(rawValue: logOption)!
//        } else {
//            self.loggingOption = DittoLogger.LoggingOptions(rawValue: DittoLogger.LoggingOptions.debug.rawValue)!
//        }
//    }
//
//    // MARK: - Static Functions
//
//    private static func loadJSON<T: Codable>(key: String, defaultValue: T) -> T {
//        if let value = UserDefaults.standard.object(forKey: key) {
//            if let data = value as? Data, let decoded = try? JSONDecoder().decode(T.self, from: data) {
//                return decoded
//            } else {
//                // Found a saved value, but it couldn't be loaded. Presumably it was from
//                // an older version of the cars app and is now incompatible. This data
//                // isn't crucial, so let's just erase it so it's fixed for next time.
//                UserDefaults.standard.removeObject(forKey: key)
//                return defaultValue
//            }
//        } else {
//            // No previously saved transports - use defaults
//            return defaultValue
//        }
//    }
//
//}
//
//
//
//
//
//
////

//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import Foundation
//
//enum Transport: String, CaseIterable, Codable, Equatable, Hashable {
//    case bluetooth
//    case wifi
//    case awdl
//    case tcpServer
//    case websocketServer
//
//    static var p2pTransports: [Self] {
//        [.bluetooth, .wifi, .awdl]
//    }
//
//    static var serverTransports: [Self] {
//        [.tcpServer, .websocketServer]
//    }
//}
//
//// MARK: CustomStringConvertible
//
//extension Transport: CustomStringConvertible {
//    var description: String {
//        switch self {
//        case .bluetooth:
//            return "Bluetooth"
//        case .wifi:
//            return "mDNS"
//        case .awdl:
//            return "AWDL"
//        case .tcpServer:
//            return "Static TCP"
//        case .websocketServer:
//            return "Websocket"
//        }
//    }
//}
//
//
//
//
//
//
//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import Foundation
//import Network
//
//struct Server: Identifiable, Codable, Equatable, Hashable {
//
//    // MARK: - Properties
//
//    /// A UUID string which identifies this server. Only used locally in
//    /// the cars app to save and update settings.
//    let id: UUID
//
//    /// A customizable user-friendly name intended to provide some
//    /// context (for example "HyDRA integration cluster")
//    let name: String
//
//    /// Server host, as either an IPv4 address or hostname.
//    let host: String
//
//    /// Port number of the server for TCP connections, if enabled. TCP
//    /// connections (effectively the same as our mDNS mesh protocol
//    /// but with a fixed-IP instead of a dynamically discovered host).
//    let tcpPort: UInt16?
//
//    /// Port number of the server for Websocket connections, if enabled.
//    /// If 443 then `wss://` will be used, otherwise `ws://`.
//    let websocketPort: UInt16?
//
//    // MARK: - Initializer
//
//    /// Constructor. If `host` or `port` were invalid, returns nil, otherwise
//    /// returns a valid `Server` object.
//    ///
//    /// - Parameters:
//    ///   - name: A customizable user-friendly name intended to provide some
//    ///           context (for example "HyDRA integration cluster")
//    ///   - host: Server host, as either an IP address or hostname.
//    ///   - port: Port number of the server. Cannot be 0.
//    init?(id: UUID, name: String, host: String, tcpPort: UInt16?, websocketPort: UInt16?) {
//        let validatedHost: String
//        if IPv4Address(host) != nil {
//            validatedHost = host
//        } else if !host.isEmpty && host.unicodeScalars.allSatisfy({ CharacterSet.urlHostAllowed.contains($0) }) {
//            validatedHost = host
//        } else {
//            print("Invalid host for server - must be either an IPv4 address or hostname: \(host)")
//            return nil
//        }
//
//        self.id = id
//        self.name = name.isEmpty ? "Server" : name
//        self.host = validatedHost
//        self.tcpPort = tcpPort
//        self.websocketPort = websocketPort
//    }
//
//    // MARK: - Functions
//
//    func urlString(formattedFor connectionType: ServerConnectionType) -> String {
//        let port = self.port(for: connectionType)
//
//        let portString = port?.description.prepending(":") ?? ""
//        let schemeString = connectionType.scheme(forPort: port)
//
//        return "\(schemeString)\(self.host)\(portString)"
//    }
//
//    func port(for connectionType: ServerConnectionType) -> UInt16? {
//        switch connectionType {
//        case .tcp: return self.tcpPort
//        case .websocket: return self.websocketPort
//        }
//    }
//
//}
//
//extension Server: CustomStringConvertible {
//    var description: String {
//        self.host
//    }
//}
//
//fileprivate extension String {
//    func prepending(_ other: String) -> String {
//        return other + self
//    }
//}
//
//
//
//
//
//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import UIKit
//import CoreBluetooth
//
//// MARK: - AuthorizationStatus
//
///// Each sub-component has its own strongly typed authorization status
///// and includes a few kinds of authorization we're not overly concerned
///// with. We define a simpler category here which corresponds to the
///// major decisions our app needs to take.
//enum AuthorizationStatus: CaseIterable, Equatable, Hashable {
//    case authorized
//    case denied
//    case notDetermined
//}
//
//extension AuthorizationStatus: CustomStringConvertible {
//    var description: String {
//        switch self {
//        case .authorized:
//            return "authorized"
//        case .denied:
//            return "denied"
//        case .notDetermined:
//            return "not yet requested"
//        }
//    }
//}
//
//// MARK: - AuthorizationsManager
//
///// A singleton which offers a convenient single point for interacting
///// with the various user authorizations we might need (notifications,
///// bluetooth, etc.)
/////
///// We unfortunately can't seem to (easily) check for local network
///// authorization.
//class AuthorizationsManager {
//
//    // MARK: - Properties
//
//    var bleAuthorizationStatus: AuthorizationStatus {
//        switch CBCentralManager.authorization {
//        case .allowedAlways:
//            return .authorized
//        case .notDetermined:
//            return .notDetermined
//        case .restricted:
//            return .denied
//        case .denied:
//            return .denied
//        @unknown default:
//            print("WARNING: Unknown CBCentralManager status")
//            return .notDetermined
//        }
//    }
//
//    var localNotificationAuthorizationStatus: AuthorizationStatus {
//        var status = AuthorizationStatus.notDetermined
//        // Such a hack. Look away.
//        let semaphore = DispatchSemaphore(value: 0)
//
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            switch settings.authorizationStatus {
//            case .notDetermined:
//                status = .notDetermined
//            case .denied:
//                status = .denied
//            case .authorized:
//                 status = .authorized
//            case .ephemeral:
//                status = .authorized
//            case .provisional:
//                status = .authorized
//            @unknown default:
//                print("WARNING: Unknown UNUserNotificationCenter status")
//                status = .notDetermined
//            }
//            semaphore.signal()
//        }
//
//        _ = semaphore.wait(wallTimeout: .distantFuture)
//        return status
//    }
//
//    // MARK: - Singleton
//
//    /// Singleton instance. All access is via `AuthorizationsManager.shared`.
//    static var shared = AuthorizationsManager()
//
//    // MARK: - Private Constructor
//
//    private init() {}
//
//    // MARK: - Functions
//
//    func requestNotificationAuthorization() {
//        let notificationCenter = UNUserNotificationCenter.current()
//        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
//            if !granted {
//                print("Request for user notifications authorization was denied")
//            }
//            if let error = error {
//                print("Request for user notifications authorization failed with error \(error)")
//            }
//        }
//    }
//
//}
//
//
//
//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import Foundation
//
//enum ServerConnectionType: CaseIterable {
//    case tcp
//    case websocket
//
//    func scheme(forPort port: UInt16?) -> String {
//        guard let port = port else {
//            return ""
//        }
//
//        switch self {
//        case .websocket where port == 443:
//            return "wss://"
//        case .websocket:
//            return "ws://"
//        case .tcp:
//            return ""
//        }
//    }
//
//    init?(from transport: Transport) {
//        switch transport {
//        case .tcpServer:
//            self = .tcp
//        case .websocketServer:
//            self = .websocket
//        default:
//            return nil
//        }
//    }
//
//    func toTransport() -> Transport {
//        switch self {
//        case .tcp:
//            return .tcpServer
//        case .websocket:
//            return .websocketServer
//        }
//    }
//}
//
//// MARK: CustomStringConvertible
//
//extension ServerConnectionType: CustomStringConvertible {
//    var description: String {
//        switch self {
//        case .tcp: return "Static TCP"
//        case .websocket: return "Websocket"
//        }
//    }
//}
//
//
//
//
////
////  Copyright © 2021 DittoLive Incorporated. All rights reserved.
////
//
//import Foundation
//import DittoSwift
//
///// A singleton which manages additional diagnostics logging (to the console only - not to
///// the Ditto persistent log file). Useful when debugging/testing only via Xcode.
//class DiagnosticsManager {
//
//    // MARK: - Public Properties
//
//    /// Enable or disable diagnostics console logging.
//    var isEnabled: Bool = false {
//        didSet {
//            if isEnabled {
//                self.startDiagnostics()
//            } else {
//                self.stopDiagnostics()
//            }
//        }
//    }
//
//    // MARK: - Properties
//
//    private var diagnosticsTimer: Timer?
//    private var observer: DittoObserver?
//
//    // MARK: - Singleton
//
//    /// Singleton instance. All access is via `Diagnostics.shared`.
//    static var shared = DiagnosticsManager()
//
//    // MARK: - Private Functions
//
//    private init() {}
//
//    // MARK: - Private Functions
//
//    func startDiagnostics() {
//        diagnosticsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
//            // This can take a while so take it off the main thread
//            DispatchQueue.global().async {
//                if let diag = try? DittoManager.shared.ditto!.transportDiagnostics() {
//                    print("--- Diagnostics")
//                    for transport in diag.transports {
//                        var out = "Transport \(transport.connectionType) -"
//                        if !transport.connecting.isEmpty {
//                            out += " connecting:\(transport.connecting)"
//                        }
//                        if !transport.connected.isEmpty {
//                            out += ", connected:\(transport.connected)"
//                        }
//                        if !transport.disconnecting.isEmpty {
//                            out += ", disconnecting:\(transport.disconnecting)"
//                        }
//                        if !transport.disconnected.isEmpty {
//                            out += ", disconnected:\(transport.disconnected)"
//                        }
//                        print(out)
//                    }
//                } else {
//                    print("Error getting diagnostics")
//                }
//            }
//        }
//
//        self.observer = DittoManager.shared.ditto!.presence.observe { peers in
//            print("Presence Update:")
//            dump(peers)
//        }
//    }
//
//    private func stopDiagnostics() {
//        self.diagnosticsTimer?.invalidate()
//        self.observer?.stop()
//
//        self.diagnosticsTimer = nil
//        self.observer = nil
//    }
//
//}
//

