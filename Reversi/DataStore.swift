import Foundation

struct DataArgs {
    let turn: Side?
    let darkPlayer: Player
    let lightPlayer: Player
    let board: Board
}

class DataStore {
    /// ゲームの状態をファイルに書き出し、保存します。
    func save(_ args: DataArgs) throws {
        var output: String = ""
        output += String(args.turn.symbol.rawValue)
        output += String(args.darkPlayer.rawValue)
        output += String(args.lightPlayer.rawValue)
        output += "\n"
        
        for y in Board.yRange {
            for x in Board.yRange {
                output += String(args.board[.init(x: x, y: y)].symbol.rawValue)
            }
            output += "\n"
        }
        
        let path = Self.path
        
        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    
    func load() throws -> DataArgs {
        let path = Self.path
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines = input.split(separator: "\n")[...]
        
        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }
        
        let turn: Side?
        do { // turn
            guard
                let sideCharacter = line.popFirst(),
                let symbol = Symbol(rawValue: sideCharacter)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = Side?.init(symbol: symbol)
        }

        // players
        var players: [Player] = []
        for _ in 0..<2 {
            do {
                guard
                    let playerSymbol = line.popFirst(),
                    let playerNumber = Int(playerSymbol.description),
                    let player = Player(rawValue: playerNumber)
                else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                players.append(player)
            }
        }
        
        var disks: [[Disk?]] = []
        do { // board
            guard lines.count == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
            
            while let line = lines.popFirst() {
                var boardLine: [Disk?] = []
                for character in line {
                    guard let symbol = Symbol(rawValue: character) else {
                        throw FileIOError.read(path: path, cause: nil)
                    }
                    boardLine.append(.init(symbol: symbol))
                }
                guard boardLine.count == Board.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                disks.append(boardLine)
            }
            
            guard disks.count == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }

        return .init(turn: turn, darkPlayer: players[0], lightPlayer: players[1], board: .init(disks))
    }
}

private extension DataStore {
    static var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }
}

private enum Symbol: Character {
    case dark = "x"
    case light = "o"
    case none = "-"
}

private extension Optional where Wrapped == Side {
    init(symbol: Symbol) {
        switch symbol {
        case .dark: self = .dark
        case .light: self = .light
        case .none: self = .none
        }
    }
    
    var symbol: Symbol {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .none: return .none
        }
    }
}

private extension Optional where Wrapped == Disk {
    init(symbol: Symbol) {
        switch symbol {
        case .dark: self = .dark
        case .light: self = .light
        case .none: self = .none
        }
    }
    
    var symbol: Symbol {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .none: return .none
        }
    }
}
