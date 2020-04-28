import Foundation

enum State {
    case launching(side: Side)
    case waiting(side: Side, player: Player)
    case passing(side: Side)
    case placing(side: Side, positions: [Board.Position])
    case result(Result)
}
