import DittoExportData
import XCTest

final class PublicNamesTests: XCTestCase {
    #if os(macOS)
    func testExportDataMacOSCompatibilityNameCompiles() {
        let compatibilityType: ExportData_macOS.Type = ExportDataMacOS.self

        XCTAssertTrue(compatibilityType == ExportDataMacOS.self)
    }
    #endif
}
