import Foundation

enum Status {
    case turn(side: Side)
    case result(Result)
}

extension Status: Equatable {}
