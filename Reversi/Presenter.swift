import Foundation

class Presenter {
    private let interactor: Interactor
    
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
    
    func setDisks(_ disks: [[Disk?]]) {
        self.interactor.board.setDisks(disks)
    }
    
    func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        self.interactor.board.setDisk(disk, atX: x, y: y)
    }
    
    func diskAt(x: Int, y: Int) -> Disk? {
        self.interactor.board.diskAt(x: x, y: y)
    }
}
