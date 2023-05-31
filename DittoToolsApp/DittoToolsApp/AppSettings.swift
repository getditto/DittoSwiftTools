//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import UIKit
import DittoSwift

extension AppSettings {
    enum LogLevel:Int, CustomStringConvertible, CaseIterable {
        case disabled = 0
        case error, warning, info, debug, verbose
        
        var description: String {
            switch self {
            case .disabled:
                return "disabled"
            case .error:
                return "error"
            case .warning:
                return "warning"
            case .info:
                return "info"
            case .debug:
                return "debug"
            case .verbose:
                return "verbose"
            }
        }
    }
}

/// A singleton instance which manages the app settings. The persisted settings
/// include enabled transports and list of available servers. These settings are
/// persisted in `UserDefaults` and so are available on subsequent app launches.
///
/// This should be re-written to use a private Ditto collection as a local store.
class AppSettings {

    // MARK: - Constants

    private struct UserDefaultsKeys {
        static let availableServers = "live.ditto.DittoCarsApp.settings.available-servers"
        static let selectedTCPServerId = "live.ditto.DittoCarsApp.settings.selected-tcp-server-id"
        static let selectedWebsocketServerId = "live.ditto.DittoCarsApp.settings.selected-websocket-server-id"
        static let enabledTransports = "live.ditto.DittoCarsApp.settings.enabled-transports"
        static let backgroundNotificationsEnabled = "live.ditto.DittoCarsApp.settings.background-notifications-enabled"
        static let diagnosticsLogsEnabled = "live.ditto.DittoCarsApp.settings.diagnostics-logs-enabled"
        static let logLevel = "live.ditto.DittoCarsApp.settings.log-level"
    }

    private struct Defaults {
        /// The default transports to enable if no other settings are saved
        static let enabledTransports: Set<Transport> = Set(Transport.p2pTransports)

        /// The default server list, used if no other settings are saved
        static let servers: [Server] = []
    }

    // MARK: - Properties

    private(set) var servers: [Server] {
        didSet {
            let encoded = try! JSONEncoder().encode(self.servers)
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.availableServers)
        }
    }

    var selectedTCPServer: Server? {
        didSet {
            let encoded = try! JSONEncoder().encode(self.selectedTCPServer?.id)
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.selectedTCPServerId)
        }
    }

    var selectedWebsocketServer: Server? {
        didSet {
            let encoded = try! JSONEncoder().encode(self.selectedWebsocketServer?.id)
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.selectedWebsocketServerId)
        }
    }

    var enabledTransports: Set<Transport> {
        didSet {
            let encoded = try! JSONEncoder().encode(self.enabledTransports)
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.enabledTransports)
        }
    }

    var backgroundNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(self.backgroundNotificationsEnabled,
                                      forKey: UserDefaultsKeys.backgroundNotificationsEnabled)

            if !oldValue && self.backgroundNotificationsEnabled {
                AuthorizationsManager.shared.requestNotificationAuthorization()
            }
        }
    }

    var diagnosticLogsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(self.diagnosticLogsEnabled, forKey: UserDefaultsKeys.diagnosticsLogsEnabled)
            DiagnosticsManager.shared.isEnabled = self.diagnosticLogsEnabled
        }
    }

    /// This property is initialized in the private init() below, setting UserDefaults with a default value, .disabled, if not yet set.
    var logLevel: AppSettings.LogLevel {
        didSet {
            UserDefaults.standard.set(self.logLevel.rawValue, forKey: UserDefaultsKeys.logLevel)
        }
    }

    // MARK: - Singleton

    /// Singleton instance. All access is via `AppSettings.shared`.
    static var shared = AppSettings()

    // MARK: - Functions & Computed Properties

    func removeServer(_ server: Server) {
        self.servers.removeAll(where: { $0.id == server.id })

        // Maybe the server being removed was in use as our selected websocket or tcp
        // server. If so, remove it.
        if self.selectedWebsocketServer == server {
            self.selectedWebsocketServer = nil
        }
        if self.selectedTCPServer == server {
            self.selectedTCPServer = nil
        }
    }

    /// Adds a new server, or updates an existing server with the same `id`.
    func addOrAmendServer(_ server: Server) {
        if let existingIndex = self.servers.firstIndex(where: { $0.id == server.id }) {
            servers[existingIndex] = server
        } else {
            self.servers.append(server)
        }

        // Maybe a current selection has been invalidated (i.e. our websocket server was
        // amended such that its websocket port was removed).
        if self.selectedWebsocketServer == server {
            self.selectedWebsocketServer = server.websocketPort == nil ? nil : server
        }
        if self.selectedTCPServer == server {
            self.selectedTCPServer = server.tcpPort == nil ? nil : server
        }
    }

    func setTransportEnabled(_ transport: Transport, enabled: Bool) {
        if enabled {
            self.enabledTransports.insert(transport)
        } else {
            self.enabledTransports.remove(transport)
        }
    }

    func isTransportEnabled(_ transport: Transport) -> Bool {
        return self.enabledTransports.contains(transport)
    }

    func populateDefaultServers() -> Int {
        var numAdded = 0
        for server in Defaults.servers {
            if !self.servers.contains(where: { $0.id == server.id }) {
                numAdded += 1
            }
            self.addOrAmendServer(server)
        }

        return numAdded
    }

    var areAllDefaultServersPresent: Bool {
        return Set(self.servers.map { $0.id }).isSuperset(of: Set(Defaults.servers.map { $0.id }))
    }

    // MARK: - Private Functions

    private init() {
        self.servers = Self.loadJSON(key: UserDefaultsKeys.availableServers, defaultValue: Defaults.servers)
        self.enabledTransports = Self.loadJSON(key: UserDefaultsKeys.enabledTransports,
                                               defaultValue: Defaults.enabledTransports)

        let tcpServerId: UUID? = Self.loadJSON(key: UserDefaultsKeys.selectedTCPServerId, defaultValue: nil)
        self.selectedTCPServer = self.servers.first(where: { $0.id == tcpServerId })

        let websocketServerId: UUID? = Self.loadJSON(key: UserDefaultsKeys.selectedWebsocketServerId, defaultValue: nil)
        self.selectedWebsocketServer = self.servers.first(where: { $0.id == websocketServerId })

        self.backgroundNotificationsEnabled = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.backgroundNotificationsEnabled)
        self.diagnosticLogsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.diagnosticsLogsEnabled)

        if let level = UserDefaults.standard.object(forKey: UserDefaultsKeys.logLevel) as? Int {
            self.logLevel = AppSettings.LogLevel(rawValue: level)!
        } else {
            self.logLevel = AppSettings.LogLevel(rawValue: AppSettings.LogLevel.disabled.rawValue)!
        }
    }

    // MARK: - Static Functions

    private static func loadJSON<T: Codable>(key: String, defaultValue: T) -> T {
//        if let value = UserDefaults().object(forKey: key) {
        if let value = UserDefaults.standard.object(forKey: key) {
            if let data = value as? Data, let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            } else {
                // Found a saved value, but it couldn't be loaded. Presumably it was from
                // an older version of the cars app and is now incompatible. This data
                // isn't crucial, so let's just erase it so it's fixed for next time.
                UserDefaults.standard.removeObject(forKey: key)
                return defaultValue
            }
        } else {
            // No previously saved transports - use defaults
            return defaultValue
        }
    }

}
