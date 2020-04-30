import Foundation

struct Computer {
    let positions: [Board.Position]
    let completion: (Board.Position) -> Void
}
