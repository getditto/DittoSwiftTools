//
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import DittoSwift

extension DittoRemotePeer: Hashable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.deviceName == rhs.deviceName
            && lhs.connections == rhs.connections
            && lhs.rssi == rhs.rssi
            && lhs.approximateDistanceInMeters == rhs.approximateDistanceInMeters
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.deviceName)
        hasher.combine(self.connections)
        hasher.combine(self.rssi)
        hasher.combine(self.approximateDistanceInMeters)
    }

}
