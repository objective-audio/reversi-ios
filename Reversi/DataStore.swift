import Foundation

class DataStore {
    var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    /// ゲームの状態をファイルに書き出し、保存します。
    func save(turn: Disk?,
              darkPlayer: Player,
              lightPlayer: Player,
              board: [[Disk?]]) throws {
        var output: String = ""
        output += turn.symbol
        output += String(darkPlayer.rawValue)
        output += String(lightPlayer.rawValue)
        output += "\n"
        
        for line in board {
            for disk in line {
                output += disk.symbol
            }
            output += "\n"
        }
        
        do {
            try output.write(toFile: self.path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: self.path, cause: error)
        }
    }
}

private extension DataStore {
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }
}

#warning("fileprivateにする?")
extension Optional where Wrapped == Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}
