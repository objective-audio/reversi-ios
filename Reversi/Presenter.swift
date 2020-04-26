import Foundation

protocol Displayable: class {
    func updateAll()
    func updateCountLabels()
    func updateMessageViews()
    
    func startPlayerActivityIndicatorAnimating(side: Disk)
    func stopPlayerActivityIndicatorAnimating(side: Disk)
    
    func presentPassView()
    
    #warning("completionを無くしたい?")
    func setBoardDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)?)
    func setBoardDisk(_ disk: Disk?, atX x: Int, y: Int)
}

class Presenter {
    enum Status {
        case turn(side: Disk)
        case won(side: Disk)
        case tied
    }
    
    private let interactor: Interactor
    
    weak var displayer: Displayable?
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    private var playerCancellers: [Disk: Canceller] = [:]
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
    }
    
    private(set) var turn: Disk? {
        get { self.interactor.turn }
        set {
            self.interactor.turn = newValue
            #warning("interactor経由にする")
            self.displayer?.updateMessageViews()
        }
    }
    
    var darkPlayer: Player { self.interactor.darkPlayer }
    var lightPlayer: Player { self.interactor.lightPlayer }
    
    func player(for side: Disk) -> Player {
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
    
    var disks: [[Disk?]] { self.interactor.board.disks }
    
    var status: Status {
        switch self.turn {
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
    
    func diskCount(of side: Disk) -> Int {
        return self.interactor.board.diskCount(of: side)
    }
    
    private var _began: Bool = false
    func begin() {
        #warning("処理を無視するのはステートでやる")
        guard !self._began else { return }
        self._began = true
        self.waitForPlayer()
    }
    
    func changePlayer(_ player: Player, side: Disk) {
        switch side {
        case .dark:
            self.interactor.darkPlayer = player
        case .light:
            self.interactor.lightPlayer = player
        }
        
        self.interactor.save()
        
        if let canceller = self.playerCancellers[side] {
            canceller.cancel()
        }
        
        if !self.isAnimating, side == self.turn, case .computer = player {
            self.playTurnOfComputer()
        }
    }
    
    func selectBoard(position: Board.Position) {
        guard let turn = self.turn else { return }
        if self.isAnimating { return }
        guard case .manual = self.player(for: turn) else { return }
        // try? because doing nothing when an error occurs
        try? self.placeDisk(turn, atX: position.x, y: position.y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
    
    func comfirmationOK() {
        #warning("interactorに移動したい？")
        self.animationCanceller?.cancel()
        self.animationCanceller = nil
        
        for side in Disk.allCases {
            self.playerCancellers[side]?.cancel()
            self.playerCancellers.removeValue(forKey: side)
        }
        
        self.newGame()
        self.waitForPlayer()
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
        
        let animationCanceller = self.animationCanceller!
        self.interactor.board.setDisk(disk, atX: position.x, y: position.y)
        
        self.displayer?.setBoardDisk(disk, atX: position.x, y: position.y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for position in coordinates {
                    self.interactor.board.setDisk(disk, atX: position.x, y: position.y)
                    self.displayer?.setBoardDisk(disk, atX: position.x, y: position.y, animated: false, completion: nil)
                }
                completion(false)
            }
        }
    }
    
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = self.interactor.board.flippedDiskCoordinatesByPlacingDisk(disk, at: .init(x: x, y: y))
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            self.animationCanceller = Canceller(cleanUp)
            self.animateSettingDisks(at: [.init(x: x, y: y)] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                self.interactor.save()
                self.displayer?.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.interactor.board.setDisk(disk, atX: x, y: y)
                self.displayer?.setBoardDisk(disk, atX: x, y: y)
                for position in diskCoordinates {
                    self.interactor.board.setDisk(disk, atX: position.x, y: position.y)
                    self.displayer?.setBoardDisk(disk, atX: position.x, y: position.y)
                }
                completion?(true)
                self.interactor.save()
                self.displayer?.updateCountLabels()
            }
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.turn else { preconditionFailure() }
        let position = self.interactor.board.validMoves(for: turn).randomElement()!

        self.displayer?.startPlayerActivityIndicatorAnimating(side: turn)
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.displayer?.stopPlayerActivityIndicatorAnimating(side: turn)
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, atX: position.x, y: position.y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        self.playerCancellers[turn] = canceller
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = self.turn else { return }

        turn.flip()
        
        if self.interactor.board.validMoves(for: turn).isEmpty {
            if self.interactor.board.validMoves(for: turn.flipped).isEmpty {
                self.turn = nil
            } else {
                self.turn = turn
                
                self.displayer?.presentPassView()
            }
        } else {
            self.turn = turn
            self.waitForPlayer()
        }
    }
    
    #warning("interactorに移動したい")
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = self.turn else { return }
        switch self.player(for: turn) {
        case .manual:
            break
        case .computer:
            self.playTurnOfComputer()
        }
    }
}
