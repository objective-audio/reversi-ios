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
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.viewHasAppeared { return }
        self.viewHasAppeared = true
        self.waitForPlayer()
    }
}

// MARK: Reversi logics

extension ViewController {
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = self.presenter.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.presenter.animationCanceller = nil
            }
            self.presenter.animationCanceller = Canceller(cleanUp)
            self.animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.presenter.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
                self.presenter.save()
                self.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.presenter.setDisk(disk, atX: x, y: y)
                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for (x, y) in diskCoordinates {
                    self.presenter.setDisk(disk, atX: x, y: y)
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion?(true)
                self.presenter.save()
                self.updateCountLabels()
            }
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.presenter.animationCanceller!
        self.presenter.setDisk(disk, atX: x, y: y)
        self.boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.presenter.setDisk(disk, atX: x, y: y)
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        self.presenter.waitForPlayer()
    }
    
    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = self.presenter.turn else { return }

        turn.flip()
        
        if self.presenter.validMoves(for: turn).isEmpty {
            if self.presenter.validMoves(for: turn.flipped).isEmpty {
                self.presenter.turn = nil
                self.updateMessageViews()
            } else {
                self.presenter.turn = turn
                self.updateMessageViews()
                
                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                    self?.nextTurn()
                })
                present(alertController, animated: true)
            }
        } else {
            self.presenter.turn = turn
            self.updateMessageViews()
            self.waitForPlayer()
        }
    }
    
    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.presenter.turn else { preconditionFailure() }
        let (x, y) = self.presenter.validMoves(for: turn).randomElement()!

        self.playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.presenter.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        self.presenter.playerCancellers[turn] = canceller
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    @IBAction func pressResetButton(_ sender: UIButton) {
        #warning("presenter経由にする")
        self.presentConfirmationView()
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        guard let sideIndex = self.playerControls.firstIndex(of: sender) else { fatalError() }
        let side: Disk = Disk(index: sideIndex)
        guard let player = Player(rawValue: sender.selectedSegmentIndex) else { fatalError() }
        
        switch side {
        case .dark:
            self.presenter.darkPlayer = player
        case .light:
            self.presenter.lightPlayer = player
        }
        
        self.presenter.save()
        
        if let canceller = self.presenter.playerCancellers[side] {
            canceller.cancel()
        }
        
        if !self.presenter.isAnimating, side == self.presenter.turn, case .computer = player {
            self.playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = self.presenter.turn else { return }
        if self.presenter.isAnimating { return }
        guard case .manual = self.presenter.player(for: turn) else { return }
        // try? because doing nothing when an error occurs
        try? self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

extension ViewController: Displayable {
    func updateAll() {
        self.updateBoardView()
        self.updatePlayerControls()
        self.updateMessageViews()
        self.updateCountLabels()
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
        self.playerControls[Disk.dark.index].selectedSegmentIndex = self.presenter.darkPlayer.rawValue
        self.playerControls[Disk.light.index].selectedSegmentIndex = self.presenter.lightPlayer.rawValue
    }
    
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Disk.allCases {
            self.countLabels[side.index].text = "\(self.presenter.diskCount(of: side))"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch self.presenter.turn {
        case .some(let side):
            self.messageDiskSizeConstraint.constant = self.messageDiskSize
            self.messageDiskView.disk = side
            self.messageLabel.text = "'s turn"
        case .none:
            if let winner = self.presenter.sideWithMoreDisks() {
                self.messageDiskSizeConstraint.constant = self.messageDiskSize
                self.messageDiskView.disk = winner
                self.messageLabel.text = " won"
            } else {
                self.messageDiskSizeConstraint.constant = 0
                self.messageLabel.text = "Tied"
            }
        }
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
            guard let self = self else { return }
            
            #warning("以下、presenter側に移動する")
            self.presenter.animationCanceller?.cancel()
            self.presenter.animationCanceller = nil
            
            for side in Disk.allCases {
                self.presenter.playerCancellers[side]?.cancel()
                self.presenter.playerCancellers.removeValue(forKey: side)
            }
            
            self.presenter.newGame()
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }
}
