import Foundation

enum Player: Int {
    case manual = 0
    case computer = 1
}

extension Player {
    var flipped: Player {
        switch self {
        case .manual: return .computer
        case .computer: return .manual
        }
    }
}
