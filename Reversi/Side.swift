import Foundation

enum Side: Int, CaseIterable {
    case dark
    case light
}

extension Side: Hashable {}

extension Side {
    var flipped: Side {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
}

extension Side {
    #warning("置き場所は再考")
    var disk: Disk {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}
