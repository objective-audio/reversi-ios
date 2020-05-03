import Foundation

extension Interactor {
    struct Computer {
        let positions: [Board.Position]
        let completion: (Board.Position) -> Void
    }
}
