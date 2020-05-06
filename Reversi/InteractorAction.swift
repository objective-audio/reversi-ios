extension Interactor {
    /// Interactorが受け取るアクション
    enum Action {
        /// ゲーム開始
        case begin
        /// ディスクを置く
        case placeDisk(at: Position, player: Player)
        /// ディスクの配置終了
        case endPlaceDisks
        /// プレイヤーの種類を変更
        case changePlayer(_ player: Player, side: Side)
        /// パスする
        case pass
        /// リセットする
        case reset
    }
}

extension Interactor.Action: Equatable {}
