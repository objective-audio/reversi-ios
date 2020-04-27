import Foundation

struct Board {
    /// 盤の幅（ `8` ）を表します。
    static let width = 8
    /// 盤の高さ（ `8` ）を返します。
    static let height = 8
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    static let xRange: Range<Int> = 0..<width
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    static let yRange: Range<Int> = 0..<height
    
    struct Position {
        var x: Int
        var y: Int
    }
    
    private(set) var disks: [[Disk?]]
    
    init(disks: [[Disk?]] = Self.initialDisks()) {
        self.disks = disks
    }
}
 
extension Board {
    mutating func setDisk(_ disk: Disk?, at position: Position) {
        self.disks[position.y][position.x] = disk
    }
    
    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func diskCount(of side: Side) -> Int {
        return self.disks.flatMap { $0 }.filter { $0 == side.disk }.count
    }
    
    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, at position: Position) -> [Position] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]
        
        guard self.diskAt(position) == nil else {
            return []
        }
        
        var diskCoordinates: [Position] = []
        
        for direction in directions {
            var position = position
            
            var diskCoordinatesInLine: [Position] = []
            flipping: while true {
                position.x += direction.x
                position.y += direction.y
                
                switch (disk, self.diskAt(position)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append(position)
                case (_, .none):
                    break flipping
                }
            }
        }
        
        return diskCoordinates
    }
    
    #warning("ゲーム結果の型を作りたい")
    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Side? {
        let darkCount = self.diskCount(of: .dark)
        let lightCount = self.diskCount(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
    
    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Side) -> [Position] {
        var coordinates: [Position] = []
        let disk = side.disk
        
        for y in Board.yRange {
            for x in Board.xRange {
                let position = Position(x: x, y: y)
                if self.canPlaceDisk(disk, at: position) {
                    coordinates.append(position)
                }
            }
        }
        
        return coordinates
    }
}

private extension Board {
    func diskAt(_ position: Position) -> Disk? {
        guard Self.xRange.contains(position.x) && Self.yRange.contains(position.y) else { return nil }
        return self.disks[position.y][position.x]
    }
    
    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, at position: Position) -> Bool {
        !self.flippedDiskCoordinatesByPlacingDisk(disk, at: position).isEmpty
    }
}

extension Board {
    static func initialDisks() -> [[Disk?]] {
        let line = [Disk?](repeating: nil, count: Self.width)
        var disks = [[Disk?]](repeating: line, count: Self.height)
        
        let down = Self.height / 2
        let up = down - 1
        let right = Self.width / 2
        let left = right - 1
        
        disks[up][left] = .light
        disks[up][right] = .dark
        disks[down][left] = .dark
        disks[down][right] = .light
        
        return disks
    }
}
