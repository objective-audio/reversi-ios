import XCTest
@testable import Reversi

class BoardTests: XCTestCase {
    func testInitialDisks() {
        let disks = Board.initialDisks
        
        XCTAssertEqual(.init(disks), TestUtils.initialBoard)
    }
    
    func testAllPositions() {
        XCTAssertEqual(Board.allPositions.count, 64)
        
        var expected: [Position] = []
        for y in 0..<8 {
            for x in 0..<8 {
                expected.append(.init(x: x, y: y))
            }
        }
        
        XCTAssertEqual(Set(Board.allPositions), Set(expected))
    }
    
    func testInit() {
        let board = Board()
        
        XCTAssertEqual(board, TestUtils.initialBoard)
    }
    
    func testInitWithDisks() {
        let disks: [[Disk?]] = [
            [.light, nil, nil, nil, nil, nil, nil, .dark],
            [nil, .light, nil, nil, nil, nil, .dark, nil],
            [nil, nil, .light, nil, nil, .dark, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, .dark, nil, nil, .light, nil, nil],
            [nil, .dark, nil, nil, nil, nil, .light, nil],
            [.dark, nil, nil, nil, nil, nil, nil, .light]
        ]
        
        let board = Board(disks)
        
        for (y, diskLine) in disks.enumerated() {
            for (x, disk) in diskLine.enumerated() {
                XCTAssertEqual(board[.init(x: x, y: y)], disk)
            }
        }
    }
    
    func testDiskCount() {
        let disks: [[Disk?]] = [
            [.light, nil, nil, nil, nil, nil, nil, .dark],
            [.light, nil, nil, nil, nil, nil, .dark, .dark],
            [.light, nil, nil, nil, nil, .dark, .dark, .dark],
            [.light, nil, nil, nil, .dark, .dark, .dark, .dark],
            [.light, nil, nil, .dark, .dark, .dark, .dark, .dark],
            [.light, nil, .dark, .dark, .dark, .dark, .dark, .dark],
            [.light, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark]
        ]
        
        let board = Board(disks)
        
        XCTAssertEqual(board.diskCount(of: .light), 7)
        XCTAssertEqual(board.diskCount(of: .dark), 36)
    }
    
    func testSetDisk() {
        var board = TestUtils.emptyBoard
        
        let position = Position(x: 2, y: 3)
        
        Board.allPositions.forEach { XCTAssertNil(board[$0]) }
        
        XCTContext.runActivity(named: "lightを置いてセットされている") { _ in
            board[position] = .light
            
            Board.allPositions.forEach {
                switch $0 {
                case position:
                    XCTAssertEqual(board[$0], .light)
                default:
                    XCTAssertNil(board[$0])
                }
            }
        }
        
        XCTContext.runActivity(named: "darkを置いてセットされている") { _ in
            board[position] = .dark
            
            Board.allPositions.forEach {
                switch $0 {
                case position:
                    XCTAssertEqual(board[$0], .dark)
                default:
                    XCTAssertNil(board[$0])
                }
            }
        }
        
        XCTContext.runActivity(named: "nilを置いてセットされている") { _ in
            board[position] = nil
            
            Board.allPositions.forEach { XCTAssertNil(board[$0]) }
        }
    }
    
    func testFlippedDiskCoordinatesByPlacingDiskWithInitialDisks() {
        let board = Board()
        
        XCTContext.runActivity(named: "lightが置ける位置") { _ in
            Board.allPositions.forEach {
                let flippedDisks = board.flippedDiskCoordinatesByPlacingDisk(.light, at: $0)
                switch $0 {
                case .init(x: 4, y: 2), .init(x: 5, y: 3):
                    XCTAssertEqual(flippedDisks, [.init(x: 4, y: 3)])
                case .init(x: 2, y: 4), .init(x: 3, y: 5):
                    XCTAssertEqual(flippedDisks, [.init(x: 3, y: 4)])
                default:
                    XCTAssertEqual(flippedDisks, [])
                }
            }
        }
        
        XCTContext.runActivity(named: "darkが置ける位置") { _ in
            Board.allPositions.forEach {
                let flippedDisks = board.flippedDiskCoordinatesByPlacingDisk(.dark, at: $0)
                switch $0 {
                case .init(x: 3, y: 2), .init(x: 2, y: 3):
                    XCTAssertEqual(flippedDisks, [.init(x: 3, y: 3)])
                case .init(x: 5, y: 4), .init(x: 4, y: 5):
                    XCTAssertEqual(flippedDisks, [.init(x: 4, y: 4)])
                default:
                    XCTAssertEqual(flippedDisks, [])
                }
            }
        }
    }
    
    func testCanPlaceDiskWithInitialDisks() {
        let board = Board()
        
        XCTContext.runActivity(named: "lightを置けるか") { _ in
            let positions = Board.allPositions.filter { board.canPlaceDisk(.light, at: $0) }
            
            let expected: [Position] = [
                .init(x: 4, y: 2),
                .init(x: 5, y: 3),
                .init(x: 2, y: 4),
                .init(x: 3, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
        
        XCTContext.runActivity(named: "darkを置けるか") { _ in
            let positions = Board.allPositions.filter { board.canPlaceDisk(.dark, at: $0) }
            
            let expected: [Position] = [
                .init(x: 3, y: 2),
                .init(x: 2, y: 3),
                .init(x: 5, y: 4),
                .init(x: 4, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
    }
    
    func testResult() {
        XCTContext.runActivity(named: "lightとdarkが同じ数なら引き分け") { _ in
            var board = TestUtils.emptyBoard
            
            board[.init(x: 0, y: 0)] = .light
            board[.init(x: 0, y: 1)] = .dark
            
            XCTAssertEqual(board.result(), .tied)
        }
        
        XCTContext.runActivity(named: "lightが多ければlightの勝ち") { _ in
            var board = TestUtils.emptyBoard
            
            board[.init(x: 0, y: 0)] = .light
            board[.init(x: 1, y: 0)] = .light
            board[.init(x: 0, y: 1)] = .dark
            
            XCTAssertEqual(board.result(), .won(side: .light))
        }
        
        XCTContext.runActivity(named: "darkが多ければdarkの勝ち") { _ in
            var board = TestUtils.emptyBoard
            
            board[.init(x: 0, y: 0)] = .light
            board[.init(x: 0, y: 1)] = .dark
            board[.init(x: 1, y: 1)] = .dark
            
            XCTAssertEqual(board.result(), .won(side: .dark))
        }
    }
    
    func testValidMovesWithInitialDisks() {
        let board = Board()
        
        XCTContext.runActivity(named: "lightの置ける位置") { _ in
            let positions = board.validMoves(for: .light)
            
            let expected: [Position] = [
                .init(x: 4, y: 2),
                .init(x: 5, y: 3),
                .init(x: 2, y: 4),
                .init(x: 3, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
        
        XCTContext.runActivity(named: "darkの置ける位置") { _ in
            let positions = board.validMoves(for: .dark)
            
            let expected: [Position] = [
                .init(x: 3, y: 2),
                .init(x: 2, y: 3),
                .init(x: 5, y: 4),
                .init(x: 4, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
    }
}
