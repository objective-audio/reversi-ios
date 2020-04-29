import XCTest
@testable import Reversi

class BoardTests: XCTestCase {
    func testInitialDisks() {
        let disks = Board.initialDisks()
        
        XCTAssertEqual(disks, self.initialDisks)
    }
    
    func testInit() {
        let board = Board()
        
        XCTAssertEqual(board.disks, self.initialDisks)
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
        
        XCTAssertEqual(board.disks, disks)
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
        var board = Board(self.emptyDisks)
        
        let position = Board.Position(x: 2, y: 3)
        
        self.allPositions.forEach { XCTAssertNil(board[$0]) }
        
        board[position] = .light
        
        self.allPositions.forEach {
            switch $0 {
            case position:
                XCTAssertEqual(board[$0], .light)
            default:
                XCTAssertNil(board[$0])
            }
        }
        
        board[position] = .dark
        
        self.allPositions.forEach {
            switch $0 {
            case position:
                XCTAssertEqual(board[$0], .dark)
            default:
                XCTAssertNil(board[$0])
            }
        }
        
        board[position] = nil
        
        self.allPositions.forEach { XCTAssertNil(board[$0]) }
    }
    
    func testFlippedDiskCoordinatesByPlacingDiskWithInitialDisks() {
        let board = Board()
        
        XCTContext.runActivity(named: "lightが置ける位置") { _ in
            self.allPositions.forEach {
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
            self.allPositions.forEach {
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
            let positions = self.allPositions.filter { board.canPlaceDisk(.light, at: $0) }
            
            let expected: [Board.Position] = [
                .init(x: 4, y: 2),
                .init(x: 5, y: 3),
                .init(x: 2, y: 4),
                .init(x: 3, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
        
        XCTContext.runActivity(named: "darkを置けるか") { _ in
            let positions = self.allPositions.filter { board.canPlaceDisk(.dark, at: $0) }
            
            let expected: [Board.Position] = [
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
            var board = Board(self.emptyDisks)
            
            board[.init(x: 0, y: 0)] = .light
            board[.init(x: 0, y: 1)] = .dark
            
            XCTAssertEqual(board.result(), .tied)
        }
        
        XCTContext.runActivity(named: "lightが多ければlightの勝ち") { _ in
            var board = Board(self.emptyDisks)
            
            board[.init(x: 0, y: 0)] = .light
            board[.init(x: 1, y: 0)] = .light
            board[.init(x: 0, y: 1)] = .dark
            
            XCTAssertEqual(board.result(), .won(side: .light))
        }
        
        XCTContext.runActivity(named: "darkが多ければdarkの勝ち") { _ in
            var board = Board(self.emptyDisks)
            
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
            
            let expected: [Board.Position] = [
                .init(x: 4, y: 2),
                .init(x: 5, y: 3),
                .init(x: 2, y: 4),
                .init(x: 3, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
        
        XCTContext.runActivity(named: "darkの置ける位置") { _ in
            let positions = board.validMoves(for: .dark)
            
            let expected: [Board.Position] = [
                .init(x: 3, y: 2),
                .init(x: 2, y: 3),
                .init(x: 5, y: 4),
                .init(x: 4, y: 5)
            ]
            
            XCTAssertEqual(Set(positions), Set(expected))
        }
    }
}

private extension BoardTests {
    var initialDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    var emptyDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    var allPositions: [Board.Position] {
        var positions: [Board.Position] = []
        Board.yRange.forEach { y in
            Board.xRange.forEach { x in
                positions.append(.init(x: x, y: y))
            }
        }
        return positions
    }
}
