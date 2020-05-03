import XCTest
@testable import Reversi

class DataStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TestUtils.removeFile()
    }
    
    override func tearDown() {
        TestUtils.removeFile()
        super.tearDown()
    }
    
    func testLoad() {
        XCTContext.runActivity(named: "turn:dark, darkPlayer:manual, lightPlayer:computer") { _ in
            let string =
                """
                x01
                x------o
                -x----o-
                --x--o--
                ---xo---
                ---ox---
                --o--x--
                -o----x-
                o------x
                
                """
            
            TestUtils.writeToFile(string: string)
            
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
            
            XCTAssertEqual(loaded.board, .init(expectedBoard))
        }
        
        XCTContext.runActivity(named: "turn:light, darkPlayer:computer, lightPlayer:manual") { _ in
            let string =
                """
                o10
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                
                """
            
            TestUtils.writeToFile(string: string)
            
            guard let loaded = try? DataStore().load() else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(loaded.turn, .light)
            XCTAssertEqual(loaded.darkPlayer, .computer)
            XCTAssertEqual(loaded.lightPlayer, .manual)
        }
        
        XCTContext.runActivity(named: "turn:none") { _ in
            let string =
                """
                -00
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                
                """
            
            TestUtils.writeToFile(string: string)
            
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
                let disks: [[Disk?]] = [
                    [.dark, nil, nil, nil, nil, nil, nil, .light],
                    [nil, .dark, nil, nil, nil, nil, .light, nil],
                    [nil, nil, .dark, nil, nil, .light, nil, nil],
                    [nil, nil, nil, .dark, .light, nil, nil, nil],
                    [nil, nil, nil, .light, .dark, nil, nil, nil],
                    [nil, nil, .light, nil, nil, .dark, nil, nil],
                    [nil, .light, nil, nil, nil, nil, .dark, nil],
                    [.light, nil, nil, nil, nil, nil, nil, .dark],
                ]
                
                try DataStore().save(.init(turn: .dark, darkPlayer: .manual, lightPlayer: .computer, board: .init(disks)))
            } catch {
                XCTFail()
                return
            }
            
            let expected =
                """
                x01
                x------o
                -x----o-
                --x--o--
                ---xo---
                ---ox---
                --o--x--
                -o----x-
                o------x
                
                """
            
            XCTAssertEqual(TestUtils.loadFromFile(), expected)
        }
        
        XCTContext.runActivity(named: "turn:light, darkPlayer:computer, lightPlayer:manual") { _ in
            do {
                try DataStore().save(.init(turn: .light, darkPlayer: .computer, lightPlayer: .manual, board: .init(TestUtils.emptyDisks)))
            } catch {
                XCTFail()
                return
            }
            
            let expected =
                """
                o10
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                
                """
            
            XCTAssertEqual(TestUtils.loadFromFile(), expected)
        }
        
        XCTContext.runActivity(named: "turn:none") { _ in
            do {
                try DataStore().save(.init(turn: nil, darkPlayer: .manual, lightPlayer: .manual, board: .init(TestUtils.emptyDisks)))
            } catch {
                XCTFail()
                return
            }
            
            let expected =
                """
                -00
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                --------
                
                """
            
            XCTAssertEqual(TestUtils.loadFromFile(), expected)
        }
    }
}
