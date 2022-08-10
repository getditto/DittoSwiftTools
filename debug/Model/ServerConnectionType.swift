//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation

enum ServerConnectionType: CaseIterable {
    case tcp
    case websocket

    func scheme(forPort port: UInt16?) -> String {
        guard let port = port else {
            return ""
        }

        switch self {
        case .websocket where port == 443:
            return "wss://"
        case .websocket:
            return "ws://"
        case .tcp:
            return ""
        }
    }

    init?(from transport: Transport) {
        switch transport {
        case .tcpServer:
            self = .tcp
        case .websocketServer:
            self = .websocket
        default:
            return nil
        }
    }

    func toTransport() -> Transport {
        switch self {
        case .tcp:
            return .tcpServer
        case .websocket:
            return .websocketServer
        }
    }
}

// MARK: CustomStringConvertible

extension ServerConnectionType: CustomStringConvertible {
    var description: String {
        switch self {
        case .tcp: return "Static TCP"
        case .websocket: return "Websocket"
        }
    }
}
