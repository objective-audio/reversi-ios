import Foundation

protocol Displayable: class {
    func updateAll()
    func updateCountLabels()
    func updateMessageViews()
    
    func startPlayerActivityIndicatorAnimating(side: Side)
    func stopPlayerActivityIndicatorAnimating(side: Side)
    
    func presentPassView()
    
    func setBoardDisk(_ disk: Disk?, at position: Board.Position, animated: Bool, completion: ((Bool) -> Void)?)
}

class Presenter {
    private let interactor: Interactor
    
    weak var displayer: Displayable?
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
        interactor.eventReceiver = self
    }
    
    var darkPlayer: Player { self.interactor.darkPlayer }
    var lightPlayer: Player { self.interactor.lightPlayer }
    
    var disks: [[Disk?]] { self.interactor.board.disks }
    
    var status: Status { self.interactor.status }
    
    func diskCount(of side: Side) -> Int {
        return self.interactor.board.diskCount(of: side)
    }
    
    func begin() {
        self.interactor.doAction(.begin)
    }
    
    func changePlayer(_ player: Player, side: Side) {
        self.interactor.doAction(.changePlayer(player, side: side))
    }
    
    func selectBoard(at position: Board.Position) {
        self.interactor.doAction(.placeDisk(position: position))
    }
    
    func reset() {
        self.interactor.doAction(.reset)
    }
    
    func pass() {
        self.interactor.doAction(.pass)
    }
}

extension Presenter: InteractorEventReceiver {
    func receiveEvent(_ event: InteractorEvent) {
        switch event {
        case .didBeginNewGame:
            self.displayer?.updateAll()
        case .didChangeTurn:
            self.displayer?.updateMessageViews()
        case .willBeginComputerWaiting(let side):
            self.displayer?.startPlayerActivityIndicatorAnimating(side: side)
        case .didEndComputerWaiting(let side):
            self.displayer?.stopPlayerActivityIndicatorAnimating(side: side)
        case .didEnterPassing:
            self.displayer?.presentPassView()
        case .didPlaceDisks(let side, let positions):
            self.didPlaceDisks(side: side, positions: positions)
        case .willReset:
            self.interactor.animationCanceller?.cancel()
            self.interactor.animationCanceller = nil
        }
    }
}

private extension Presenter {
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping () -> Void)
        where C.Element == Board.Position
    {
        guard let position = coordinates.first else {
            completion()
            return
        }
        
        let animationCanceller = self.interactor.animationCanceller!
        
        self.displayer?.setBoardDisk(disk, at: position, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for position in coordinates {
                    self.displayer?.setBoardDisk(disk, at: position, animated: false, completion: nil)
                }
                completion()
            }
        }
    }
    
    func didPlaceDisks(side: Side, positions: [Board.Position]) {
        let cleanUp: () -> Void = { [weak self] in
            self?.interactor.animationCanceller = nil
        }
        self.interactor.animationCanceller = Canceller(cleanUp)
        self.animateSettingDisks(at: positions, to: side.disk) { [weak self] in
            guard let self = self else { return }
            guard let canceller = self.interactor.animationCanceller else { return }
            if canceller.isCancelled { return }
            cleanUp()

            self.displayer?.updateCountLabels()
            
            self.interactor.doAction(.endPlaceDisks)
        }
    }
}
