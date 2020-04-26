import Foundation

enum Side: Int, CaseIterable {
    case dark
    case light
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
