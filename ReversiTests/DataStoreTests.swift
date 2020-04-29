import XCTest
@testable import Reversi

class DataStoreTests: XCTestCase {
    func testLoad() {
        XCTContext.runActivity(named: "turn:dark, darkPlayer:manual, lightPlayer:computer") { _ in
            let string = [
                "x01\n",
                "x------o\n",
                "-x----o-\n",
                "--x--o--\n",
                "---xo---\n",
                "---ox---\n",
                "--o--x--\n",
                "-o----x-\n",
                "o------x\n",
            ].joined()
            
            self.writeToFile(string: string)
            
            guard let loaded = try? DataStore().load() else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(loaded.turn, .dark)
            XCTAssertEqual(loaded.darkPlayer, .manual)
            XCTAssertEqual(loaded.lightPlayer, .computer)
            
            let expectedBoard: [[Disk?]] = [
                [.dark, nil, nil, nil, nil, nil, nil, .light],
                [nil, .dark, nil, nil, nil, nil, .light, nil],
                [nil, nil, .dark, nil, nil, .light, nil, nil],
                [nil, nil, nil, .dark, .light, nil, nil, nil],
                [nil, nil, nil, .light, .dark, nil, nil, nil],
                [nil, nil, .light, nil, nil, .dark, nil, nil],
                [nil, .light, nil, nil, nil, nil, .dark, nil],
                [.light, nil, nil, nil, nil, nil, nil, .dark],
            ]
            
            XCTAssertEqual(loaded.board, expectedBoard)
        }
        
        XCTContext.runActivity(named: "turn:light, darkPlayer:computer, lightPlayer:manual") { _ in
            let string = [
                "o10\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
            ].joined()
            
            self.writeToFile(string: string)
            
            guard let loaded = try? DataStore().load() else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(loaded.turn, .light)
            XCTAssertEqual(loaded.darkPlayer, .computer)
            XCTAssertEqual(loaded.lightPlayer, .manual)
        }
        
        XCTContext.runActivity(named: "turn:none") { _ in
            let string = [
                "-00\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
            ].joined()
            
            self.writeToFile(string: string)
            
            guard let loaded = try? DataStore().load() else {
                XCTFail()
                return
            }
            
            XCTAssertNil(loaded.turn)
        }
    }
    
    func testSave() {
        XCTContext.runActivity(named: "turn:dark, darkPlayer:manual, lightPlayer:computer") { _ in
            do {
                let board: [[Disk?]] = [
                    [.dark, nil, nil, nil, nil, nil, nil, .light],
                    [nil, .dark, nil, nil, nil, nil, .light, nil],
                    [nil, nil, .dark, nil, nil, .light, nil, nil],
                    [nil, nil, nil, .dark, .light, nil, nil, nil],
                    [nil, nil, nil, .light, .dark, nil, nil, nil],
                    [nil, nil, .light, nil, nil, .dark, nil, nil],
                    [nil, .light, nil, nil, nil, nil, .dark, nil],
                    [.light, nil, nil, nil, nil, nil, nil, .dark],
                ]
                
                try DataStore().save(.init(turn: .dark, darkPlayer: .manual, lightPlayer: .computer, board: board))
            } catch {
                XCTFail()
                return
            }
            
            let expected = [
                "x01\n",
                "x------o\n",
                "-x----o-\n",
                "--x--o--\n",
                "---xo---\n",
                "---ox---\n",
                "--o--x--\n",
                "-o----x-\n",
                "o------x\n",
            ].joined()
            
            XCTAssertEqual(self.loadFromFile(), expected)
        }
        
        XCTContext.runActivity(named: "turn:light, darkPlayer:computer, lightPlayer:manual") { _ in
            do {
                let board: [[Disk?]] = [
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]
                
                try DataStore().save(.init(turn: .light, darkPlayer: .computer, lightPlayer: .manual, board: board))
            } catch {
                XCTFail()
                return
            }
            
            let expected = [
                "o10\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
            ].joined()
            
            XCTAssertEqual(self.loadFromFile(), expected)
        }
        
        XCTContext.runActivity(named: "turn:none") { _ in
            do {
                let board: [[Disk?]] = [
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]
                
                try DataStore().save(.init(turn: nil, darkPlayer: .manual, lightPlayer: .manual, board: board))
            } catch {
                XCTFail()
                return
            }
            
            let expected = [
                "-00\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
                "--------\n",
            ].joined()
            
            XCTAssertEqual(self.loadFromFile(), expected)
        }
    }
}

private extension DataStoreTests {
    var url: URL {
        guard let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Game") else { fatalError() }
        return url
    }
    
    func writeToFile(string: String) {
        try! string.write(to: self.url, atomically: true, encoding: .utf8)
    }
    
    func loadFromFile() -> String {
        return try! String(contentsOf: self.url)
    }
}
