import XCTest
@testable import Reversi

private class DataStoreMock: DataStorable {
    var saveHandler: ((GameData) throws -> Void)?
    var loadHandler: (() throws -> GameData)?
    
    func save(_ data: GameData) throws {
        try self.saveHandler?(data)
    }
    
    func load() throws -> GameData {
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
    private var dataStore: DataStoreMock!
    private var eventReceiver: EventReceiverMock!
    private var computerThinking: ((Interactor.Computer) -> Void)!
    private var receivedEvents: [Interactor.Event] = []
    private var receivedComputers: [Interactor.Computer] = []
    private var savedData: [GameData] = []
    
    override func setUp() {
        self.dataStore = .init()
        self.eventReceiver = .init()
        
        self.eventReceiver.receiveHandler = { self.receivedEvents.append($0) }
        self.computerThinking = { self.receivedComputers.append($0) }
        self.dataStore.saveHandler = { self.savedData.append($0) }
    }
    
    override func tearDown() {
        self.savedData.removeAll()
        self.receivedComputers.removeAll()
        self.receivedEvents.removeAll()
        
        self.eventReceiver = nil
        self.dataStore = nil
        self.computerThinking = nil
        
    }
    
    func test_新規に起動した状態() {
        let interactor = Interactor(dataStore: self.dataStore)
        
        XCTAssertEqual(interactor.board, TestUtils.initialBoard)
        XCTAssertEqual(interactor.player(for: .dark), .manual)
        XCTAssertEqual(interactor.player(for: .light), .manual)
        XCTAssertEqual(interactor.state, .launching(side: .dark))
    }
    
    func test_ロードして起動した状態_ゲーム中() {
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
        
        XCTContext.runActivity(named: "白のターン、黒マニュアル、白コンピュータ") { _ in
            let expectation = self.expectation(description: "load from DataStore")
            
            self.dataStore.loadHandler = {
                expectation.fulfill()
                return .init(turn: .light,
                             darkPlayer: .manual,
                             lightPlayer: .computer,
                             board: .init(disks))
            }
            
            let interactor = Interactor(dataStore: self.dataStore)
            
            self.wait(for: [expectation], timeout: 0.0)
            
            XCTAssertEqual(interactor.board, .init(disks))
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .computer)
            XCTAssertEqual(interactor.state, .launching(side: .light))
        }
        
        XCTContext.runActivity(named: "黒のターン、白マニュアル、黒コンピュータ") { _ in
            let expectation = self.expectation(description: "load from DataStore")
            
            self.dataStore.loadHandler = {
                expectation.fulfill()
                return .init(turn: .dark,
                             darkPlayer: .computer,
                             lightPlayer: .manual,
                             board: .init(disks))
            }
            
            let interactor = Interactor(dataStore: self.dataStore)
            
            self.wait(for: [expectation], timeout: 0.0)
            
            XCTAssertEqual(interactor.board, .init(disks))
            XCTAssertEqual(interactor.player(for: .dark), .computer)
            XCTAssertEqual(interactor.player(for: .light), .manual)
            XCTAssertEqual(interactor.state, .launching(side: .dark))
        }
    }
    
    func test_ロードして起動した状態_引き分け() {
        let expectation = self.expectation(description: "load from DataStore")
        
        self.dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil,
                         darkPlayer: .computer,
                         lightPlayer: .manual,
                         board: TestUtils.tiedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        XCTAssertEqual(interactor.state, .result(.tied))
    }
    
    func test_ロードして起動した状態_白の勝ち() {
        let expectation = self.expectation(description: "load from DataStore")
        
        self.dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.lightWonBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        XCTAssertEqual(interactor.state, .result(.won(side: .light)))
    }
    
    func test_ロードして起動した状態_黒の勝ち() {
        let expectation = self.expectation(description: "load from DataStore")
        
        self.dataStore.loadHandler = {
            expectation.fulfill()
            return .init(turn: nil,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.darkWonBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        
        self.wait(for: [expectation], timeout: 0.0)
        
        XCTAssertEqual(interactor.state, .result(.won(side: .dark)))
    }
    
    func test_新規にゲームを開始して待機する() {
        let interactor = Interactor(dataStore: self.dataStore)
        
        XCTAssertEqual(interactor.state, .launching(side: .dark))
        
        interactor.doAction(.begin)
        
        XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
        XCTAssertEqual(self.receivedEvents.count, 0)
    }
    
    func test_ロードしてゲームを開始してマニュアルで待機する() {
        self.dataStore.loadHandler = {
            return .init(turn: .light,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.darkPlacedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        interactor.doAction(.begin)
        
        XCTAssertEqual(interactor.state, .waiting(side: .light, player: .manual))
        XCTAssertEqual(self.receivedEvents.count, 0)
    }
    
    func test_ロードしてゲームを開始してコンピュータで待機する() {
        self.dataStore.loadHandler = {
            return .init(turn: .light,
                         darkPlayer: .manual,
                         lightPlayer: .computer,
                         board: TestUtils.darkPlacedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        interactor.doAction(.begin)
        
        XCTAssertEqual(interactor.state, .waiting(side: .light, player: .computer))
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertEqual(self.receivedEvents[0], .willBeginComputerWaiting(side: .light))
    }
    
    func test_ロードしてゲームを開始してパスになる() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.darkPassBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        interactor.doAction(.begin)
        
        XCTAssertEqual(interactor.state, .passing(side: .dark))
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertEqual(self.receivedEvents.last, .didEnterPassing)
    }
    
    func test_マニュアルでの操作() {
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
        }
        
        XCTContext.runActivity(named: "黒のディスクを置く") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 3, y: 2)))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents.last, .didPlaceDisks(side: .dark, positions: [.init(x: 3, y: 2), .init(x: 3, y: 3)]))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクの配置が終わり、白のターン") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents.last, .didChangeTurn)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .light))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "白のディスクを置く") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 4, y: 2)))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents.last, .didPlaceDisks(side: .light, positions: [.init(x: 4, y: 2), .init(x: 4, y: 3)]))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクの配置が終わり、黒のターン") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents.last, .didChangeTurn)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
        }
    }
    
    func test_コンピュータでの操作() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .computer,
                         lightPlayer: .computer,
                         board: TestUtils.initialBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .willBeginComputerWaiting(side: .dark))
            
            XCTAssertEqual(self.receivedComputers.count, 1)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "コンピュータの思考が終わり、黒のディスクが置かれる") { _ in
            let position = Board.Position(x: 3, y: 2)
            let computer = self.receivedComputers[0]
            
            XCTAssertTrue(computer.positions.contains(position))
            
            computer.completion(position)
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[0], .didEndComputerWaiting(side: .dark))
            XCTAssertEqual(self.receivedEvents[1], .didPlaceDisks(side: .dark, positions: [.init(x: 3, y: 2), .init(x: 3, y: 3)]))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクの配置が終わり、白のターン") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .light))

            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[0], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[1], .willBeginComputerWaiting(side: .light))
            
            XCTAssertEqual(self.receivedComputers.count, 2)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "コンピュータの思考が終わり、白のディスクを置かれる") { _ in
            let position = Board.Position(x: 4, y: 2)
            let computer = self.receivedComputers[1]
            
            XCTAssertTrue(computer.positions.contains(position))
            
            computer.completion(position)
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[0], .didEndComputerWaiting(side: .light))
            XCTAssertEqual(self.receivedEvents[1], .didPlaceDisks(side: .light, positions: [.init(x: 4, y: 2), .init(x: 4, y: 3)]))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクの配置が終わり、黒のターン") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[0], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[1], .willBeginComputerWaiting(side: .dark))
        }
    }
    
    func test_マニュアルのパス() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.preLightPassBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
        }
        
        XCTContext.runActivity(named: "黒のディスクを置いて、白のターン、パスの待機") { _ in
            
            interactor.doAction(.placeDisk(at: .init(x: 1, y: 0)))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didPlaceDisks(side: .dark, positions: [.init(x: 1, y: 0), .init(x: 2, y: 0)]))
            
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 3)
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[2], .didEnterPassing)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .light))
            XCTAssertEqual(interactor.state, .passing(side: .light))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "パスして黒のターン") { _ in
            interactor.doAction(.pass)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didChangeTurn)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
        }
    }
    
    func test_コンピュータのパス() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .computer,
                         board: TestUtils.preLightPassBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
        }
        
        XCTContext.runActivity(named: "黒のディスクを置いて、白のターン、パスの待機") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 1, y: 0)))
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 3)
            XCTAssertEqual(self.receivedEvents[0], .didPlaceDisks(side: .dark, positions: [.init(x: 1, y: 0), .init(x: 2, y: 0)]))
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[2], .didEnterPassing)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .light))
            XCTAssertEqual(interactor.state, .passing(side: .light))
        }
        
        XCTContext.runActivity(named: "コンピュータの思考は開始しない") { _ in
            XCTAssertEqual(self.receivedComputers.count, 0)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "パスして黒のターン") { _ in
            interactor.doAction(.pass)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didChangeTurn)
            
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
        }
    }
    
    func test_プレイヤーをマニュアルからコンピュータに変更() {
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン、白黒ともマニュアル") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .manual)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
        }
        
        XCTContext.runActivity(named: "白のプレイヤーをコンピュータに変更、状態に影響なし") { _ in
            interactor.doAction(.changePlayer(.computer, side: .light))
            
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .computer)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
        }
        
        XCTContext.runActivity(named: "黒のプレイヤーをコンピュータに変更、状態が変更され、コンピュータの思考開始") { _ in
            XCTAssertEqual(self.receivedComputers.count, 0)
            
            interactor.doAction(.changePlayer(.computer, side: .dark))
            
            XCTAssertEqual(interactor.player(for: .dark), .computer)
            XCTAssertEqual(interactor.player(for: .light), .computer)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .computer))
            
            XCTAssertEqual(self.receivedComputers.count, 1)
        }
    }
    
    func test_プレイヤーをコンピュータからマニュアルに変更() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .computer,
                         lightPlayer: .computer,
                         board: TestUtils.initialBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン、白黒ともコンピュータ") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.player(for: .dark), .computer)
            XCTAssertEqual(interactor.player(for: .light), .computer)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .computer))
            
            XCTAssertEqual(self.receivedComputers.count, 1)
        }
        
        XCTContext.runActivity(named: "白のプレイヤーをマニュアルに変更、状態に影響がない") { _ in
            interactor.doAction(.changePlayer(.manual, side: .light))
            
            XCTAssertEqual(interactor.player(for: .dark), .computer)
            XCTAssertEqual(interactor.player(for: .light), .manual)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .computer))
        }
        
        XCTContext.runActivity(named: "黒のプレーヤーをマニュアルに変更、状態が変更され、コンピュータの思考停止") { _ in
            interactor.doAction(.changePlayer(.manual, side: .dark))
            
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .manual)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
            
            XCTAssertEqual(self.receivedComputers.count, 1)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "コンピュータの思考が完了しても何も起きない") { _ in
            let computer = self.receivedComputers[0]
            computer.completion(computer.positions[0])
            
            XCTAssertEqual(self.receivedEvents.count, 0)
        }
    }
    
    func test_ゲーム終了し引き分け() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.preTiedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 0)
        }
        
        XCTContext.runActivity(named: "黒の一手を置いて引き分け") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 6, y: 0)))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didPlaceDisks(side: .dark, positions: [.init(x: 6, y: 0), .init(x: 5, y: 0)]))
            
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(interactor.state, .result(.tied))
        }
    }
    
    func test_ゲーム終了し黒の勝ち() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.preDarkWonBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 0)
        }
        
        XCTContext.runActivity(named: "黒のディスクを置いて、黒の勝ち") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 6, y: 0)))
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didPlaceDisks(side: .dark, positions: [.init(x: 6, y: 0), .init(x: 5, y: 0)]))
            
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(interactor.state, .result(.won(side: .dark)))
        }
    }
    
    func test_白のマニュアル待機からリセット() {
        self.dataStore.loadHandler = {
            return .init(turn: .light,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.darkPlacedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、白マニュアルのターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 0)
            XCTAssertEqual(interactor.state, .waiting(side: .light, player: .manual))
        }
        
        XCTContext.runActivity(named: "リセットを呼んで初期状態に戻る") { _ in
            interactor.doAction(.reset)
            
            XCTAssertEqual(self.receivedEvents.count, 3)
            XCTAssertEqual(self.receivedEvents[0], .willReset)
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[2], .didReset)
            
            XCTAssertEqual(interactor.board, TestUtils.initialBoard)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .manual)
        }
    }
    
    func test_白のコンピュータ待機からリセット() {
        self.dataStore.loadHandler = {
            return .init(turn: .light,
                         darkPlayer: .manual,
                         lightPlayer: .computer,
                         board: TestUtils.darkPlacedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、白コンピュータのターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .willBeginComputerWaiting(side: .light))
            XCTAssertEqual(interactor.state, .waiting(side: .light, player: .computer))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "リセットを呼んで初期状態に戻る") { _ in
            interactor.doAction(.reset)
            
            XCTAssertEqual(self.receivedEvents.count, 4)
            XCTAssertEqual(self.receivedEvents[0], .willReset)
            XCTAssertEqual(self.receivedEvents[1], .didEndComputerWaiting(side: .light))
            XCTAssertEqual(self.receivedEvents[2], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[3], .didReset)
            
            XCTAssertEqual(interactor.board, TestUtils.initialBoard)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .manual)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "コンピュータの思考を完了させても何も起きない") { _ in
            let computer = self.receivedComputers[0]
            computer.completion(computer.positions[0])
            
            XCTAssertEqual(self.receivedEvents.count, 0)
        }
    }
    
    func test_パス待機からリセット() {
        self.dataStore.loadHandler = {
            return .init(turn: .dark,
                         darkPlayer: .manual,
                         lightPlayer: .manual,
                         board: TestUtils.darkPassBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、黒のパス待機") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 1)
            XCTAssertEqual(self.receivedEvents[0], .didEnterPassing)
            XCTAssertEqual(interactor.state, .passing(side: .dark))
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "リセットを呼んで初期状態に戻る") { _ in
            interactor.doAction(.reset)
            
            XCTAssertEqual(self.receivedEvents.count, 2)
            XCTAssertEqual(self.receivedEvents[0], .willReset)
            XCTAssertEqual(self.receivedEvents[1], .didReset)
            
            XCTAssertEqual(interactor.board, TestUtils.initialBoard)
            XCTAssertEqual(interactor.state, .waiting(side: .dark, player: .manual))
            XCTAssertEqual(interactor.player(for: .dark), .manual)
            XCTAssertEqual(interactor.player(for: .light), .manual)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "パスしても無視される") { ＿ in
            interactor.doAction(.pass)
            
            XCTAssertEqual(self.receivedEvents.count, 0)
        }
    }
    
    func test_ゲーム終了からリセット() {
        self.dataStore.loadHandler = {
            return .init(turn: nil,
                         darkPlayer: .manual,
                         lightPlayer: .computer,
                         board: TestUtils.tiedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始、引き分け") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(self.receivedEvents.count, 0)
            XCTAssertEqual(interactor.state, .result(.tied))
        }
        
        XCTContext.runActivity(named: "リセットを呼んで初期状態に戻る") { _ in
            interactor.doAction(.reset)
            
            XCTAssertEqual(self.receivedEvents.count, 3)
            XCTAssertEqual(self.receivedEvents[0], .willReset)
            XCTAssertEqual(self.receivedEvents[1], .didChangeTurn)
            XCTAssertEqual(self.receivedEvents[2], .didReset)
        }
    }
    
    func test_ターンの変更時に保存される() {
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        interactor.eventReceiver = self.eventReceiver
        
        XCTContext.runActivity(named: "ゲーム開始") { _ in
            interactor.doAction(.begin)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクを置いた時点では保存されない") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 3, y: 2)))
            
            XCTAssertFalse(self.receivedEvents.contains(.didChangeTurn))
            
            XCTAssertEqual(self.savedData.count, 0)
        }
        
        self.receivedEvents.removeAll()
        
        XCTContext.runActivity(named: "ディスクが置き終わったら保存される") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertTrue(self.receivedEvents.contains(.didChangeTurn))
            
            XCTAssertEqual(self.savedData.count, 1)
            XCTAssertEqual(self.savedData.last?.board, interactor.board)
            XCTAssertEqual(self.savedData.last?.darkPlayer, .manual)
            XCTAssertEqual(self.savedData.last?.lightPlayer, .manual)
            XCTAssertEqual(self.savedData.last?.turn, .light)
        }
    }
    
    func test_プレイヤーの変更時に保存される() {
        let interactor = Interactor(dataStore: self.dataStore, computerThinking: self.computerThinking)
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .dark))
            XCTAssertEqual(self.savedData.count, 0)
        }
        
        XCTContext.runActivity(named: "白のプレイヤーを変更したら保存される") { _ in
            interactor.doAction(.changePlayer(.computer, side: .light))
            
            XCTAssertEqual(self.savedData.count, 1)
            XCTAssertEqual(self.savedData.last?.darkPlayer, .manual)
            XCTAssertEqual(self.savedData.last?.lightPlayer, .computer)
        }
        
        self.savedData.removeAll()
        
        XCTContext.runActivity(named: "黒のプレイヤーを変更したら保存される") { _ in
            interactor.doAction(.changePlayer(.computer, side: .dark))
            
            XCTAssertEqual(self.savedData.count, 1)
            XCTAssertEqual(self.savedData.last?.darkPlayer, .computer)
            XCTAssertEqual(self.savedData.last?.lightPlayer, .computer)
        }
    }
    
    func test_リセット時に保存される() {
        self.dataStore.loadHandler = {
            return .init(turn: .light,
                         darkPlayer: .computer,
                         lightPlayer: .computer,
                         board: TestUtils.darkPlacedBoard)
        }
        
        let interactor = Interactor(dataStore: self.dataStore)
        
        XCTContext.runActivity(named: "ゲーム開始、白のターン") { _ in
            interactor.doAction(.begin)
            
            XCTAssertEqual(interactor.state.status, .turn(side: .light))
            XCTAssertEqual(self.savedData.count, 0)
        }
        
        XCTContext.runActivity(named: "リセットしたら保存される") { _ in
            interactor.doAction(.reset)
            
            XCTAssertEqual(self.savedData.count, 2) // turn変更のsaveが1回入っている
            
            XCTAssertEqual(self.savedData.last?.turn, .dark)
            XCTAssertEqual(self.savedData.last?.darkPlayer, .manual)
            XCTAssertEqual(self.savedData.last?.lightPlayer, .manual)
            XCTAssertEqual(self.savedData.last?.board, TestUtils.initialBoard)
        }
    }
    
    func test_ディスク配置後に位置を反映() {
        let interactor = Interactor(dataStore: self.dataStore)
        
        XCTContext.runActivity(named: "ゲーム開始、黒のターン") { _ in
            interactor.doAction(.begin)
        }
        
        XCTContext.runActivity(named: "ディスクを配置") { _ in
            interactor.doAction(.placeDisk(at: .init(x: 5, y: 4)))
            
            XCTAssertEqual(interactor.board, TestUtils.initialBoard)
        }
        
        XCTContext.runActivity(named: "ディスクの配置が終了し、位置が反映される") { _ in
            interactor.doAction(.endPlaceDisks)
            
            XCTAssertEqual(interactor.board, TestUtils.darkPlacedBoard)
        }
    }
}
