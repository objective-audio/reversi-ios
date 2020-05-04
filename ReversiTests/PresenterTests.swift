import XCTest
@testable import Reversi

private class InteractorMock: Interactable {
    var stateHandler: () -> State = { fatalError() }
    var boardHandler: () -> Board = { fatalError() }
    var playerHandler: (Side) -> Player = { _ in fatalError() }
    var actionHandler: ((Interactor.Action) -> Void)?
    func sendEvent(_ event: Interactor.Event) { self.eventReceiver?.receiveEvent(event) }
    
    var eventReceiver: InteractorEventReceiver?
    
    var state: State { self.stateHandler() }
    var board: Board { self.boardHandler() }
    
    func player(for side: Side) -> Player {
        self.playerHandler(side)
    }
    
    func doAction(_ action: Interactor.Action) {
        self.actionHandler?(action)
    }
}

private class EventReceiverMock: PresenterEventReceiver {
    var receiveHandler: ((Presenter.Event) -> Void)?
    
    func receiveEvent(_ event: Presenter.Event) {
        self.receiveHandler?(event)
    }
}

class PresenterTests: XCTestCase {
    private var interactor: InteractorMock!
    private var receivedActions: [Interactor.Action] = []
    private var eventReceiver: EventReceiverMock!
    private var receivedEvents: [Presenter.Event] = []
    
    override func setUp() {
        self.interactor = .init()
        self.eventReceiver = .init()
        
        self.interactor.actionHandler = { self.receivedActions.append($0) }
        self.eventReceiver.receiveHandler = { self.receivedEvents.append($0) }
    }
    
    override func tearDown() {
        self.eventReceiver = nil
        self.interactor = nil
        
        self.receivedEvents.removeAll()
        self.receivedActions.removeAll()
    }
    
    func testStatus() {
        let presenter = Presenter(interactor: self.interactor)
        
        self.interactor.stateHandler = { .operating(side: .dark, player: .manual) }
        
        XCTAssertEqual(presenter.status, .turn(side: .dark))
        
        self.interactor.stateHandler = { .result(.won(side: .light)) }
        
        XCTAssertEqual(presenter.status, .result(.won(side: .light)))
    }
    
    func testBoard() {
        let presenter = Presenter(interactor: self.interactor)
        
        self.interactor.boardHandler = { TestUtils.initialBoard }
        
        XCTAssertEqual(presenter.board, TestUtils.initialBoard)
    }
    
    func testPlayerForSide() {
        let presenter = Presenter(interactor: self.interactor)
        
        self.interactor.playerHandler = {
            switch $0 {
            case .dark: return .manual
            case .light: return .computer
            }
        }
        
        XCTAssertEqual(presenter.player(for: .dark), .manual)
        XCTAssertEqual(presenter.player(for: .light), .computer)
    }
    
    func testAction() {
        let presenter = Presenter(interactor: self.interactor)
        
        presenter.viewDidAppear()
        
        XCTAssertEqual(self.receivedActions.count, 1)
        XCTAssertEqual(self.receivedActions[0], .begin)
        
        presenter.changePlayer(.computer, side: .light)
        
        XCTAssertEqual(self.receivedActions.count, 2)
        XCTAssertEqual(self.receivedActions[1], .changePlayer(.computer, side: .light))
        
        presenter.selectBoard(at: .init(x: 3, y: 4))
        
        XCTAssertEqual(self.receivedActions.count, 3)
        XCTAssertEqual(self.receivedActions[2], .placeDisk(at: .init(x: 3, y: 4)))
        
        presenter.reset()
        
        XCTAssertEqual(self.receivedActions.count, 4)
        XCTAssertEqual(self.receivedActions[3], .reset)
        
        presenter.pass()
        
        XCTAssertEqual(self.receivedActions.count, 5)
        XCTAssertEqual(self.receivedActions[4], .pass)
    }
    
    func testEventReceiver() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        
        XCTAssertEqual(self.receivedEvents.count, 4)
        XCTAssertTrue(self.receivedEvents.contains(.updateBoardView))
        XCTAssertTrue(self.receivedEvents.contains(.updatePlayerControls))
        XCTAssertTrue(self.receivedEvents.contains(.updateCountLabels))
        XCTAssertTrue(self.receivedEvents.contains(.updateMessageViews))
        
        self.receivedEvents.removeAll()
        
        presenter.eventReceiver = nil
        
        XCTAssertEqual(self.receivedEvents.count, 0)
    }
    
    func testReceiveDidChangeTurn() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didChangeTurn)
        
        XCTAssertEqual(self.receivedEvents.count, 2)
        XCTAssertTrue(self.receivedEvents.contains(.updateCountLabels))
        XCTAssertTrue(self.receivedEvents.contains(.updateMessageViews))
    }
    
    func testReceiveDidEnterComputerOperating() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didEnterComputerOperating(side: .dark))
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertTrue(self.receivedEvents.contains(.startPlayerActivityIndicatorAnimating(side: .dark)))
    }
    
    func testReceiveWillExitComputerOperating() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.willExitComputerOperating(side: .light))
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertTrue(self.receivedEvents.contains(.stopPlayerActivityIndicatorAnimating(side: .light)))
    }
    
    func testReceiveDidEnterPassing() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didEnterPassing)
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertTrue(self.receivedEvents.contains(.presentPassView))
    }
    
    func testReceiveWillReset() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.willReset)
        
        XCTAssertEqual(self.receivedEvents.count, 0)
    }
    
    func testReceiveDidReset() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didReset)
        
        XCTAssertEqual(self.receivedEvents.count, 3)
        XCTAssertTrue(self.receivedEvents.contains(.updateBoardView))
        XCTAssertTrue(self.receivedEvents.contains(.updatePlayerControls))
        XCTAssertTrue(self.receivedEvents.contains(.updateCountLabels))
    }
    
    func testReceiveDidPlaceDisk_最後までアニメーションする() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        let positions: [Position] = [.init(x: 0, y: 0),
                                     .init(x: 0, y: 1),
                                     .init(x: 0, y: 2)]
        
        self.interactor.sendEvent(.didPlaceDisks(side: .light,
                                                 positions: positions))
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        
        guard case .setBoardViewDisk(_, _, let receivedID) = self.receivedEvents.first, let animationID = receivedID else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(self.receivedEvents.last, .setBoardViewDisk(.light, at: positions[0], animationID: animationID))
        
        self.receivedEvents.removeAll()
        
        presenter.endSetBoardDisk(animationID: animationID, isFinished: true)
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertEqual(self.receivedEvents.last, .setBoardViewDisk(.light, at: positions[1], animationID: animationID))
        
        self.receivedEvents.removeAll()
        
        presenter.endSetBoardDisk(animationID: animationID, isFinished: true)
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertEqual(self.receivedEvents.last, .setBoardViewDisk(.light, at: positions[2], animationID: animationID))
        
        self.receivedEvents.removeAll()
        
        XCTAssertEqual(self.receivedActions.count, 0)
        
        presenter.endSetBoardDisk(animationID: animationID, isFinished: true)
        
        XCTAssertEqual(self.receivedEvents.count, 0)
        XCTAssertEqual(self.receivedActions.count, 1)
        
        XCTAssertEqual(self.receivedActions.last, .endPlaceDisks)
    }
    
    func testReceivedDidPlaceDisk_途中でアニメーション中断() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        let positions: [Position] = [.init(x: 0, y: 0),
                                     .init(x: 0, y: 1),
                                     .init(x: 0, y: 2)]
        
        self.interactor.sendEvent(.didPlaceDisks(side: .light,
                                                 positions: positions))
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        
        guard case .setBoardViewDisk(_, _, let receivedID) = self.receivedEvents.first, let animationID = receivedID else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(self.receivedEvents.last, .setBoardViewDisk(.light, at: positions[0], animationID: animationID))
        
        self.receivedEvents.removeAll()
        
        XCTAssertEqual(self.receivedActions.count, 0)
        
        presenter.endSetBoardDisk(animationID: animationID, isFinished: false)
        
        XCTAssertEqual(self.receivedEvents.count, 2)
        XCTAssertEqual(self.receivedEvents[0], .setBoardViewDisk(.light, at: positions[1], animationID: nil))
        XCTAssertEqual(self.receivedEvents[1], .setBoardViewDisk(.light, at: positions[2], animationID: nil))
        
        XCTAssertEqual(self.receivedActions.count, 1)
        XCTAssertEqual(self.receivedActions.last, .endPlaceDisks)
    }
}
