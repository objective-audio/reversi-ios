import Foundation

enum Action {
    case begin
    case placeDisk(position: Board.Position)
    case changePlayer(_ player: Player, side: Side)
    case reset
}
