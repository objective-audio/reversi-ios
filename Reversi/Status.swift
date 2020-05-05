/// UIに表示する程度の大まかなゲームの状態
enum Status {
    case turn(side: Side)
    case result(Result)
}

extension Status: Equatable {}
