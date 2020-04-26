import Foundation

protocol InteractorDelegate: class {
    func didChangeTurn()
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
