import XCTest
@testable import Reversi

class SideTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Side.allCases, [.dark, .light])
    }
    
    func testFlipped() {
        XCTAssertEqual(Side.dark.flipped, .light)
        XCTAssertEqual(Side.light.flipped, .dark)
    }
    
    func testDisk() {
        XCTAssertEqual(Side.dark.disk, Disk.dark)
        XCTAssertEqual(Side.light.disk, Disk.light)
    }
}
