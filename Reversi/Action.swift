import Foundation

enum Action {
    case begin
    case placeDisk(position: Board.Position)
    case endPlaceDisks
    case changePlayer(_ player: Player, side: Side)
    case pass
    case reset
}
