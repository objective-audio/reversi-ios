import Foundation
@testable import Reversi

struct TestUtils {
    static var initialBoard: Board {
        return .init([
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ])
    }
    
    static var emptyBoard: Board {
        return .init([
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ])
    }
    
    static var darkPassBoard: Board {
        return .init([
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, .dark, .light, .dark, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ])
    }
    
    static var preLightPassBoard: Board {
        return .init([
            [nil, nil, .light, .dark, .dark, .dark, .dark, .dark],
            [.light, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark]
        ])
    }
    
    static var darkPlacedBoard: Board {
        return .init([
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ])
    }
    
    static var tiedBoard: Board {
        return .init([
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ])
    }
    
    static var lightWonBoard: Board {
        return .init([
            [.light, .light, .light, .light, .light, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ])
    }
    
    static var darkWonBoard: Board {
        return self.lightWonBoard.flipped
    }
    
    static var preTiedBoard: Board {
        return .init([
            [.light, .light, .light, .light, .dark, .light, nil, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ])
    }
    
    static var preDarkWonBoard: Board {
        return .init([
            [.light, .light, .light, .dark, .dark, .light, nil, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ])
    }
    
    static var url: URL {
        guard let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Game") else { fatalError() }
        return url
    }
    
    static func writeToFile(string: String) {
        try! string.write(to: self.url, atomically: true, encoding: .utf8)
    }
    
    static func loadFromFile() -> String {
        return try! String(contentsOf: self.url)
    }
    
    static func removeFile() {
        try? FileManager.default.removeItem(at: self.url)
    }
}

private extension Board {
    var flipped: Board {
        return .init(Board.yRange.map { y in Board.xRange.map { x in self[.init(x: x, y: y)].flipped } })
    }
}

private extension Optional where Wrapped == Disk {
    var flipped: Disk? {
        switch self {
        case .dark: return .light
        case .light: return .dark
        case .none: return .none
        }
    }
}
