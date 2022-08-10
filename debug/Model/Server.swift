//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation
import Network

struct Server: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Properties

    /// A UUID string which identifies this server. Only used locally in
    /// the cars app to save and update settings.
    let id: UUID

    /// A customizable user-friendly name intended to provide some
    /// context (for example "HyDRA integration cluster")
    let name: String

    /// Server host, as either an IPv4 address or hostname.
    let host: String

    /// Port number of the server for TCP connections, if enabled. TCP
    /// connections (effectively the same as our mDNS mesh protocol
    /// but with a fixed-IP instead of a dynamically discovered host).
    let tcpPort: UInt16?

    /// Port number of the server for Websocket connections, if enabled.
    /// If 443 then `wss://` will be used, otherwise `ws://`.
    let websocketPort: UInt16?

    // MARK: - Initializer

    /// Constructor. If `host` or `port` were invalid, returns nil, otherwise
    /// returns a valid `Server` object.
    ///
    /// - Parameters:
    ///   - name: A customizable user-friendly name intended to provide some
    ///           context (for example "HyDRA integration cluster")
    ///   - host: Server host, as either an IP address or hostname.
    ///   - port: Port number of the server. Cannot be 0.
    init?(id: UUID, name: String, host: String, tcpPort: UInt16?, websocketPort: UInt16?) {
        let validatedHost: String
        if IPv4Address(host) != nil {
            validatedHost = host
        } else if !host.isEmpty && host.unicodeScalars.allSatisfy({ CharacterSet.urlHostAllowed.contains($0) }) {
            validatedHost = host
        } else {
            print("Invalid host for server - must be either an IPv4 address or hostname: \(host)")
            return nil
        }

        self.id = id
        self.name = name.isEmpty ? "Server" : name
        self.host = validatedHost
        self.tcpPort = tcpPort
        self.websocketPort = websocketPort
    }

    // MARK: - Functions

    func urlString(formattedFor connectionType: ServerConnectionType) -> String {
        let port = self.port(for: connectionType)

        let portString = port?.description.prepending(":") ?? ""
        let schemeString = connectionType.scheme(forPort: port)

        return "\(schemeString)\(self.host)\(portString)"
    }

    func port(for connectionType: ServerConnectionType) -> UInt16? {
        switch connectionType {
        case .tcp: return self.tcpPort
        case .websocket: return self.websocketPort
        }
    }

}

extension Server: CustomStringConvertible {
    var description: String {
        self.host
    }
}

fileprivate extension String {
    func prepending(_ other: String) -> String {
        return other + self
    }
}
