import Foundation

extension Interactor {
    enum Action {
        case begin
        case placeDisk(at: Board.Position)
        case endPlaceDisks
        case changePlayer(_ player: Player, side: Side)
        case pass
        case reset
    }
}

extension Interactor.Action: Equatable {}
