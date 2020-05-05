/// ゲームの結果
enum Result {
    case won(side: Side)
    case tied
}

extension Result: Equatable {}
