enum Disk {
    case dark
    case light
}

extension Disk: Hashable {}

extension Disk {
    /// 自身の値を反転させた値（ `.dark` なら `.light` 、 `.light` なら `.dark` ）を返します。
    var flipped: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
    
    /// 自身の値を、現在の値が `.dark` なら `.light` に、 `.light` なら `.dark` に反転させます。
    mutating func flip() {
        self = flipped
    }
}

#warning("置き場所は再考")
extension Disk: CaseIterable {
    init(index: Int) {
        precondition(index < Disk.allCases.count)
        self = Disk.allCases[index]
    }
    
    var index: Int {
        if let index = Disk.allCases.firstIndex(of: self) {
            return index
        } else {
            fatalError()
        }
    }
}
