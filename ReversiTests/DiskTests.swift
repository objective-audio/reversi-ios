import XCTest
@testable import Reversi

class DiskTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Disk.allCases, [.dark, .light])
    }
}
