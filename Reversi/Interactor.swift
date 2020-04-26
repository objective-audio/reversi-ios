import Foundation

protocol InteractorDelegate: class {
    func didChangeTurn()
    func willBeginComputerWaiting(side: Side)
    func didEndComputerWaiting(side: Side)
    
    #warning("残すつもりはない")
    func placeDisk(_ disk: Disk, at position: Board.Position, animated isAnimated: Bool, completion: ((Bool) -> Void)?) throws
    func nextTurn()
}

class Interactor {
    weak var delegate: InteractorDelegate?
    
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Side? = .dark {
        didSet { self.delegate?.didChangeTurn() }
    }
    
    #warning("init時に読み込んだ値をセットする")
    var darkPlayer: Player = .manual {
        didSet { self.save() }
    }
    var lightPlayer: Player = .manual {
        didSet { self.save() }
    }
    
    #warning("init時にdiskをセットする")
    var board: Board = .init()
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    var playerCancellers: [Side: Canceller] = [:]
    
    init() {
        do {
            try self.load()
        } catch {
            self.newGame()
        }
    }
    
    func newGame() {
        self.board.resetDisks()
        self.turn = .dark
        
        self.darkPlayer = .manual
        self.lightPlayer = .manual
        
        self.save()
    }
    
    func save() {
        try? DataStore().save(.init(turn: self.turn,
                                    darkPlayer: self.darkPlayer,
                                    lightPlayer: self.lightPlayer,
                                    board: self.board.disks))
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
            
            try! self.delegate?.placeDisk(side.disk, at: position, animated: true) { [weak self] _ in
                self?.delegate?.nextTurn()
            }
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
}

private extension Interactor {
    private func load() throws {
        let parameters = try DataStore().load()
        
        self.turn = parameters.turn
        self.darkPlayer = parameters.darkPlayer
        self.lightPlayer = parameters.lightPlayer
        self.board.setDisks(parameters.board)
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let position: Board.Position
}
