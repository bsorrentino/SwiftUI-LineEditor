import XCTest
@testable import LineEditor

final class LineEditorTests: XCTestCase {
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(LineEditor().text, "Hello, World!")
        
        let items = (0...50).map { "line\($0)" }
        
        XCTAssertEqual(items.count , 51)
        XCTAssertEqual(items.endIndex , 51)

        XCTAssertFalse( items.indices.contains( items.endIndex ))
    }
}
