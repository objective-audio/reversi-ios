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
}

extension Board {
    static func emptyDisks() -> [[Disk?]] {
        let line = [Disk?](repeating: nil, count: Self.width)
        return [[Disk?]](repeating: line, count: Self.height)
    }
}
