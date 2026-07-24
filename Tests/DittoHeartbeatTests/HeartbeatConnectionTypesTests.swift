import XCTest
@testable import DittoHeartbeat

final class HeartbeatConnectionTypesTests: XCTestCase {
    func testPreservesEveryObservedConnectionType() {
        let counts = HeartbeatConnectionTypes.count([
            "Bluetooth",
            "AccessPoint",
            "WebSocket",
            "Multicast",
            "FutureTransport",
            "FutureTransport",
        ])
        XCTAssertEqual(counts["Bluetooth"], 1)
        XCTAssertEqual(counts["AccessPoint"], 1)
        XCTAssertEqual(counts["WebSocket"], 1)
        XCTAssertEqual(counts["Multicast"], 1)
        XCTAssertEqual(counts["FutureTransport"], 2)
    }

    func testPeerConnectionKeepsPublishedWireFieldsAndConnectionTypes() {
        let peer = DittoPeerConnection("peer", cx: [
            "isConnectedToDittoCloud": true,
            "bluetooth": 1,
            "p2pWifi": 2,
            "lan": 3,
            "connectionTypes": ["FutureTransport": 5],
        ])

        XCTAssertEqual(peer.value["isConnectedToDittoCloud"] as? Bool, true)
        XCTAssertEqual(
            peer.value["connectionTypes"] as? [String: Int],
            ["FutureTransport": 5]
        )
    }

    func testOldPeerDocumentStillDecodes() {
        let peer = DittoPeerConnection("peer", cx: [
            "isConnectedToDittoCloud": true,
            "bluetooth": 1,
            "p2pWifi": 2,
            "lan": 3,
        ])

        XCTAssertTrue(peer.isConnectedToDittoCloud)
        XCTAssertEqual(peer.bluetooth, 1)
        XCTAssertEqual(peer.p2pWifi, 2)
        XCTAssertEqual(peer.lan, 3)
        XCTAssertEqual(peer.connectionTypes, [:])
    }
}
