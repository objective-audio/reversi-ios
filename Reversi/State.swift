import Foundation

enum State {
    case launching
    case waiting(side: Side, player: Player)
    case passing(side: Side)
    case placing(side: Side)
    case result(Result)
}
