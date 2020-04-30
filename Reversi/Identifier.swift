import Foundation

class Identifier {}

extension Identifier: Equatable {
    static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
