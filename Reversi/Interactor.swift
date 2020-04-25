import Foundation

class Interactor {
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Disk? = .dark
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}
