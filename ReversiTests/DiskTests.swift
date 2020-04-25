import XCTest
@testable import Reversi

class DiskTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Disk.allCases, [.dark, .light])
    }
    
    func testMakeWithIndex() {
        XCTAssertEqual(Disk(index: 0), .dark)
        XCTAssertEqual(Disk(index: 1), .light)
    }
    
    func testGetIndex() {
        XCTAssertEqual(Disk.dark.index, 0)
        XCTAssertEqual(Disk.light.index, 1)
    }
}
