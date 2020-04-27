import Foundation

protocol Displayable: class {
    func updateAll()
    func updateCountLabels()
    func updateMessageViews()
    
    func startPlayerActivityIndicatorAnimating(side: Side)
    func stopPlayerActivityIndicatorAnimating(side: Side)
    
    func presentPassView()
    
    #warning("completionを無くしたい?")
    func setBoardDisk(_ disk: Disk?, at position: Board.Position, animated: Bool, completion: ((Bool) -> Void)?)
}

class Presenter {
    enum Status {
        case turn(side: Side)
        case won(side: Side)
        case tied
    }
    
    private let interactor: Interactor
    
    weak var displayer: Displayable?
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
        interactor.delegate = self
    }
    
    var darkPlayer: Player { self.interactor.darkPlayer }
    var lightPlayer: Player { self.interactor.lightPlayer }
    
    var disks: [[Disk?]] { self.interactor.board.disks }
    
    var status: Status {
        switch self.interactor.turn {
        case .some(let side):
            return .turn(side: side)
        case .none:
            if let winner = self.interactor.board.sideWithMoreDisks() {
                return .won(side: winner)
            } else {
                return .tied
            }
        }
    }
    
    func diskCount(of side: Side) -> Int {
        return self.interactor.board.diskCount(of: side)
    }
    
    private var _began: Bool = false
    func begin() {
        #warning("処理を無視するのはステートでやる")
        guard !self._began else { return }
        self._began = true
        self.interactor.waitForPlayer()
    }
    
    func changePlayer(_ player: Player, side: Side) {
        self.interactor.setPlayer(player, side: side)
    }
    
    func selectBoard(at position: Board.Position) {
        self.interactor.placeDiskByManual(at: position)
    }
    
    func reset() {
        self.interactor.reset()
    }
    
    func pass() {
        self.interactor.nextTurn()
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
}

extension Presenter: InteractorDelegate {
    func didBeginNewGame() {
        self.displayer?.updateAll()
    }
    
    func didChangeTurn() {
        self.displayer?.updateMessageViews()
    }
    
    func willBeginComputerWaiting(side: Side) {
        self.displayer?.startPlayerActivityIndicatorAnimating(side: side)
    }
    
    func didEndComputerWaiting(side: Side) {
        self.displayer?.stopPlayerActivityIndicatorAnimating(side: side)
    }
    
    func noPlaceToPutDisk() {
        self.displayer?.presentPassView()
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
            
            self.interactor.nextTurn()
        }
    }
}
