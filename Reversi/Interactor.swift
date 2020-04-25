import Foundation

class Interactor {
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Disk? = .dark
    
    #warning("init時に読み込んだ値をセットする")
    var darkPlayer: Player = .manual
    var lightPlayer: Player = .manual
    
    #warning("init時にdiskをセットする")
    var board: Board = .init()
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
