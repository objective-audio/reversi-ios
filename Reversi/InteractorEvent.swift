extension Interactor {
    enum Event {
        case didChangeTurn
        case didEnterComputerOperating(side: Side)
        case willExitComputerOperating(side: Side)
        case didEnterPassing
        case didPlaceDisks(side: Side, positions: [Position])
        case willReset
        case didReset
    }
}

extension Interactor.Event: Equatable {}
