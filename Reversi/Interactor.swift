import Foundation

enum InteractorEvent {
    case didBeginNewGame
    case didChangeTurn
    case willBeginComputerWaiting(side: Side)
    case didEndComputerWaiting(side: Side)
    case didEnterPassing
    case didPlaceDisks(side: Side, positions: [Board.Position])
    case willReset
}

protocol InteractorEventReceiver: class {
    func receiveEvent(_ event: InteractorEvent)
}

enum Action {
    case begin
    case placeDisk(position: Board.Position)
    case endPlaceDisks
    case changePlayer(_ player: Player, side: Side)
    case pass
    case reset
}

class Interactor {
    weak var eventReceiver: InteractorEventReceiver?
    
    var darkPlayer: Player {
        didSet {
            if self.darkPlayer != oldValue {
                self.save()
                self.didChangePlayer(self.darkPlayer, side: .dark)
            }
        }
    }
    var lightPlayer: Player {
        didSet {
            if self.lightPlayer != oldValue {
                self.save()
                self.didChangePlayer(self.lightPlayer, side: .light)
            }
        }
    }
    
    private(set) var state: State {
        willSet {
            #warning("同じなら処理しない")
            
            switch self.state {
            case .waiting(let side, let player):
                if case .computer = player {
                    self.playerCanceller?.cancel()
                    self.eventReceiver?.receiveEvent(.didEndComputerWaiting(side: side))
                }
            default:
                break
            }
        }
        didSet {
            #warning("同じなら処理しない")
            
            if self.state.turn != oldValue.turn {
                self.save()
                self.eventReceiver?.receiveEvent(.didChangeTurn)
            }
            
            switch self.state {
            case .passing:
                self.eventReceiver?.receiveEvent(.didEnterPassing)
            case .waiting(let side, let player):
                if case .computer = player {
                    self.eventReceiver?.receiveEvent(.willBeginComputerWaiting(side: side))
                    self.playTurnOfComputer(side: side)
                }
            case .placing(let side, let positions):
                positions.forEach { self.board.setDisk(side.disk, at: $0) }
                self.eventReceiver?.receiveEvent(.didPlaceDisks(side: side, positions: positions))
            default:
                break
            }
        }
    }
    
    let dataStore: DataStore
    var board: Board
    
    private let computerDuration: TimeInterval
    private var playerCanceller: Canceller?
    
    init(dataStore: DataStore = .init(),
         computerDuration: TimeInterval = 2.0) {
        self.dataStore = dataStore
        self.computerDuration = computerDuration
        
        do {
            let parameters = try self.dataStore.load()
            
            self.darkPlayer = parameters.darkPlayer
            self.lightPlayer = parameters.lightPlayer
            
            let board = Board(disks: parameters.board)
            self.board = board
            
            #warning("整理したい")
            switch parameters.turn {
            case .some(let side):
                switch side {
                case .dark:
                    self.state = .launching(side: .dark)
                case .light:
                    self.state = .launching(side: .light)
                }
            case .none:
                self.state = .result(board.result())
            }
        } catch {
            self.darkPlayer = .manual
            self.lightPlayer = .manual
            self.board = .init()
            self.state = .launching(side: .dark)
        }
    }
    
    func doAction(_ action: Action) {
        switch action {
        case .begin:
            if case .launching(let side) = self.state {
                if self.board.validMoves(for: side).isEmpty {
                    self.state = .passing(side: side)
                } else {
                    self.waitForPlayer(side: side)
                }
            }
        case .changePlayer(let player, let side):
            switch self.state {
            case .launching:
                fatalError()
            default:
                switch side {
                case .dark: self.darkPlayer = player
                case .light: self.lightPlayer = player
                }
            }
        case .placeDisk(let position):
            switch self.state {
            case .waiting(let side, player: .manual):
                if self.board.canPlaceDisk(side.disk, at: position) {
                    try? self.placeDisk(side: side, at: position)
                }
            case .launching:
                fatalError()
            default:
                break
            }
        case .endPlaceDisks:
            if case .placing(let side, _) = self.state {
                self.nextTurn(from: side)
            } else {
                fatalError()
            }
        case .pass:
            if case .passing(let side) = self.state {
                self.nextTurn(from: side)
            } else {
                fatalError()
            }
        case .reset:
            switch self.state {
            case .launching:
                fatalError()
            default:
                self.eventReceiver?.receiveEvent(.willReset)
                self.newGame()
            }
        }
    }
}

private extension Interactor {
    func player(for side: Side) -> Player {
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
    
    func save() {
        try? self.dataStore.save(.init(turn: self.state.turn,
                                       darkPlayer: self.darkPlayer,
                                       lightPlayer: self.lightPlayer,
                                       board: self.board.disks))
    }
    
    func newGame() {
        #warning("resetDisksを先にしてディスク位置が保存されるようにしている")
        self.board = .init()
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.state = .waiting(side: .dark, player: .manual)
        
        self.eventReceiver?.receiveEvent(.didBeginNewGame)
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer(side: Side) {
        self.state = .waiting(side: side, player: self.player(for: side))
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer(side: Side) {
        let position = self.board.validMoves(for: side).randomElement()!
        
        let canceller = Canceller { [weak self] in
            self?.playerCanceller = nil
        }
        
        self.playerCanceller = canceller
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.computerDuration) { [weak self] in
            guard let self = self else { return }
            guard !canceller.isCancelled else { return }
            self.playerCanceller = nil
            
            self.placeDisk(side: side, at: position)
        }
    }
    
    func placeDisk(side: Side, at position: Board.Position) {
        let disk = side.disk
        
        let diskCoordinates = self.board.flippedDiskCoordinatesByPlacingDisk(disk, at: position)
        guard !diskCoordinates.isEmpty else { fatalError() }
        
        self.state = .placing(side: side, positions: [position] + diskCoordinates)
    }
    
    func didChangePlayer(_ player: Player, side: Side) {
        if case .waiting(side, player.flipped) = self.state {
            self.state = .waiting(side: side, player: player)
        }
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn(from currentSide: Side) {
        let nextSide = currentSide.flipped
        
        if self.board.validMoves(for: nextSide).isEmpty {
            if self.board.validMoves(for: currentSide).isEmpty {
                self.state = .result(self.board.result())
            } else {
                self.state = .passing(side: nextSide)
            }
        } else {
            self.waitForPlayer(side: nextSide)
        }
    }
}

private extension State {
    var turn: Side? {
        switch self.status {
        case .turn(let side):
            return side
        case .result:
            return nil
        }
    }
}
