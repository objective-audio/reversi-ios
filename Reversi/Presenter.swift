import Foundation

protocol Displayable: class {
    func updateAll()
}

class Presenter {
    private let interactor: Interactor
    
    weak var displayer: Displayable?
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    var playerCancellers: [Disk: Canceller] = [:]
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
    }
    
    var turn: Disk? {
        get { self.interactor.turn }
        set { self.interactor.turn = newValue }
    }
    
    var darkPlayer: Player {
        get { self.interactor.darkPlayer }
        set { self.interactor.darkPlayer = newValue }
    }
    
    var lightPlayer: Player {
        get { self.interactor.lightPlayer }
        set { self.interactor.lightPlayer = newValue }
    }
    
    func player(for side: Disk) -> Player {
        switch side {
        case .dark:
            return self.darkPlayer
        case .light:
            return self.lightPlayer
        }
    }
    
    var disks: [[Disk?]] { self.interactor.board.disks }
    
    func setDisks(_ disks: [[Disk?]]) {
        self.interactor.board.setDisks(disks)
    }
    
    func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        self.interactor.board.setDisk(disk, atX: x, y: y)
    }
    
    func diskAt(x: Int, y: Int) -> Disk? {
        self.interactor.board.diskAt(x: x, y: y)
    }
    
    func resetDisks() {
        self.interactor.board.resetDisks()
    }
    
    func load() throws {
        try self.interactor.load()
        
        #warning("通知で呼び出す")
        self.displayer?.updateAll()
    }
    
    func save() throws {
        try self.interactor.save()
    }
}
