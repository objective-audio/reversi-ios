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
    private var eventReceiver: EventReceiverMock!
    private var receivedEvents: [Presenter.Event] = []
    
    override func setUp() {
        self.interactor = .init()
        self.eventReceiver = .init()
        
        self.eventReceiver.receiveHandler = { self.receivedEvents.append($0) }
    }
    
    override func tearDown() {
        self.eventReceiver = nil
        self.interactor = nil
    }
    
    func testStatus() {
        let presenter = Presenter(interactor: self.interactor)
        
        self.interactor.stateHandler = { .waiting(side: .dark, player: .manual) }
        
        XCTAssertEqual(presenter.status, .turn(side: .dark))
        
        self.interactor.stateHandler = { .result(.won(side: .light)) }
        
        XCTAssertEqual(presenter.status, .result(.won(side: .light)))
    }
    
    func testDisks() {
        let presenter = Presenter(interactor: self.interactor)
        
        self.interactor.boardHandler = { .init(TestUtils.initialDisks) }
        
        XCTAssertEqual(presenter.disks, TestUtils.initialDisks)
    }
    
    func testAction() {
        let presenter = Presenter(interactor: self.interactor)
        
        var actions: [Interactor.Action] = []
        
        self.interactor.actionHandler = { action in
            actions.append(action)
        }
        
        presenter.viewDidAppear()
        
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0], .begin)
        
        presenter.changePlayer(.computer, side: .light)
        
        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(actions[1], .changePlayer(.computer, side: .light))
        
        presenter.selectBoard(at: .init(x: 3, y: 4))
        
        XCTAssertEqual(actions.count, 3)
        XCTAssertEqual(actions[2], .placeDisk(at: .init(x: 3, y: 4)))
        
        presenter.reset()
        
        XCTAssertEqual(actions.count, 4)
        XCTAssertEqual(actions[3], .reset)
        
        presenter.pass()
        
        XCTAssertEqual(actions.count, 5)
        XCTAssertEqual(actions[4], .pass)
    }
    
    func testInitial() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        
        self.interactor.eventReceiver = presenter
        
        XCTAssertEqual(self.receivedEvents.count, 4)
        XCTAssertTrue(self.receivedEvents.contains(.updateBoardView))
        XCTAssertTrue(self.receivedEvents.contains(.updatePlayerControls))
        XCTAssertTrue(self.receivedEvents.contains(.updateCountLabels))
        XCTAssertTrue(self.receivedEvents.contains(.updateMessageViews))
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
    
    func testReceiveWillBeginComputerWaiting() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.willBeginComputerWaiting(side: .dark))
        
        XCTAssertEqual(self.receivedEvents.count, 1)
        XCTAssertTrue(self.receivedEvents.contains(.startPlayerActivityIndicatorAnimating(side: .dark)))
    }
    
    func testReceiveDidEndComputerWaiting() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didEndComputerWaiting(side: .light))
        
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
    
    func testReceiveDidPlaceDisk() {
        let presenter = Presenter(interactor: self.interactor)
        presenter.eventReceiver = self.eventReceiver
        self.interactor.eventReceiver = presenter
        
        self.receivedEvents.removeAll()
        
        self.interactor.sendEvent(.didPlaceDisks(side: .light,
                                                 positions: [.init(x: 0, y: 0), .init(x: 0, y: 1)]))
        
        #warning("todo")
    }
}
