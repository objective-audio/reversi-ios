import Foundation

enum State {
    case launching(side: Side)
    case waiting(side: Side, player: Player)
    case passing(side: Side)
    case placing(side: Side, positions: [Board.Position])
    case result(Result)
}

enum Result {
    case won(side: Side)
    case tied
}

enum Status {
    case turn(side: Side)
    case result(Result)
}

extension State {
    var status: Status {
        switch self {
        case .launching(let side), .waiting(let side, _), .placing(let side, _), .passing(let side):
            return .turn(side: side)
        case .result(let result):
            return .result(result)
        }
    }
}

extension State: Equatable {}
extension Result: Equatable {}
extension Status: Equatable {}
