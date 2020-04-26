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
    
    private let presenter: Presenter = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.presenter.displayer = self
        
        self.boardView.delegate = self
        self.messageDiskSize = self.messageDiskSizeConstraint.constant
        
        self.updateAll()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.presenter.begin()
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
        self.presenter.selectBoard(position: .init(x: x, y: y))
    }
}

extension ViewController: Displayable {
    func updateAll() {
        self.updateBoardView()
        self.updatePlayerControls()
        self.updateMessageViews()
        self.updateCountLabels()
    }
    
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        self.countLabels[Side.dark.rawValue].text = "\(self.presenter.diskCount(of: .dark))"
        self.countLabels[Side.light.rawValue].text = "\(self.presenter.diskCount(of: .light))"
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch self.presenter.status {
        case .turn(let side):
            self.messageDiskSizeConstraint.constant = self.messageDiskSize
            self.messageDiskView.disk = side.disk
            self.messageLabel.text = "'s turn"
        case .won(let side):
            self.messageDiskSizeConstraint.constant = self.messageDiskSize
            self.messageDiskView.disk = side.disk
            self.messageLabel.text = " won"
        case .tied:
            self.messageDiskSizeConstraint.constant = 0
            self.messageLabel.text = "Tied"
        }
    }
    
    func setBoardDisk(_ disk: Disk?, at position: Board.Position, animated: Bool, completion: ((Bool) -> Void)?) {
        self.boardView.setDisk(disk, atX: position.x, y: position.y, animated: animated, completion: completion)
    }
    
    func setBoardDisk(_ disk: Disk?, at position: Board.Position) {
        self.setBoardDisk(disk, at: position, animated: false, completion: nil)
    }
    
    func startPlayerActivityIndicatorAnimating(side: Side) {
        self.playerActivityIndicators[side.rawValue].startAnimating()
    }
    
    func stopPlayerActivityIndicatorAnimating(side: Side) {
        self.playerActivityIndicators[side.rawValue].stopAnimating()
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
}

private extension ViewController {
    func updateBoardView() {
        for (y, boardLine) in self.presenter.disks.enumerated() {
            for (x, disk) in boardLine.enumerated() {
                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
            }
        }
    }
    
    func updatePlayerControls() {
        self.playerControls[Side.dark.rawValue].selectedSegmentIndex = self.presenter.darkPlayer.rawValue
        self.playerControls[Side.light.rawValue].selectedSegmentIndex = self.presenter.lightPlayer.rawValue
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
