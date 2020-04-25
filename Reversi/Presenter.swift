import Foundation

class Presenter {
    private let interactor: Interactor
    
    #warning("privateにする")
    var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    
    init(interactor: Interactor = .init()) {
        self.interactor = interactor
    }
    
    var turn: Disk? {
        get { self.interactor.turn }
        set { self.interactor.turn = newValue }
    }
}
