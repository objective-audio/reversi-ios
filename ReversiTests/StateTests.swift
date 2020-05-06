import XCTest
@testable import Reversi

class StateTests: XCTestCase {
    func testStatus() {
        XCTAssertEqual(State.launching(side: .dark).status, .turn(side: .dark))
        XCTAssertEqual(State.operating(side: .dark, player: .manual).status, .turn(side: .dark))
        XCTAssertEqual(State.operating(side: .dark, player: .computer).status, .turn(side: .dark))
        XCTAssertEqual(State.passing(side: .dark).status, .turn(side: .dark))
        XCTAssertEqual(State.placing(side: .dark, positions: []).status, .turn(side: .dark))
        
        XCTAssertEqual(State.launching(side: .light).status, .turn(side: .light))
        XCTAssertEqual(State.operating(side: .light, player: .manual).status, .turn(side: .light))
        XCTAssertEqual(State.operating(side: .light, player: .computer).status, .turn(side: .light))
        XCTAssertEqual(State.passing(side: .light).status, .turn(side: .light))
        XCTAssertEqual(State.placing(side: .light, positions: []).status, .turn(side: .light))
        
        XCTAssertEqual(State.resulting(.won(side: .dark)).status, .result(.won(side: .dark)))
        XCTAssertEqual(State.resulting(.won(side: .light)).status, .result(.won(side: .light)))
        XCTAssertEqual(State.resulting(.tied).status, .result(.tied))
    }
}
