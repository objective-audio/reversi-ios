import UIKit

private let lineWidth: CGFloat = 2

class BoardView: UIView {
    private var cellViews: [CellView] = []
    private var actions: [CellSelectionAction] = []
    
    let width: Int = Board.width
    let height: Int = Board.height
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    let xRange: Range<Int>
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    let yRange: Range<Int>
    
    /// セルがタップされたときの挙動を移譲するためのオブジェクトです。
    weak var delegate: BoardViewDelegate?
    
    override init(frame: CGRect) {
        self.xRange = 0 ..< self.width
        self.yRange = 0 ..< self.height
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder: NSCoder) {
        self.xRange = 0 ..< self.width
        self.yRange = 0 ..< self.height
        super.init(coder: coder)
        self.setUp()
    }
    
    private func setUp() {
        self.backgroundColor = UIColor(named: "DarkColor")!
        
        let cellViews: [CellView] = (0 ..< (width * height)).map { _ in
            let cellView = CellView()
            cellView.translatesAutoresizingMaskIntoConstraints = false
            return cellView
        }
        self.cellViews = cellViews
        
        cellViews.forEach(self.addSubview(_:))
        for i in cellViews.indices.dropFirst() {
            NSLayoutConstraint.activate([
                cellViews[0].widthAnchor.constraint(equalTo: cellViews[i].widthAnchor),
                cellViews[0].heightAnchor.constraint(equalTo: cellViews[i].heightAnchor),
            ])
        }
        
        NSLayoutConstraint.activate([
            cellViews[0].widthAnchor.constraint(equalTo: cellViews[0].heightAnchor),
        ])
        
        for y in self.yRange {
            for x in self.xRange {
                let topNeighborAnchor: NSLayoutYAxisAnchor
                if let cellView = self.cellViewAt(x: x, y: y - 1) {
                    topNeighborAnchor = cellView.bottomAnchor
                } else {
                    topNeighborAnchor = self.topAnchor
                }
                
                let leftNeighborAnchor: NSLayoutXAxisAnchor
                if let cellView = self.cellViewAt(x: x - 1, y: y) {
                    leftNeighborAnchor = cellView.rightAnchor
                } else {
                    leftNeighborAnchor = self.leftAnchor
                }
                
                let cellView = self.cellViewAt(x: x, y: y)!
                NSLayoutConstraint.activate([
                    cellView.topAnchor.constraint(equalTo: topNeighborAnchor, constant: lineWidth),
                    cellView.leftAnchor.constraint(equalTo: leftNeighborAnchor, constant: lineWidth),
                ])
                
                if y == self.height - 1 {
                    NSLayoutConstraint.activate([
                        self.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: lineWidth),
                    ])
                }
                if x == self.width - 1 {
                    NSLayoutConstraint.activate([
                        self.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: lineWidth),
                    ])
                }
            }
        }
        
        self.reset()
        
        for y in self.yRange {
            for x in self.xRange {
                let cellView: CellView = self.cellViewAt(x: x, y: y)!
                let action = CellSelectionAction(boardView: self, x: x, y: y)
                self.actions.append(action) // To retain the `action`
                cellView.addTarget(action, action: #selector(action.selectCell), for: .touchUpInside)
            }
        }
    }
    
    /// 盤をゲーム開始時に状態に戻します。このメソッドはアニメーションを伴いません。
    func reset() {
        for y in  self.yRange {
            for x in self.xRange {
                self.setDisk(nil, atX: x, y: y, animated: false)
            }
        }
        
        self.setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1, animated: false)
        self.setDisk(.dark, atX: width / 2, y: height / 2 - 1, animated: false)
        self.setDisk(.dark, atX: width / 2 - 1, y: height / 2, animated: false)
        self.setDisk(.light, atX: width / 2, y: height / 2, animated: false)
    }
    
    private func cellViewAt(x: Int, y: Int) -> CellView? {
        guard self.xRange.contains(x) && self.yRange.contains(y) else { return nil }
        return self.cellViews[y * width + x]
    }
    
    /// `x`, `y` で指定されたセルの状態を返します。
    /// セルにディスクが置かれていない場合、 `nil` が返されます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: セルにディスクが置かれている場合はそのディスクの値を、置かれていない場合は `nil` を返します。
    func diskAt(x: Int, y: Int) -> Disk? {
        self.cellViewAt(x: x, y: y)?.disk
    }
    
    /// `x`, `y` で指定されたセルの状態を、与えられた `disk` に変更します。
    /// `animated` が `true` の場合、アニメーションが実行されます。
    /// アニメーションの完了通知は `completion` ハンドラーで受け取ることができます。
    /// - Parameter disk: セルに設定される新しい状態です。 `nil` はディスクが置かれていない状態を表します。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter animated: セルの状態変更を表すアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーションの完了通知を受け取るハンドラーです。
    ///     `animated` に `false` が指定された場合は状態が変更された後で即座に同期的に呼び出されます。
    ///     ハンドラーが受け取る `Bool` 値は、 `UIView.animate()`  等に準じます。
    func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard let cellView = self.cellViewAt(x: x, y: y) else {
            preconditionFailure() // FIXME: Add a message.
        }
        cellView.setDisk(disk, animated: animated, completion: completion)
    }
}

protocol BoardViewDelegate: AnyObject {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int)
}

private class CellSelectionAction: NSObject {
    private weak var boardView: BoardView?
    let x: Int
    let y: Int
    
    init(boardView: BoardView, x: Int, y: Int) {
        self.boardView = boardView
        self.x = x
        self.y = y
    }
    
    @objc func selectCell() {
        guard let boardView = self.boardView else { return }
        boardView.delegate?.boardView(boardView, didSelectCellAtX: x, y: y)
    }
}
