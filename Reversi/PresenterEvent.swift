extension Presenter {
    /// PresenterからViewControllerに通知するイベント
    enum Event {
        case updateBoardView
        case updatePlayerControls
        case updateCountLabels
        case updateMessageViews
        
        case startPlayerActivityIndicatorAnimating(side: Side)
        case stopPlayerActivityIndicatorAnimating(side: Side)
        
        case presentPassView
        
        case setBoardViewDisk(_ disk: Disk, at: Position, animationID: Identifier?)
    }
}

extension Presenter.Event: Equatable {}
