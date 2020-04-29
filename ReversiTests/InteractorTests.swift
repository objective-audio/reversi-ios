import XCTest
@testable import Reversi

private class DataStoreMock: InteractorDataStore {
    var saveHandler: ((DataStore.Parameters) throws -> Void)?
    var loadHandler: (() throws -> DataStore.Parameters)?
    
    func save(_ parameters: DataStore.Parameters) throws {
        try self.saveHandler?(parameters)
    }
    
    func load() throws -> DataStore.Parameters {
        guard let handler = self.loadHandler else {
            throw TestError.handlerNotFound
        }
        
        return try handler()
    }
    
    enum TestError: Error {
        case handlerNotFound
    }
}

class InteractorTests: XCTestCase {
    func testNewGame() {
        let dataStore = DataStoreMock()
        let interactor = Interactor(dataStore: dataStore)
        
        XCTAssertEqual(interactor.board.disks, TestUtils.initialDisks)
        XCTAssertEqual(interactor.darkPlayer, .manual)
        XCTAssertEqual(interactor.lightPlayer, .manual)
        
        if case .launching(let side) = interactor.state {
            XCTAssertEqual(side, .dark)
        } else {
            XCTFail()
        }
    }
    
    func testLoadGame() {
        let dataStore = DataStoreMock()
        
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
        
        XCTContext.runActivity(named: "turn:light, darkPlayer:manual, lightPlayer:computer") { _ in
            let expectation = self.expectation(description: "load from DataStore")
            
            dataStore.loadHandler = {
                expectation.fulfill()
                return .init(turn: .light, darkPlayer: .manual, lightPlayer: .computer, board: disks)
            }
            
            let interactor = Interactor(dataStore: dataStore)
            
            self.wait(for: [expectation], timeout: 0.0)
            
            XCTAssertEqual(interactor.board.disks, disks)
            XCTAssertEqual(interactor.darkPlayer, .manual)
            XCTAssertEqual(interactor.lightPlayer, .computer)
            
            if case .launching(let side) = interactor.state {
                XCTAssertEqual(side, .light)
            } else {
                XCTFail()
            }
        }
        
        XCTContext.runActivity(named: "turn:dark, darkPlayer:computer, lightPlayer:manual") { _ in
            let expectation = self.expectation(description: "load from DataStore")
            
            dataStore.loadHandler = {
                expectation.fulfill()
                return .init(turn: .dark, darkPlayer: .computer, lightPlayer: .manual, board: disks)
            }
            
            let interactor = Interactor(dataStore: dataStore)
            
            self.wait(for: [expectation], timeout: 0.0)
            
            XCTAssertEqual(interactor.board.disks, disks)
            XCTAssertEqual(interactor.darkPlayer, .computer)
            XCTAssertEqual(interactor.lightPlayer, .manual)
            
            if case .launching(let side) = interactor.state {
                XCTAssertEqual(side, .dark)
            } else {
                XCTFail()
            }
        }
    }
    
    func testBeginGame() {
        #warning("todo")
    }
    
    func testBeginPass() {
        #warning("todo")
    }
    
    func testLoadResultTied() {
        let dataStore = DataStoreMock()
        
        let disks: [[Disk?]] = [
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
        
        let expectation = self.expectation(description: "load from DataStore")
        
        dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil, darkPlayer: .computer, lightPlayer: .manual, board: disks)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        guard case .result(.tied) = interactor.state else {
            XCTFail()
            return
        }
    }
    
    func testLoadResultLightWon() {
        let dataStore = DataStoreMock()
        
        let disks: [[Disk?]] = [
            [.light, .light, .light, .light, .light, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
        
        let expectation = self.expectation(description: "load from DataStore")
        
        dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil, darkPlayer: .manual, lightPlayer: .manual, board: disks)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        guard case .result(.won(side: .light)) = interactor.state else {
            XCTFail()
            return
        }
    }
    
    func testLoadResultDarkWon() {
        let dataStore = DataStoreMock()
        
        let disks: [[Disk?]] = [
            [.light, .light, .light, .dark, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
        
        let expectation = self.expectation(description: "load from DataStore")
        
        dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil, darkPlayer: .manual, lightPlayer: .manual, board: disks)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        guard case .result(.won(side: .dark)) = interactor.state else {
            XCTFail()
            return
        }
    }
    
    func testResetFromManualWaiting() {
        #warning("todo")
    }
    
    func testResetFromComputerWaiting() {
        #warning("todo")
    }
    
    func testResetFromPassing() {
        #warning("todo")
    }
    
    func testResetFromResult() {
        #warning("todo")
    }
}
