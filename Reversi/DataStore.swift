import Foundation

class DataStore {
    struct Parameters {
        let turn: Side?
        let darkPlayer: Player
        let lightPlayer: Player
        let board: [[Disk?]]
    }
    
    /// ゲームの状態をファイルに書き出し、保存します。
    func save(_ parameters: Parameters) throws {
        var output: String = ""
        output += parameters.turn.symbol
        output += String(parameters.darkPlayer.rawValue)
        output += String(parameters.lightPlayer.rawValue)
        output += "\n"
        
        for line in parameters.board {
            for disk in line {
                output += disk.symbol
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
    
    func load() throws -> Parameters {
        let path = Self.path
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines = input.split(separator: "\n")[...]
        
        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }
        
        let turn: Side?
        do { // turn
            guard
                let sideSymbol = line.popFirst(),
                let side = Optional<Side>(symbol: sideSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = side
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
        
        var board: [[Disk?]] = []
        do { // board
            guard lines.count == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
            
            var y = 0
            while let line = lines.popFirst() {
                var boardLine: [Disk?] = []
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    boardLine.append(disk)
                    x += 1
                }
                guard x == Board.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                board.append(boardLine)
                y += 1
            }
            
            guard y == Board.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }

        return .init(turn: turn, darkPlayer: players[0], lightPlayer: players[1], board: board)
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

private extension Optional where Wrapped == Side {
    init?<S: StringProtocol>(symbol: S) {
        
        switch symbol {
        case "x":
            self = .dark
        case "o":
            self = .light
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    var symbol: String {
        switch self {
        case .dark:
            return "x"
        case .light:
            return "o"
        case .none:
            return "-"
        }
    }
}

private extension Optional where Wrapped == Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .dark
        case "o":
            self = .light
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    var symbol: String {
        switch self {
        case .dark:
            return "x"
        case .light:
            return "o"
        case .none:
            return "-"
        }
    }
}
