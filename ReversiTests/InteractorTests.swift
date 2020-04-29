import XCTest
@testable import Reversi

private class DataStoreMock: InteractorDataStore {
    var saveHandler: ((DataStore.Parameters) throws -> Void)?
    var loadHandler: (() throws -> DataStore.Parameters)?
    
    func save(_ parameters: DataStore.Parameters) throws {
        try self.saveHandler?(parameters)
    }
    
    func load() throws -> DataStore.Parameters {
        guard let handler = self.loadHandler else {
            throw TestError.handlerNotFound
        }
        
        return try handler()
    }
    
    enum TestError: Error {
        case handlerNotFound
    }
}

class InteractorTests: XCTestCase {
    func testNewGame() {
        let dataStore = DataStoreMock()
        let interactor = Interactor(dataStore: dataStore)
        
        XCTAssertEqual(interactor.board.disks, TestUtils.initialDisks)
        XCTAssertEqual(interactor.darkPlayer, .manual)
        XCTAssertEqual(interactor.lightPlayer, .manual)
        
        if case .launching(let side) = interactor.state {
            XCTAssertEqual(side, .dark)
        } else {
            XCTFail()
        }
    }
}
