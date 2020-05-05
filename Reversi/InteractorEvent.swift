extension Interactor {
    /// Interactorが送信するイベント
    enum Event {
        case didChangeTurn
        case didEnterComputerOperating(side: Side)
        case willExitComputerOperating(side: Side)
        case didEnterPassing
        case didEnterPlacing(side: Side, positions: [Position])
        case willReset
        case didReset
    }
}

extension Interactor.Event: Equatable {}
