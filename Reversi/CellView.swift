import UIKit

#warning("0.25に戻す")
private let animationDuration: TimeInterval = 0.1

class CellView: UIView {
    private let button: UIButton = UIButton()
    private let diskView: DiskView = DiskView()
    
    private var _disk: Disk?
    var disk: Disk? {
        get { self._disk }
        set { self.setDisk(newValue, animated: true) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setUp()
    }
    
    private func setUp() {
        do { // button
            self.button.translatesAutoresizingMaskIntoConstraints = false
            do { // backgroundImage
                UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
                defer { UIGraphicsEndImageContext() }
                
                let color: UIColor = UIColor(named: "CellColor")!
                color.set()
                UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
                
                let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()!
                self.button.setBackgroundImage(backgroundImage, for: .normal)
                self.button.setBackgroundImage(backgroundImage, for: .disabled)
            }
            self.addSubview(self.button)
        }

        do { // diskView
            self.diskView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.diskView)
        }

        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.button.frame = bounds
        self.layoutDiskView()
    }
    
    private func layoutDiskView() {
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
        if self._disk == nil || self.diskView.disk == self._disk {
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        } else {
            diskSize = CGSize(width: 0, height: diskDiameter)
        }
        self.diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        self.diskView.alpha = self._disk == nil ? 0.0 : 1.0
    }
    
    func setDisk(_ disk: Disk?, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let diskBefore: Disk? = self._disk
        self._disk = disk
        let diskAfter: Disk? = self._disk
        if animated {
            switch (diskBefore, diskAfter) {
            case (.none, .none):
                completion?(true)
            case (.none, .some(let animationDisk)):
                self.diskView.disk = animationDisk
                fallthrough
            case (.some, .none):
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.layoutDiskView()
                }, completion: { finished in
                    completion?(finished)
                })
            case (.some, .some):
                UIView.animate(withDuration: animationDuration / 2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                    self?.layoutDiskView()
                }, completion: { [weak self] finished in
                    guard let self = self else { return }
                    if self.diskView.disk == self._disk {
                        completion?(finished)
                    }
                    guard let diskAfter = self._disk else {
                        completion?(finished)
                        return
                    }
                    self.diskView.disk = diskAfter
                    UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
                        self?.layoutDiskView()
                    }, completion: { finished in
                        completion?(finished)
                    })
                })
            }
        } else {
            if let diskAfter = diskAfter {
                self.diskView.disk = diskAfter
            }
            completion?(true)
            setNeedsLayout()
        }
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        self.button.addTarget(target, action: action, for: controlEvents)
    }
    
    func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        self.button.removeTarget(target, action: action, for: controlEvents)
    }
    
    func actions(forTarget target: Any?, forControlEvent controlEvent: UIControl.Event) -> [String]? {
        self.button.actions(forTarget: target, forControlEvent: controlEvent)
    }
    
    var allTargets: Set<AnyHashable> {
        self.button.allTargets
    }
    
    var allControlEvents: UIControl.Event {
        self.button.allControlEvents
    }
}
