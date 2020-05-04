enum State {
    case launching(side: Side)
    case operating(side: Side, player: Player)
    case passing(side: Side)
    case placing(side: Side, positions: [Position])
    case result(Result)
}

extension State {
    var status: Status {
        switch self {
        case .launching(let side), .operating(let side, _), .placing(let side, _), .passing(let side):
            return .turn(side: side)
        case .result(let result):
            return .result(result)
        }
    }
}

extension State: Equatable {}
