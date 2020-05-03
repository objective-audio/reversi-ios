import Foundation

protocol Interactable: class {
    var eventReceiver: InteractorEventReceiver? { get set }
    
    var state: State { get }
    var board: Board { get }
    func player(for side: Side) -> Player
    
    func doAction(_ action: Interactor.Action)
}

protocol PresenterEventReceiver: class {
    func receiveEvent(_ event: Presenter.Event)
}

extension Presenter {
    enum Event {
        case updateBoardView
        case updatePlayerControls
        case updateCountLabels
        case updateMessageViews
        
        case startPlayerActivityIndicatorAnimating(side: Side)
        case stopPlayerActivityIndicatorAnimating(side: Side)
        
        case presentPassView
        
        case setBoardViewDisk(_ disk: Disk, at: Board.Position, animationID: Identifier?)
    }
}

class Presenter {
    private weak var interactor: Interactable?
    
    weak var eventReceiver: PresenterEventReceiver? {
        didSet {
            if self.eventReceiver != nil {
                self.updateViewsForInitial()
            }
        }
    }
    
    class DiskAnimation {
        let id: Identifier = .init()
        let disk: Disk
        var remainPositions: [Board.Position]
        
        init(disk: Disk, positions: [Board.Position]) {
            self.disk = disk
            self.remainPositions = positions
        }
    }
    private var animation: DiskAnimation?
    
    init(interactor: Interactable) {
        self.interactor = interactor
        interactor.eventReceiver = self
    }
    
    func player(for side: Side) -> Player? { self.interactor?.player(for: side) }
    
    var disks: [[Disk?]]? { self.interactor?.board.disks }
    
    var status: Status? { self.interactor?.state.status }
    
    func diskCount(of side: Side) -> Int? {
        return self.interactor?.board.diskCount(of: side)
    }
    
    func viewDidAppear() {
        self.interactor?.doAction(.begin)
    }
    
    func changePlayer(_ player: Player, side: Side) {
        self.interactor?.doAction(.changePlayer(player, side: side))
    }
    
    func selectBoard(at position: Board.Position) {
        self.interactor?.doAction(.placeDisk(at: position))
    }
    
    func reset() {
        self.interactor?.doAction(.reset)
    }
    
    func pass() {
        self.interactor?.doAction(.pass)
    }
    
    func endSetBoardDisk(animationID: Identifier, isFinished: Bool) {
        guard let animation = self.animation else { return }
        
        if animation.remainPositions.isEmpty {
            self.endSetBoardViewDisks()
        } else if isFinished {
            self.setNextBoardViewDisk(animation: animation)
        } else {
            for position in animation.remainPositions {
                self.sendEvent(.setBoardViewDisk(animation.disk, at: position, animationID: nil))
            }
            self.endSetBoardViewDisks()
        }
    }
}

extension Presenter: InteractorEventReceiver {
    func receiveEvent(_ event: Interactor.Event) {
        switch event {
        case .didChangeTurn:
            self.sendEvent(.updateMessageViews)
            self.sendEvent(.updateCountLabels)
        case .willBeginComputerWaiting(let side):
            self.sendEvent(.startPlayerActivityIndicatorAnimating(side: side))
        case .didEndComputerWaiting(let side):
            self.sendEvent(.stopPlayerActivityIndicatorAnimating(side: side))
        case .didEnterPassing:
            self.sendEvent(.presentPassView)
        case .didPlaceDisks(let side, let positions):
            self.didPlaceDisks(side: side, positions: positions)
        case .willReset:
            self.animation = nil
        case .didReset:
            self.updateViewsForReset()
        }
    }
}

private extension Presenter {
    func updateViewsForInitial() {
        self.sendEvent(.updateBoardView)
        self.sendEvent(.updatePlayerControls)
        self.sendEvent(.updateCountLabels)
        self.sendEvent(.updateMessageViews)
    }
    
    func updateViewsForReset() {
        self.sendEvent(.updateBoardView)
        self.sendEvent(.updatePlayerControls)
        self.sendEvent(.updateCountLabels)
    }
    
    func didPlaceDisks(side: Side, positions: [Board.Position]) {
        let animation = DiskAnimation(disk: side.disk, positions: positions)
        self.animation = animation
        self.setNextBoardViewDisk(animation: animation)
    }
    
    func setNextBoardViewDisk(animation: DiskAnimation) {
        guard let position = animation.popPosition() else { fatalError() }
        self.sendEvent(.setBoardViewDisk(animation.disk, at: position, animationID: animation.id))
    }
    
    func endSetBoardViewDisks() {
        self.animation = nil
        self.interactor?.doAction(.endPlaceDisks)
    }
    
    func sendEvent(_ event: Event) {
        self.eventReceiver?.receiveEvent(event)
    }
}

private extension Presenter.DiskAnimation {
    func popPosition() -> Board.Position? {
        if self.remainPositions.isEmpty {
            return nil
        } else {
            return self.remainPositions.removeFirst()
        }
    }
}

extension Interactor: Interactable {}
