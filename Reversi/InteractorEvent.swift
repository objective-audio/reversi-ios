extension Interactor {
    enum Event {
        case didChangeTurn
        case willBeginComputerWaiting(side: Side)
        case didEndComputerWaiting(side: Side)
        case didEnterPassing
        case didPlaceDisks(side: Side, positions: [Position])
        case willReset
        case didReset
    }
}

extension Interactor.Event: Equatable {}
