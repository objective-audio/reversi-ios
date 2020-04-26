import XCTest
@testable import Reversi

class SideTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Side.allCases, [.dark, .light])
    }
}
