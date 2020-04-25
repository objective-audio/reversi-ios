import Foundation

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func cancel() {
        if self.isCancelled { return }
        self.isCancelled = true
        self.body?()
    }
}
