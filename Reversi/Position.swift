extension Board {
    struct Position {
        var x: Int
        var y: Int
    }
}

extension Board.Position: Equatable {}
extension Board.Position: Hashable {}
