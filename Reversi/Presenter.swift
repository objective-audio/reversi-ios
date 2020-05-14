/// ゲーム全体を管理するインターフェースを定義
protocol Interactable: AnyObject {
    var eventReceiver: InteractorEventReceiver? { get set }
    
    var state: State { get }
    var board: Board { get }
    func player(for side: Side) -> Player
    
    func doAction(_ action: Interactor.Action)
}

/// Presenterのイベントを受け取るインターフェースを定義
protocol PresenterEventReceiver: AnyObject {
    func receiveEvent(_ event: Presenter.Event)
}

/// ViewControllerとInteractorの橋渡しをする
class Presenter {
    private weak var interactor: Interactable?
    
    weak var eventReceiver: PresenterEventReceiver? {
        didSet {
            if self.eventReceiver != nil && oldValue == nil {
                self.updateViewsForInitial()
            }
        }
    }
    
    fileprivate class DiskAnimation {
        let id: Identifier = .init()
        let disk: Disk
        var remainPositions: [Position]
        
        init(disk: Disk, positions: [Position]) {
            self.disk = disk
            self.remainPositions = positions
        }
    }
    private var diskAnimation: DiskAnimation?
    
    init(interactor: Interactable) {
        self.interactor = interactor
        interactor.eventReceiver = self
    }
    
    /// 番手に応じたプレイヤー（マニュアル・コンピュータ）を返す
    func player(for side: Side) -> Player? { self.interactor?.player(for: side) }
    
    /// 盤のデータを返す
    var board: Board? { self.interactor?.board }
    
    /// ゲームの状態を返す
    var status: Status? { self.interactor?.state.status }
    
    /// 番手に応じたディスクの枚数を返す
    func diskCount(of side: Side) -> Int? {
        return self.interactor?.board.diskCount(of: side)
    }
    
    /// UIが準備できた
    func viewDidAppear() {
        self.interactor?.doAction(.begin)
    }
    
    /// プレイヤーを変更する
    func changePlayer(_ player: Player, side: Side) {
        self.interactor?.doAction(.changePlayer(player, side: side))
    }
    
    /// ディスクを置く位置を選択する
    func selectBoard(at position: Position) {
        self.interactor?.doAction(.placeDisk(at: position, player: .manual))
    }
    
    /// ゲームをリセットする
    func reset() {
        self.interactor?.doAction(.reset)
    }
    
    /// 自分の番をパスする
    func pass() {
        self.interactor?.doAction(.pass)
    }
    
    /// ディスクを配置するアニメーションが終わった
    func endSetBoardDisk(animationID: Identifier, isFinished: Bool) {
        guard let animation = self.diskAnimation else { return }
        
        if animation.remainPositions.isEmpty {
            self.endSetBoardViewDisks()
        } else if isFinished {
            self.setNextBoardViewDisk(animation: animation)
        } else {
            for position in animation.remainPositions {
                self.sendEvent(.setBoardViewDisk(animation.disk, at: position, animationID: nil))
            }
            self.endSetBoardViewDisks()
        }
    }
}

extension Presenter: InteractorEventReceiver {
    /// Interactorのイベントを受け取る
    func receiveEvent(_ event: Interactor.Event) {
        switch event {
        case .didChangeTurn:
            self.updateViewsForDidChangeTurn()
        case .didEnterComputerOperating(let side):
            self.sendEvent(.startPlayerActivityIndicatorAnimating(side: side))
        case .willExitComputerOperating(let side):
            self.sendEvent(.stopPlayerActivityIndicatorAnimating(side: side))
        case .didEnterPassing:
            self.sendEvent(.presentPassView)
        case .didEnterPlacing(let side, let positions):
            self.didEnterPlacing(side: side, positions: positions)
        case .willReset:
            self.diskAnimation = nil
        case .didReset:
            self.updateViewsForReset()
        }
    }
}

private extension Presenter {
    /// UI全体を初期化するためのイベントを送信する
    func updateViewsForInitial() {
        self.sendEvent(.updateBoardView)
        self.sendEvent(.updatePlayerControls)
        self.sendEvent(.updateCountLabels)
        self.sendEvent(.updateMessageViews)
    }
    
    /// ゲームをリセットした後にUIを更新するためのイベントを送信する
    func updateViewsForReset() {
        self.sendEvent(.updateBoardView)
        self.sendEvent(.updatePlayerControls)
        self.sendEvent(.updateCountLabels)
    }
    
    /// ターンが変わった時にUIを更新するためのイベントを送信する
    func updateViewsForDidChangeTurn() {
        self.sendEvent(.updateMessageViews)
        self.sendEvent(.updateCountLabels)
    }
    
    /// ディスクが置かれた時の処理
    func didEnterPlacing(side: Side, positions: [Position]) {
        let animation = DiskAnimation(disk: side.disk, positions: positions)
        self.diskAnimation = animation
        self.setNextBoardViewDisk(animation: animation)
    }
    
    /// ディスクを配置するイベントを送信する
    func setNextBoardViewDisk(animation: DiskAnimation) {
        guard let position = animation.popPosition() else { fatalError() }
        self.sendEvent(.setBoardViewDisk(animation.disk, at: position, animationID: animation.id))
    }
    
    /// ディスクを配置するアニメーションが全て終わった時の処理
    func endSetBoardViewDisks() {
        self.diskAnimation = nil
        self.interactor?.doAction(.endPlaceDisks)
    }
    
    func sendEvent(_ event: Event) {
        self.eventReceiver?.receiveEvent(event)
    }
}

private extension Presenter.DiskAnimation {
    func popPosition() -> Position? {
        if self.remainPositions.isEmpty {
            return nil
        } else {
            return self.remainPositions.removeFirst()
        }
    }
}

extension Interactor: Interactable {}
