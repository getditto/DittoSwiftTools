import DittoSwift
import XCTest
@testable import DittoPresenceDegradation

final class PresenceDegradationConnectionTypesTests: XCTestCase {
    func testLanUsesAccessPointEnumCase() {
        let connectionTypes: [DittoConnectionType] = [
            .accessPoint,
            .webSocket,
            .accessPoint,
            .bluetooth,
        ]

        XCTAssertEqual(countLanConnections(connectionTypes), 2)
    }
}
