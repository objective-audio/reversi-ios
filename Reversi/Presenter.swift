import Foundation

protocol Displayable: class {
    func updateAll()
    func updateCountLabels()
    
    #warning("completionを無くしたい?")
    func setBoardDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)?)
    func setBoardDisk(_ disk: Disk?, atX x: Int, y: Int)
    
    #warning("残すつもりはない")
    func playTurnOfComputer()
}

class Presenter {
    private let interactor: Interactor
    
    weak var displayer: Displayable?
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    var playerCancellers: [Disk: Canceller] = [:]
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
    }
    
    var turn: Disk? {
        get { self.interactor.turn }
        set { self.interactor.turn = newValue }
    }
    
    var darkPlayer: Player {
        get { self.interactor.darkPlayer }
        set { self.interactor.darkPlayer = newValue }
    }
    
    var lightPlayer: Player {
        get { self.interactor.lightPlayer }
        set { self.interactor.lightPlayer = newValue }
    }
    
    func player(for side: Disk) -> Player {
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
    
    var disks: [[Disk?]] { self.interactor.board.disks }
    
    func setDisks(_ disks: [[Disk?]]) {
        self.interactor.board.setDisks(disks)
    }
    
    func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        self.interactor.board.setDisk(disk, atX: x, y: y)
    }
    
    func diskAt(x: Int, y: Int) -> Disk? {
        self.interactor.board.diskAt(x: x, y: y)
    }
    
    func resetDisks() {
        self.interactor.board.resetDisks()
    }
    
    func diskCount(of side: Disk) -> Int {
        return self.interactor.board.diskCount(of: side)
    }
    
    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        return self.interactor.board.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
    }
    
    func sideWithMoreDisks() -> Disk? {
        return self.interactor.board.sideWithMoreDisks()
    }
    
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        return self.interactor.board.canPlaceDisk(disk, atX: x, y: y)
    }
    
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        return self.interactor.board.validMoves(for: side)
    }
    
    func newGame() {
        self.interactor.newGame()
        
        #warning("通知で呼び出す")
        self.displayer?.updateAll()
    }
    
    func load() throws {
        try self.interactor.load()
        
        #warning("通知で呼び出す")
        self.displayer?.updateAll()
    }
    
    func save() {
        self.interactor.save()
    }
    
    #warning("interactorに移動したい")
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = self.turn else { return }
        switch self.player(for: turn) {
        case .manual:
            break
        case .computer:
            self.displayer?.playTurnOfComputer()
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        self.setDisk(disk, atX: x, y: y)
        
        self.displayer?.setBoardDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.setDisk(disk, atX: x, y: y)
                    self.displayer?.setBoardDisk(disk, atX: x, y: y, animated: false, completion: nil)
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
        let diskCoordinates = self.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            self.animationCanceller = Canceller(cleanUp)
            self.animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                self.save()
                self.displayer?.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setDisk(disk, atX: x, y: y)
                self.displayer?.setBoardDisk(disk, atX: x, y: y)
                for (x, y) in diskCoordinates {
                    self.setDisk(disk, atX: x, y: y)
                    self.displayer?.setBoardDisk(disk, atX: x, y: y)
                }
                completion?(true)
                self.save()
                self.displayer?.updateCountLabels()
            }
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
}
