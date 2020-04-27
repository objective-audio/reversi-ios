import Foundation

protocol InteractorDelegate: class {
    func didBeginNewGame()
    func didChangeTurn()
    func willBeginComputerWaiting(side: Side)
    func didEndComputerWaiting(side: Side)
    func noPlaceToPutDisk()
    func didPlaceDisks(side: Side, positions: [Board.Position])
}

class Interactor {
    weak var delegate: InteractorDelegate?
    
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Side? = .dark {
        didSet {
            if self.turn != oldValue {
                self.save()
                self.delegate?.didChangeTurn()
            }
        }
    }
    
    #warning("init時に読み込んだ値をセットする")
    var darkPlayer: Player = .manual {
        didSet {
            if self.darkPlayer != oldValue {
                self.save()
                self.didChangePlayer(side: .dark)
            }
        }
    }
    var lightPlayer: Player = .manual {
        didSet {
            if self.lightPlayer != oldValue {
                self.save()
                self.didChangePlayer(side: .light)
            }
        }
    }
    
    private(set) var state: State = .launching
    let dataStore: DataStore
    #warning("init時にdiskをセットする")
    var board: Board = .init()
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    private var playerCancellers: [Side: Canceller] = [:]
    
    init(dataStore: DataStore = .init()) {
        self.dataStore = dataStore
        
        do {
            try self.load()
        } catch {
            self.newGame()
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let side = self.turn else { preconditionFailure() }
        let position = self.board.validMoves(for: side).randomElement()!

        self.delegate?.willBeginComputerWaiting(side: side)
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.delegate?.didEndComputerWaiting(side: side)
            self.playerCancellers[side] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(at: position)
        }
        
        self.playerCancellers[side] = canceller
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let side = self.turn else { return }
        switch self.player(for: side) {
        case .manual:
            break
        case .computer:
            self.playTurnOfComputer()
        }
    }
    
    func player(for side: Side) -> Player {
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard let currentSide = self.turn else { return }

        let nextSide = currentSide.flipped
        
        if self.board.validMoves(for: nextSide).isEmpty {
            if self.board.validMoves(for: currentSide).isEmpty {
                self.turn = nil
            } else {
                self.turn = nextSide
                
                self.delegate?.noPlaceToPutDisk()
            }
        } else {
            self.turn = nextSide
            self.waitForPlayer()
        }
    }
    
    func reset() {
        self.animationCanceller?.cancel()
        self.animationCanceller = nil
        
        for side in Side.allCases {
            self.playerCancellers[side]?.cancel()
            self.playerCancellers.removeValue(forKey: side)
        }
        
        self.newGame()
        self.waitForPlayer()
    }
    
    func setPlayer(_ player: Player, side: Side) {
        switch side {
        case .dark:
            self.darkPlayer = player
        case .light:
            self.lightPlayer = player
        }
    }
    
    func placeDiskByManual(at position: Board.Position) {
        guard let side = self.turn else { return }
        if self.isAnimating { return }
        guard case .manual = self.player(for: side) else { return }
        
        try? self.placeDisk(at: position)
    }
}

private extension Interactor {
    func load() throws {
        let parameters = try self.dataStore.load()
        
        self.board.setDisks(parameters.board)
        self.turn = parameters.turn
        self.darkPlayer = parameters.darkPlayer
        self.lightPlayer = parameters.lightPlayer
    }
    
    func save() {
        try? self.dataStore.save(.init(turn: self.turn,
                                       darkPlayer: self.darkPlayer,
                                       lightPlayer: self.lightPlayer,
                                       board: self.board.disks))
    }
    
    func newGame() {
        self.board.resetDisks()
        self.turn = .dark
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.delegate?.didBeginNewGame()
    }
    
    func placeDisk(at position: Board.Position) throws {
        guard let side = self.turn else {
            throw DiskPlacementError(disk: nil, position: position)
        }
        
        let disk = side.disk
        
        let diskCoordinates = self.board.flippedDiskCoordinatesByPlacingDisk(disk, at: position)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, position: position)
        }
        
        let positions = [position] + diskCoordinates
        
        positions.forEach { self.board.setDisk(disk, at: $0) }
        
        self.delegate?.didPlaceDisks(side: side, positions: positions)
    }
    
    func didChangePlayer(side: Side) {
        if let canceller = self.playerCancellers[side] {
            canceller.cancel()
        }
        
        if !self.isAnimating, side == self.turn, case .computer = self.player(for: side) {
            self.playTurnOfComputer()
        }
    }
}

struct DiskPlacementError: Error {
    let disk: Disk?
    let position: Board.Position
}
