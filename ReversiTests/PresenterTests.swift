import XCTest
@testable import Reversi

private class InteractorMock: Interactable {
    var stateHandler: () -> State = { fatalError() }
    var boardHandler: () -> Board = { fatalError() }
    var playerHandler: (Side) -> Player = { _ in fatalError() }
    var actionHandler: ((Interactor.Action) -> Void)?
    
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
    
    override func setUp() {
        self.interactor = .init()
    }
    
    override func tearDown() {
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
}
