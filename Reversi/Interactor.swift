import Foundation

/// Interactorのイベントを受け取るインターフェースを定義
protocol InteractorEventReceiver: class {
    func receiveEvent(_ event: Interactor.Event)
}

/// データを保存するインターフェースを定義
protocol DataStorable {
    func save(_ data: GameData) throws
    func load() throws -> GameData
}

/// コンピュータの処理を行うインターフェースを定義
protocol ComputerThinkable {
    func callAsFunction(_ computer: Computer)
}

/// ゲーム全体の状態を管理する
class Interactor {
    weak var eventReceiver: InteractorEventReceiver?
    
    private var darkPlayer: Player
    private var lightPlayer: Player
    
    private(set) var board: Board
    
    private let dataStore: DataStorable
    private let computerThinking: ComputerThinkable
    private var computerID: Identifier?
    
    init(dataStore: DataStorable = DataStore(),
         computerThinking: ComputerThinkable = DefaultComputerThinking()) {
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
                self.state = .resulting(board.result())
            }
        } catch {
            self.darkPlayer = .manual
            self.lightPlayer = .manual
            self.board = .init()
            self.state = .launching(side: .dark)
        }
    }
    
    /// 番手に応じてプレイヤーを返す
    func player(for side: Side) -> Player {
        switch side {
        case .dark: return self.darkPlayer
        case .light: return self.lightPlayer
        }
    }
    
    /// ゲームの状態
    private(set) var state: State
}

extension Interactor {
    /// アクションを受け取る
    func doAction(_ action: Action) {
        switch self.state {
        case .launching(let side):
            switch action {
            case .begin:
                if self.board.validMoves(for: side).isEmpty {
                    self.changeState(to: .passing(side: side))
                } else {
                    self.changeState(to: .operating(side: side, player: self.player(for: side)))
                }
            default:
                fatalError()
            }
        case .operating(let side, let player):
            switch action {
            case .changePlayer(let player, let side):
                if let state = self.changePlayer(player, side: side) {
                    self.changeState(to: state)
                }
            case .reset:
                self.changeState(to: .resetting)
            case .placeDisk(let position, let placedPlayer):
                if player == placedPlayer, self.board.canPlaceDisk(side.disk, at: position) {
                    self.changeState(to: self.placingState(side: side, at: position))
                }
            default:
                break
            }
        case .placing(let side, let positions):
            switch action {
            case .changePlayer(let player, let side):
                if let state = self.changePlayer(player, side: side) {
                    self.changeState(to: state)
                }
            case .reset:
                self.changeState(to: .resetting)
            case .endPlaceDisks:
                positions.forEach { self.board[$0] = side.disk }
                self.changeState(to: .branching(fromSide: side))
            default:
                break
            }
        case .passing(let side):
            switch action {
            case .changePlayer(let player, let side):
                if let state = self.changePlayer(player, side: side) {
                    self.changeState(to: state)
                }
            case .reset:
                self.changeState(to: .resetting)
            case .pass:
                self.changeState(to: .branching(fromSide: side))
            default:
                break
            }
        case .resulting:
            switch action {
            case .changePlayer(let player, let side):
                if let state = self.changePlayer(player, side: side) {
                    self.changeState(to: state)
                }
            case .reset:
                self.changeState(to: .resetting)
            default:
                break
            }
        case .resetting, .branching, .next:
            fatalError()
        }
    }
}

private extension Interactor {
    /// ステートを変更する
    func changeState(to toState: State) {
        self.willExitState()
        self.state = toState
        self.didEnterState()
    }
    
    /// 現在のステートに入った時の処理
    func didEnterState() {
        switch self.state {
        case .passing:
            self.sendEvent(.didEnterPassing)
        case .operating(let side, .computer):
            self.sendEvent(.didEnterComputerOperating(side: side))
            self.playTurnOfComputer(side: side)
        case .placing(let side, let positions):
            self.sendEvent(.didEnterPlacing(side: side, positions: positions))
        case .resetting:
            self.sendEvent(.willReset)
            self.reset()
            self.sendEvent(.didReset)
            self.changeState(to: .operating(side: .dark, player: .manual))
        case .branching(let fromSide):
            self.changeState(to: .next(toState: self.nextTurnState(from: fromSide)))
        case .next(let state):
            self.save()
            self.sendEvent(.didChangeTurn)
            self.changeState(to: state)
        default:
            break
        }
    }
    
    /// 現在のステートから出る時の処理
    func willExitState() {
        switch self.state {
        case .operating(let side, .computer):
            self.computerID = nil
            self.sendEvent(.willExitComputerOperating(side: side))
        default:
            break
        }
    }
    
    /// ゲームのデータを保存する
    func save() {
        try? self.dataStore.save(.init(turn: self.state.turn,
                                       darkPlayer: self.darkPlayer,
                                       lightPlayer: self.lightPlayer,
                                       board: self.board))
    }
    
    /// ゲームをリセットする
    func reset() {
        self.board = .init()
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.save()
    }
    
    /// コンピュータの処理を開始する
    func playTurnOfComputer(side: Side) {
        let positions = self.board.validMoves(for: side)
        let computerID = Identifier()
        
        self.computerID = computerID
        
        let computer = Computer(positions: positions, completion: { [weak self] position in
            guard let self = self else { return }
            guard self.computerID == computerID else { return }
            
            self.doAction(.placeDisk(at: position, player: .computer))
        })
        
        self.computerThinking(computer)
    }
    
    /// ディスクを配置するステートを返す
    func placingState(side: Side, at position: Position) -> State {
        let disk = side.disk
        
        let diskCoordinates = self.board.flippedDiskCoordinatesByPlacingDisk(disk, at: position)
        guard !diskCoordinates.isEmpty else { fatalError() }
        
        return .placing(side: side, positions: [position] + diskCoordinates)
    }
    
    /// 次にターンのステートを返す
    func nextTurnState(from currentSide: Side) -> State {
        let nextSide = currentSide.flipped
        
        if self.board.validMoves(for: nextSide).isEmpty {
            if self.board.validMoves(for: currentSide).isEmpty {
                return .resulting(self.board.result())
            } else {
                return .passing(side: nextSide)
            }
        } else {
            return .operating(side: nextSide, player: self.player(for: nextSide))
        }
    }
    
    /// プレイヤーの種類を変更する。ステート変更の必要があればステートを返す
    func changePlayer(_ player: Player, side: Side) -> State? {
        guard player != self.player(for: side) else { return nil }
        
        switch side {
        case .dark: self.darkPlayer = player
        case .light: self.lightPlayer = player
        }
        
        self.save()
        
        if case .operating(side, player.flipped) = self.state {
            return .operating(side: side, player: player)
        } else {
            return nil
        }
    }
    
    func sendEvent(_ event: Event) {
        self.eventReceiver?.receiveEvent(event)
    }
}

/// 実際のゲームで使うコンピュータの処理
private struct DefaultComputerThinking: ComputerThinkable {
    func callAsFunction(_ computer: Computer) {
        guard let position = computer.positions.randomElement() else { fatalError() }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            computer.completion(position)
        }
    }
}

private extension State {
    var turn: Side? {
        switch self.status {
        case .turn(let side): return side
        case .result: return nil
        }
    }
}

extension DataStore: DataStorable {}
