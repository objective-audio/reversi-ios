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
        
        case setBoardDisk(_ disk: Disk?, at: Board.Position, animated: Bool, completion: ((Bool) -> Void)?)
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
    
    private var animationID: Identifier?
    
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
        self.interactor?.doAction(.placeDisk(position: position))
    }
    
    func reset() {
        self.interactor?.doAction(.reset)
    }
    
    func pass() {
        self.interactor?.doAction(.pass)
    }
}

extension Presenter: InteractorEventReceiver {
    func receiveEvent(_ event: Interactor.Event) {
        switch event {
        case .didChangeTurn:
            self.sendEvent(.updateMessageViews)
        case .willBeginComputerWaiting(let side):
            self.sendEvent(.startPlayerActivityIndicatorAnimating(side: side))
        case .didEndComputerWaiting(let side):
            self.sendEvent(.stopPlayerActivityIndicatorAnimating(side: side))
        case .didEnterPassing:
            self.sendEvent(.presentPassView)
        case .didPlaceDisks(let side, let positions):
            self.didPlaceDisks(side: side, positions: positions)
        case .willReset:
            self.animationID = nil
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
        let animationID = Identifier()
        
        self.animationID = animationID
        
        self.animateSettingDisks(at: positions, to: side.disk) { [weak self] in
            guard let self = self else { return }
            guard self.animationID == animationID else { return }
            self.animationID = nil

            self.sendEvent(.updateCountLabels)
            
            self.interactor?.doAction(.endPlaceDisks)
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    func animateSettingDisks<C: Collection>(at coordinates: C,
                                            to disk: Disk,
                                            completion: @escaping () -> Void) where C.Element == Board.Position {
        guard let position = coordinates.first else {
            completion()
            return
        }
        
        guard let animationID = self.animationID else { return }
        
        self.sendEvent(.setBoardDisk(disk, at: position, animated: true, completion: { [weak self] isFinished in
            guard let self = self else { return }
            guard self.animationID == animationID else { return }
            
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for position in coordinates {
                    self.sendEvent(.setBoardDisk(disk, at: position, animated: false, completion: nil))
                }
                completion()
            }
        }))
    }
    
    func sendEvent(_ event: Event) {
        self.eventReceiver?.receiveEvent(event)
    }
}

extension Interactor: Interactable {}
