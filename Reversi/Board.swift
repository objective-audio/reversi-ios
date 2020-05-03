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
    
    static let allPositions: [Board.Position] = Board.yRange.flatMap { y in Board.xRange.map { x in .init(x: x, y: y) } }
    
    struct Position {
        var x: Int
        var y: Int
    }
    
    struct Element {
        let disk: Disk?
        let position: Position
    }
    
    private(set) var disks: [[Disk?]]
    
    init(_ disks: [[Disk?]] = Self.initialDisks) {
        precondition(disks.count == Self.height)
        for diskLine in disks {
            precondition(diskLine.count == Self.width)
        }
        
        self.disks = disks
    }
}
 
extension Board {
    subscript(position: Position) -> Disk? {
        get { self.disks[position.y][position.x] }
        set { self.disks[position.y][position.x] = newValue }
    }
    
    var allElements: [Element] {
        return Self.allPositions.map { .init(disk: self[$0], position: $0) }
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
        
        guard self.safeDiskAt(position) == nil else {
            return []
        }
        
        var diskCoordinates: [Position] = []
        
        for direction in directions {
            var position = position
            
            var diskCoordinatesInLine: [Position] = []
            flipping: while true {
                position.x += direction.x
                position.y += direction.y
                
                switch (disk, self.safeDiskAt(position)) { // Uses tuples to make patterns exhaustive
                case (.dark, .dark), (.light, .light):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .light), (.light, .dark):
                    diskCoordinatesInLine.append(position)
                case (_, .none):
                    break flipping
                }
            }
        }
        
        return diskCoordinates
    }
    
    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, at position: Position) -> Bool {
        !self.flippedDiskCoordinatesByPlacingDisk(disk, at: position).isEmpty
    }
    
    func result() -> Result {
        let darkCount = self.diskCount(of: .dark)
        let lightCount = self.diskCount(of: .light)
        if darkCount == lightCount {
            return .tied
        } else {
            return .won(side: darkCount > lightCount ? .dark : .light)
        }
    }
    
    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Side) -> [Position] {
        return Self.allPositions.filter { self.canPlaceDisk(side.disk, at: $0) }
    }
}

private extension Board {
    func safeDiskAt(_ position: Position) -> Disk? {
        guard Self.xRange.contains(position.x) && Self.yRange.contains(position.y) else { return nil }
        return self.disks[position.y][position.x]
    }
}

extension Board {
    static var initialDisks: [[Disk?]] {
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

extension Board.Position: Equatable {}
extension Board.Position: Hashable {}
