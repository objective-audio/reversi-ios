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
    
    private(set) var disks: [[Disk?]]
    
    init(disks: [[Disk?]]) {
        self.disks = disks
    }
    
    #warning("後で消す?")
    init() {
        self.init(disks: Self.emptyDisks())
    }
    
    mutating func setDisks(_ disks: [[Disk?]]) {
        self.disks = disks
    }
    
    mutating func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        self.disks[y][x] = disk
    }
    
    func diskAt(x: Int, y: Int) -> Disk? {
        guard Self.xRange.contains(x) && Self.yRange.contains(y) else { return nil }
        return self.disks[y][x]
    }
    
    mutating func resetDisks() {
        self.disks = Self.emptyDisks()
        
        self.setDisk(.light, atX: Self.width / 2 - 1, y: Self.height / 2 - 1)
        self.setDisk(.dark, atX: Self.width / 2, y: Self.height / 2 - 1)
        self.setDisk(.dark, atX: Self.width / 2 - 1, y: Self.height / 2)
        self.setDisk(.light, atX: Self.width / 2, y: Self.height / 2)
    }
    
    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func diskCount(of side: Disk) -> Int {
        return self.disks.flatMap { $0 }.filter { $0 == side }.count
    }
    
    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
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
        
        guard self.diskAt(x: x, y: y) == nil else {
            return []
        }
        
        var diskCoordinates: [(Int, Int)] = []
        
        for direction in directions {
            var x = x
            var y = y
            
            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y
                
                switch (disk, self.diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }
        
        return diskCoordinates
    }
    
    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Disk? {
        let darkCount = self.diskCount(of: .dark)
        let lightCount = self.diskCount(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
}

extension Board {
    static func emptyDisks() -> [[Disk?]] {
        let line = [Disk?](repeating: nil, count: Self.width)
        return [[Disk?]](repeating: line, count: Self.height)
    }
}
