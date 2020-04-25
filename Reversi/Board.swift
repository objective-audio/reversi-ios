import Foundation

struct Board {
    /// 盤の幅（ `8` ）を表します。
    static let width = 8
    /// 盤の高さ（ `8` ）を返します。
    static let height = 8
    
    private(set) var disks: [[Disk?]]
    
    init(disks: [[Disk?]]) {
        self.disks = disks
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
}
