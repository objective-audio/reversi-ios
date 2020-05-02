import Foundation
@testable import Reversi

struct TestUtils {
    static var initialDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    static var emptyDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    static var darkPassDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, .dark, .light, .dark, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    static var preLightPassDisks: [[Disk?]] {
        return [
            [nil, nil, .light, .dark, .dark, .dark, .dark, .dark],
            [.light, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark],
            [.dark, .dark, .dark, .dark, .dark, .dark, .dark, .dark]
        ]
    }
    
    static var darkPlacedDisks: [[Disk?]] {
        return [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .dark, .dark, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil]
        ]
    }
    
    static var tiedDisks: [[Disk?]] {
        return [
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
    }
    
    static var lightWonDisks: [[Disk?]] {
        return [
            [.light, .light, .light, .light, .light, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
    }
    
    static var darkWonDisks: [[Disk?]] {
        return [
            [.light, .light, .light, .dark, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
    }
    
    static var preTiedDisks: [[Disk?]] {
        return [
            [.light, .light, .light, .light, .dark, .light, nil, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
    }
    
    static var preDarkWonDisks: [[Disk?]] {
        return [
            [.light, .light, .light, .dark, .dark, .light, nil, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark],
            [.light, .light, .light, .light, .dark, .dark, .dark, .dark]
        ]
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
