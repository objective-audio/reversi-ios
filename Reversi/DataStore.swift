import Foundation

class DataStore {
    struct Parameters {
        let turn: Disk?
        let darkPlayer: Player
        let lightPlayer: Player
        let board: [[Disk?]]
    }
    
    var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
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
