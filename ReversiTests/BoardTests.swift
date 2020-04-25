import XCTest
@testable import Reversi

class BoardTests: XCTestCase {
    func testEmptyDisks() {
        let disks = Board.emptyDisks()
        
        XCTAssertEqual(disks.count, 8)
        for diskLine in disks {
            XCTAssertEqual(diskLine.count, 8)
            for disk in diskLine {
                XCTAssertNil(disk)
            }
        }
    }
}
