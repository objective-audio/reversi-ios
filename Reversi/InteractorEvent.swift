import Foundation

extension Interactor {
    enum Event {
        case didChangeTurn
        case willBeginComputerWaiting(side: Side)
        case didEndComputerWaiting(side: Side)
        case didEnterPassing
        case didPlaceDisks(side: Side, positions: [Board.Position])
        case willReset
        case didReset
    }
}

extension Interactor.Event: Equatable {}
