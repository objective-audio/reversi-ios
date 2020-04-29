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

private class EventReceiverMock: InteractorEventReceiver {
    var receiveHandler: ((Interactor.Event) -> Void)?
    
    func receiveEvent(_ event: Interactor.Event) {
        self.receiveHandler?(event)
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
    
    func testBeginNewGame() {
        let dataStore = DataStoreMock()
        let eventReceiver = EventReceiverMock()
        
        var receivedEvents: [Interactor.Event] = []
        
        eventReceiver.receiveHandler = { event in
            receivedEvents.append(event)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        
        if case .launching(let side) = interactor.state {
            XCTAssertEqual(side, .dark)
        } else {
            XCTFail()
        }
        
        interactor.doAction(.begin)
        
        if case .waiting(let side, let player) = interactor.state {
            XCTAssertEqual(side, .dark)
            XCTAssertEqual(player, .manual)
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(receivedEvents.count, 0)
    }
    
    func testBeginManualWaiting() {
        let dataStore = DataStoreMock()
        let eventReceiver = EventReceiverMock()
        
        var receivedEvents: [Interactor.Event] = []
        
        let disks: [[Disk?]] = [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
        
        dataStore.loadHandler = {
            return .init(turn: .light, darkPlayer: .manual, lightPlayer: .manual, board: disks)
        }
        
        eventReceiver.receiveHandler = { event in
            receivedEvents.append(event)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        interactor.eventReceiver = eventReceiver
        
        interactor.doAction(.begin)
        
        if case .waiting(let side, let player) = interactor.state {
            XCTAssertEqual(side, .light)
            XCTAssertEqual(player, .manual)
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(receivedEvents.count, 0)
    }
    
    func testBeginComputerWaiting() {
        let dataStore = DataStoreMock()
        let eventReceiver = EventReceiverMock()
        
        var receivedEvents: [Interactor.Event] = []
        
        let disks: [[Disk?]] = [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
        
        dataStore.loadHandler = {
            return .init(turn: .light, darkPlayer: .manual, lightPlayer: .computer, board: disks)
        }
        
        eventReceiver.receiveHandler = { event in
            receivedEvents.append(event)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        interactor.eventReceiver = eventReceiver
        
        interactor.doAction(.begin)
        
        if case .waiting(let side, let player) = interactor.state {
            XCTAssertEqual(side, .light)
            XCTAssertEqual(player, .computer)
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0], .willBeginComputerWaiting(side: .light))
    }
    
    func testBeginPass() {
        let dataStore = DataStoreMock()
        let eventReceiver = EventReceiverMock()
        
        var receivedEvents: [Interactor.Event] = []
        
        dataStore.loadHandler = {
            return .init(turn: .dark, darkPlayer: .manual, lightPlayer: .manual, board: TestUtils.darkPassDisks)
        }
        
        eventReceiver.receiveHandler = { event in
            receivedEvents.append(event)
        }
        
        let interactor = Interactor(dataStore: dataStore)
        interactor.eventReceiver = eventReceiver
        
        interactor.doAction(.begin)
        
        if case .passing(let side) = interactor.state {
            XCTAssertEqual(side, .dark)
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents.last, .didEnterPassing)
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
