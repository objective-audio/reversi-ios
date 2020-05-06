/// ゲームの状態
indirect enum State {
    // MARK: - 待機ステート
    /// 起動してUIの準備待ち
    case launching(side: Side)
    /// 操作待ち
    case operating(side: Side, player: Player)
    /// パス待ち
    case passing(side: Side)
    /// ディスクの配置中
    case placing(side: Side, positions: [Position])
    /// ゲーム結果
    case resulting(Result)
    
    // MARK: - 実行ステート
    /// リセット
    case resetting
    /// 次のターンへ進む分岐
    case branching(fromSide: Side)
    
    // MARK: - 遷移
    /// 次のステートに遷移する。statusが次のステートと同じ扱いになる
    case next(toState: State)
}

extension State {
    var status: Status {
        switch self {
        case .launching(let side), .operating(let side, _), .placing(let side, _), .passing(let side), .branching(let side):
            return .turn(side: side)
        case .resetting:
            return .turn(side: .dark)
        case .next(let state):
            return state.status
        case .resulting(let result):
            return .result(result)
        }
    }
}

extension State: Equatable {}
