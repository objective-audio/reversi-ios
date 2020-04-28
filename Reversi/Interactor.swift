import Foundation

#warning("2.0に戻す")
private let computerThinkDuration = 0.3

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

class Interactor {
    weak var eventReceiver: InteractorEventReceiver?
    
    #warning("turnはstateで済ませる")
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Side? {
        didSet {
            if self.turn != oldValue {
                self.save()
                self.eventReceiver?.receiveEvent(.didChangeTurn)
            }
        }
    }
    
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
        didSet {
            switch self.state {
            case .passing:
                self.eventReceiver?.receiveEvent(.didEnterPassing)
            case .waiting(_, let player):
                if case .computer = player {
                    self.playTurnOfComputer()
                }
            default:
                break
            }
        }
    }
    
    var status: Status {
        switch self.state {
        case .launching(let side), .waiting(let side, _), .placing(let side), .passing(let side):
            return .turn(side: side)
        case .result(let result):
            return .result(result)
        }
    }
    
    let dataStore: DataStore
    var board: Board
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    private var playerCancellers: [Side: Canceller] = [:]
    
    init(dataStore: DataStore = .init()) {
        self.dataStore = dataStore
        
        do {
            let parameters = try self.dataStore.load()
            
            self.turn = parameters.turn
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
                if let winner = board.sideWithMoreDisks() {
                    self.state = .result(.won(side: winner))
                } else {
                    self.state = .result(.tied)
                }
            }
        } catch {
            self.turn = .dark
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
                    self.waitForPlayer()
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
            case .waiting(_, player: .manual):
                try? self.placeDisk(at: position)
            case .launching:
                fatalError()
            default:
                break
            }
        case .endPlaceDisks:
            if case .placing = self.state {
                self.nextTurn()
            } else {
                fatalError()
            }
        case .pass:
            if case .passing = self.state {
                self.nextTurn()
            } else {
                fatalError()
            }
        case .reset:
            switch self.state {
            case .launching:
                fatalError()
            default:
                self.reset()
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
        try? self.dataStore.save(.init(turn: self.turn,
                                       darkPlayer: self.darkPlayer,
                                       lightPlayer: self.lightPlayer,
                                       board: self.board.disks))
    }
    
    func newGame() {
        #warning("resetDisksを先にしてディスク位置が保存されるようにしている")
        self.board = .init()
        self.turn = .dark
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.state = .waiting(side: .dark, player: .manual)
        
        self.eventReceiver?.receiveEvent(.didBeginNewGame)
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let side = self.turn else { return }
        let player =  self.player(for: side)
        
        self.state = .waiting(side: side, player: player)
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let side = self.turn else { preconditionFailure() }
        let position = self.board.validMoves(for: side).randomElement()!

        self.eventReceiver?.receiveEvent(.willBeginComputerWaiting(side: side))
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.eventReceiver?.receiveEvent(.didEndComputerWaiting(side: side))
            self.playerCancellers[side] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + computerThinkDuration) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(at: position)
        }
        
        self.playerCancellers[side] = canceller
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
        
        self.state = .placing(side: side)
        
        let positions = [position] + diskCoordinates
        
        positions.forEach { self.board.setDisk(disk, at: $0) }
        
        self.eventReceiver?.receiveEvent(.didPlaceDisks(side: side, positions: positions))
    }
    
    func didChangePlayer(_ player: Player, side: Side) {
        if let canceller = self.playerCancellers[side] {
            canceller.cancel()
        }
        
        if case .waiting(side, player.flipped) = self.state {
            self.state = .waiting(side: side, player: player)
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
                if let winner = self.board.sideWithMoreDisks() {
                    self.state = .result(.won(side: winner))
                } else {
                    self.state = .result(.tied)
                }
                
                self.turn = nil
            } else {
                self.state = .passing(side: nextSide)
                self.turn = nextSide
            }
        } else {
            self.turn = nextSide
            self.waitForPlayer()
        }
    }
    
    func reset() {
        self.eventReceiver?.receiveEvent(.willReset)
        
        for side in Side.allCases {
            self.playerCancellers[side]?.cancel()
            self.playerCancellers.removeValue(forKey: side)
        }
        
        self.newGame()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk?
    let position: Board.Position
}
