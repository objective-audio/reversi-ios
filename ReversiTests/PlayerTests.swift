import XCTest
@testable import Reversi

class PlayerTests: XCTestCase {
    func testRawValue() {
        XCTAssertEqual(Player.manual.rawValue, 0)
        XCTAssertEqual(Player.computer.rawValue, 1)
    }
    
    func testFlipped() {
        XCTAssertEqual(Player.manual.flipped, .computer)
        XCTAssertEqual(Player.computer.flipped, .manual)
    }
}
