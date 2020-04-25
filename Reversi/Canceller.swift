import Foundation

final class Canceller {
    var isCancelled: Bool { self.body == nil }
    
    private var body: (() -> Void)?
    
    init(_ body: @escaping (() -> Void)) {
        self.body = body
    }
    
    func cancel() {
        self.body?()
        self.body = nil
    }
}
