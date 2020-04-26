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
    func setBoardDisk(_ disk: Disk?, at position: Board.Position)
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
        switch side {
        case .dark:
            self.interactor.darkPlayer = player
        case .light:
            self.interactor.lightPlayer = player
        }
        
        if let canceller = self.interactor.playerCancellers[side] {
            canceller.cancel()
        }
        
        if !self.interactor.isAnimating, side == self.interactor.turn, case .computer = player {
            self.interactor.playTurnOfComputer()
        }
    }
    
    func selectBoard(position: Board.Position) {
        guard let side = self.interactor.turn else { return }
        if self.interactor.isAnimating { return }
        guard case .manual = self.interactor.player(for: side) else { return }
        // try? because doing nothing when an error occurs
        try? self.placeDisk(side.disk, at: position, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
    
    func comfirmationOK() {
        #warning("interactorに移動したい？")
        self.interactor.animationCanceller?.cancel()
        self.interactor.animationCanceller = nil
        
        for side in Side.allCases {
            self.interactor.playerCancellers[side]?.cancel()
            self.interactor.playerCancellers.removeValue(forKey: side)
        }
        
        self.newGame()
        self.interactor.waitForPlayer()
    }
    
    func pass() {
        self.nextTurn()
    }
}

private extension Presenter {
    func newGame() {
        self.interactor.newGame()
        
        #warning("通知で呼び出す")
        self.displayer?.updateAll()
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == Board.Position
    {
        guard let position = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.interactor.animationCanceller!
        self.interactor.board.setDisk(disk, at: position)
        
        self.displayer?.setBoardDisk(disk, at: position, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for position in coordinates {
                    self.interactor.board.setDisk(disk, at: position)
                    self.displayer?.setBoardDisk(disk, at: position, animated: false, completion: nil)
                }
                completion(false)
            }
        }
    }
}

extension Presenter: InteractorDelegate {
    func didChangeTurn() {
        self.displayer?.updateMessageViews()
    }
    
    func willBeginComputerWaiting(side: Side) {
        self.displayer?.startPlayerActivityIndicatorAnimating(side: side)
    }
    
    func didEndComputerWaiting(side: Side) {
        self.displayer?.stopPlayerActivityIndicatorAnimating(side: side)
    }
}

#warning("Interactorに移動する")
extension Presenter {
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, at position: Board.Position, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = self.interactor.board.flippedDiskCoordinatesByPlacingDisk(disk, at: position)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, position: position)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.interactor.animationCanceller = nil
            }
            self.interactor.animationCanceller = Canceller(cleanUp)
            self.animateSettingDisks(at: [position] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.interactor.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                self.interactor.save()
                self.displayer?.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.interactor.board.setDisk(disk, at: position)
                self.displayer?.setBoardDisk(disk, at: position)
                for position in diskCoordinates {
                    self.interactor.board.setDisk(disk, at: position)
                    self.displayer?.setBoardDisk(disk, at: position)
                }
                completion?(true)
                self.interactor.save()
                self.displayer?.updateCountLabels()
            }
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard let currentSide = self.interactor.turn else { return }

        let nextSide = currentSide.flipped
        
        if self.interactor.board.validMoves(for: nextSide).isEmpty {
            if self.interactor.board.validMoves(for: currentSide).isEmpty {
                self.interactor.turn = nil
            } else {
                self.interactor.turn = nextSide
                
                self.displayer?.presentPassView()
            }
        } else {
            self.interactor.turn = nextSide
            self.interactor.waitForPlayer()
        }
    }
}
