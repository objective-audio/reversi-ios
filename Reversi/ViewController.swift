import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    
    private let presenter: Presenter = .init(interactor: Interactor.shared)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.boardView.delegate = self
        self.messageDiskSize = self.messageDiskSizeConstraint.constant
        self.presenter.eventReceiver = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.presenter.viewDidAppear()
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    @IBAction func pressResetButton(_ sender: UIButton) {
        self.presentConfirmationView()
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        guard let sideIndex = self.playerControls.firstIndex(of: sender) else { fatalError() }
        guard let side = Side(rawValue: sideIndex) else { fatalError() }
        guard let player = Player(rawValue: sender.selectedSegmentIndex) else { fatalError() }
        
        self.presenter.changePlayer(player, side: side)
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        self.presenter.selectBoard(at: .init(x: x, y: y))
    }
}

extension ViewController: PresenterEventReceiver {
    func receiveEvent(_ event: Presenter.Event) {
        switch event {
        case .updateBoardView:
            self.updateBoardView()
        case .updatePlayerControls:
            self.updatePlayerControls()
        case .updateCountLabels:
            self.updateCountLabels()
        case .updateMessageViews:
            self.updateMessageViews()
        case .presentPassView:
            self.presentPassView()
        case .startPlayerActivityIndicatorAnimating(let side):
            self.playerActivityIndicators[side.rawValue].startAnimating()
        case .stopPlayerActivityIndicatorAnimating(let side):
            self.playerActivityIndicators[side.rawValue].stopAnimating()
        case .setBoardViewDisk(let disk, let position, let animationID):
            self.boardView.setDisk(disk, atX: position.x, y: position.y, animated: animationID != nil) { [weak self] isFinished in
                guard let animationID = animationID else { return }
                self?.presenter.endSetBoardDisk(animationID: animationID, isFinished: isFinished)
            }
        }
    }
}

private extension ViewController {
    func updateBoardView() {
        guard let board = self.presenter.board else { return }
        
        board.all.forEach {
            self.boardView.setDisk($0.disk, atX: $0.position.x, y: $0.position.y, animated: false)
        }
    }
    
    func updatePlayerControls() {
        for side in Side.allCases {
            guard let player = self.presenter.player(for: side) else { continue }
            self.playerControls[side.rawValue].selectedSegmentIndex = player.rawValue
        }
    }
    
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Side.allCases {
            guard let diskCount = self.presenter.diskCount(of: side) else { continue }
            self.countLabels[side.rawValue].text = "\(diskCount)"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        guard let status = self.presenter.status else { return }
        
        switch status {
        case .turn(let side):
            self.messageDiskSizeConstraint.constant = self.messageDiskSize
            self.messageDiskView.disk = side.disk
            self.messageLabel.text = "'s turn"
        case .result(.won(let side)):
            self.messageDiskSizeConstraint.constant = self.messageDiskSize
            self.messageDiskView.disk = side.disk
            self.messageLabel.text = " won"
        case .result(.tied):
            self.messageDiskSizeConstraint.constant = 0
            self.messageLabel.text = "Tied"
        }
    }
    
    func presentPassView() {
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            self?.presenter.pass()
        })
        present(alertController, animated: true)
    }
    
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    func presentConfirmationView() {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.presenter.reset()
        })
        present(alertController, animated: true)
    }
}
