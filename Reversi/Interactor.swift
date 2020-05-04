import Foundation

protocol InteractorEventReceiver: class {
    func receiveEvent(_ event: Interactor.Event)
}

protocol DataStorable {
    func save(_ data: GameData) throws
    func load() throws -> GameData
}

class Interactor {
    weak var eventReceiver: InteractorEventReceiver?
    
    private var darkPlayer: Player
    private var lightPlayer: Player
    
    private(set) var board: Board
    
    private let dataStore: DataStorable
    private let computerThinking: (Computer) -> Void
    private var computerID: Identifier?
    
    init(dataStore: DataStorable = DataStore(),
         computerThinking: @escaping (Computer) -> Void = defaultComputerThinking) {
        self.dataStore = dataStore
        self.computerThinking = computerThinking
        
        do {
            let loadedData = try self.dataStore.load()
            
            self.darkPlayer = loadedData.darkPlayer
            self.lightPlayer = loadedData.lightPlayer
            
            let board = loadedData.board
            self.board = board
            
            switch loadedData.turn {
            case .some(let side):
                self.state = .launching(side: side)
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
    
    func player(for side: Side) -> Player {
        switch side {
        case .dark: return self.darkPlayer
        case .light: return self.lightPlayer
        }
    }
    
    private(set) var state: State {
        willSet {
            switch self.state {
            case .waiting(let side, let player):
                if case .computer = player {
                    self.computerID = nil
                    self.sendEvent(.didEndComputerWaiting(side: side))
                }
            default:
                break
            }
        }
        didSet {
            if self.state.turn != oldValue.turn {
                self.save()
                self.sendEvent(.didChangeTurn)
            }
            
            switch self.state {
            case .passing:
                self.sendEvent(.didEnterPassing)
            case .waiting(let side, let player):
                if case .computer = player {
                    self.sendEvent(.willBeginComputerWaiting(side: side))
                    self.playTurnOfComputer(side: side)
                }
            case .placing(let side, let positions):
                self.sendEvent(.didPlaceDisks(side: side, positions: positions))
            default:
                break
            }
        }
    }
}

extension Interactor {
    func doAction(_ action: Action) {
        switch action {
        case .begin:
            if case .launching(let side) = self.state {
                if self.board.validMoves(for: side).isEmpty {
                    self.state = .passing(side: side)
                } else {
                    self.state = self.waitForPlayer(side: side)
                }
            }
        case .changePlayer(let player, let side):
            switch self.state {
            case .launching:
                fatalError()
            default:
                self.changePlayer(player, side: side)
            }
        case .placeDisk(let position):
            switch self.state {
            case .waiting(let side, player: .manual):
                if self.board.canPlaceDisk(side.disk, at: position) {
                    self.state = self.placeDisk(side: side, at: position)
                }
            case .launching:
                fatalError()
            default:
                break
            }
        case .endPlaceDisks:
            switch self.state {
            case .placing(let side, let positions):
                positions.forEach { self.board[$0] = side.disk }
                self.state = self.nextTurn(from: side)
            case .launching:
                fatalError()
            default:
                break
            }
        case .pass:
            switch self.state {
            case .passing(let side):
                self.state = self.nextTurn(from: side)
            case .launching:
                fatalError()
            default:
                break
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
    static var defaultComputerThinking: (Computer) -> Void {
        return { computer in
            guard let position = computer.positions.randomElement() else { fatalError() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                computer.completion(position)
            }
        }
    }
    
    func save() {
        try? self.dataStore.save(.init(turn: self.state.turn,
                                       darkPlayer: self.darkPlayer,
                                       lightPlayer: self.lightPlayer,
                                       board: self.board))
    }
    
    func reset() {
        self.sendEvent(.willReset)
        
        self.board = .init()
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.save()
        
        self.state = .waiting(side: .dark, player: .manual)
        
        self.sendEvent(.didReset)
    }
    
    func waitForPlayer(side: Side) -> State {
        return .waiting(side: side, player: self.player(for: side))
    }
    
    func playTurnOfComputer(side: Side) {
        let positions = self.board.validMoves(for: side)
        let computerID = Identifier()
        
        self.computerID = computerID
        
        let computer = Computer(positions: positions, completion: { [weak self] position in
            guard let self = self else { return }
            guard self.computerID == computerID else { return }
            
            self.state = self.placeDisk(side: side, at: position)
        })
        
        self.computerThinking(computer)
    }
    
    func placeDisk(side: Side, at position: Board.Position) -> State {
        let disk = side.disk
        
        let diskCoordinates = self.board.flippedDiskCoordinatesByPlacingDisk(disk, at: position)
        guard !diskCoordinates.isEmpty else { fatalError() }
        
        return .placing(side: side, positions: [position] + diskCoordinates)
    }
    
    func nextTurn(from currentSide: Side) -> State {
        let nextSide = currentSide.flipped
        
        if self.board.validMoves(for: nextSide).isEmpty {
            if self.board.validMoves(for: currentSide).isEmpty {
                return .result(self.board.result())
            } else {
                return .passing(side: nextSide)
            }
        } else {
            return self.waitForPlayer(side: nextSide)
        }
    }
    
    func changePlayer(_ player: Player, side: Side) {
        guard player != self.player(for: side) else { return }
        
        switch side {
        case .dark: self.darkPlayer = player
        case .light: self.lightPlayer = player
        }
        
        self.save()
        
        if case .waiting(side, player.flipped) = self.state {
            self.state = .waiting(side: side, player: player)
        }
    }
    
    func sendEvent(_ event: Event) {
        self.eventReceiver?.receiveEvent(event)
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

extension DataStore: DataStorable {}
