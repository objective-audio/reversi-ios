/// ゲームの状態
enum State {
    /// 起動してUIの準備待ち
    case launching(side: Side)
    /// 操作待ち
    case operating(side: Side, player: Player)
    /// パス待ち
    case passing(side: Side)
    /// ディスクの配置中
    case placing(side: Side, positions: [Position])
    /// ゲーム結果
    case result(Result)
}

extension State {
    var status: Status {
        switch self {
        case .launching(let side), .operating(let side, _), .placing(let side, _), .passing(let side):
            return .turn(side: side)
        case .result(let result):
            return .result(result)
        }
    }
}

extension State: Equatable {}
