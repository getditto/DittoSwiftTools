//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import Foundation

enum Transport: String, CaseIterable, Codable, Equatable, Hashable {
    case bluetooth
    case wifi
    case awdl
    case tcpServer
    case websocketServer

    static var p2pTransports: [Self] {
        [.bluetooth, .wifi, .awdl]
    }

    static var serverTransports: [Self] {
        [.tcpServer, .websocketServer]
    }
}

// MARK: CustomStringConvertible

extension Transport: CustomStringConvertible {
    var description: String {
        switch self {
        case .bluetooth:
            return "Bluetooth"
        case .wifi:
            return "mDNS"
        case .awdl:
            return "AWDL"
        case .tcpServer:
            return "Static TCP"
        case .websocketServer:
            return "Websocket"
        }
    }
}
