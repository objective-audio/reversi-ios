import XCTest
@testable import Reversi

class StateTests: XCTestCase {
    func testStatus() {
        XCTAssertEqual(State.launching(side: .dark).status, .turn(side: .dark))
        XCTAssertEqual(State.waiting(side: .dark, player: .manual).status, .turn(side: .dark))
        XCTAssertEqual(State.waiting(side: .dark, player: .computer).status, .turn(side: .dark))
        XCTAssertEqual(State.passing(side: .dark).status, .turn(side: .dark))
        XCTAssertEqual(State.placing(side: .dark, positions: []).status, .turn(side: .dark))
        
        XCTAssertEqual(State.launching(side: .light).status, .turn(side: .light))
        XCTAssertEqual(State.waiting(side: .light, player: .manual).status, .turn(side: .light))
        XCTAssertEqual(State.waiting(side: .light, player: .computer).status, .turn(side: .light))
        XCTAssertEqual(State.passing(side: .light).status, .turn(side: .light))
        XCTAssertEqual(State.placing(side: .light, positions: []).status, .turn(side: .light))
        
        XCTAssertEqual(State.result(.won(side: .dark)).status, .result(.won(side: .dark)))
        XCTAssertEqual(State.result(.won(side: .light)).status, .result(.won(side: .light)))
        XCTAssertEqual(State.result(.tied).status, .result(.tied))
    }
}
