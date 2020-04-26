import Foundation

class Interactor {
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Disk? = .dark
    
    #warning("init時に読み込んだ値をセットする")
    var darkPlayer: Player = .manual
    var lightPlayer: Player = .manual
    
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
        
        try? self.save()
    }
    
    func load() throws {
        let parameters = try DataStore().load()
        
        self.turn = parameters.turn
        self.darkPlayer = parameters.darkPlayer
        self.lightPlayer = parameters.lightPlayer
        self.board.setDisks(parameters.board)
    }
    
    func save() {
        try? DataStore().save(.init(turn: self.turn,
                                    darkPlayer: self.darkPlayer,
                                    lightPlayer: self.lightPlayer,
                                    board: self.board.disks))
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
