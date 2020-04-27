import XCTest
@testable import Reversi

class BoardTests: XCTestCase {
    func testInitialDisks() {
        let disks = Board.initialDisks()
        
        let expect: [[Disk?]] = [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
        
        XCTAssertEqual(disks.count, expect.count)
        for (y, diskLine) in disks.enumerated() {
            let expectLine = expect[y]
            for x in 0..<8 {
                XCTAssertEqual(diskLine[x], expectLine[x])
            }
        }
    }
}
