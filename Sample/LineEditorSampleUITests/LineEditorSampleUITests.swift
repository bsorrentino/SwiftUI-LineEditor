//
//  LineEditorSampleUITests.swift
//  LineEditorSampleUITests
//
//  Created by Bartolomeo Sorrentino on 09/11/22.
//

import XCTest

extension XCUIElement {
    
    func valueAsString() -> String? {
        self.value as? String
    }
    
    func clearText() {
        
        if let s = self.value as? String {
            
            s.forEach { _ in
                self.typeText( XCUIKeyboardKey.delete.rawValue )
            }
        }
        
    }
    
}

extension XCTestCase {

    ///
    /// https://stackoverflow.com/a/42222302/521197
    ///
    private func wait(for duration: TimeInterval,  handler: (() -> Void)? = nil) {
        
        let waitExpectation = expectation(description: "Waiting")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
          waitExpectation.fulfill()
        }

        // We use a buffer here to avoid flakiness with Timer on CI
        waitForExpectations(timeout: duration + 0.5)
        
        handler?()
    }
    
    
    func waitUntilExists( elements:[XCUIElement], timeout: TimeInterval, handler: (( [XCUIElement] ) -> Void)? = nil ) {
        
        let expectations = elements.map {
            expectation( for: NSPredicate(format: "exists == 1"), evaluatedWith: $0 )
        }
        
        wait( for: expectations, timeout: timeout )
        
        handler?( elements )
    }
    
    func waitUntilExists( element:XCUIElement, timeout: TimeInterval, handler: (( XCUIElement) -> Void)? = nil ) {
        
        let result = element.waitForExistence(timeout: timeout)
        XCTAssertTrue( result )
        
        handler?( element )
        
    }

}

final class LineEditorSampleUITests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .portrait
        }
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    typealias CellElements = (label:XCUIElement, textField:XCUIElement)
    
    private func getCellElements( table: XCUIElement, atRow row: Int, handler: (( CellElements ) -> Void)? = nil ) -> CellElements {
        
        XCTAssertEqual( table.elementType, XCUIElement.ElementType.table)
        XCTAssertTrue( row >= 0 && row < table.cells.count, "index: \(row) is out of bound \(table.cells.count)")
        
        let cell = table.cells.element(boundBy: row)
        XCTAssertTrue(cell.exists)
        
        let textField = cell.textFields["LineText"]
        XCTAssertTrue(textField.exists)
        
        let label = cell.staticTexts["LineLabel"]
        XCTAssertTrue(label.exists)
        
        let result = (label: label, textField: textField)
        
        handler?( result )
        
        return result
        
    }
    
    
    private func deleteRow( table: XCUIElement, atRow row: Int ) {
        
        XCTAssertEqual( table.elementType, XCUIElement.ElementType.table)
        XCTAssertTrue( row >= 0 && row < table.cells.count, "index: \(row) is out of bound \(table.cells.count)")
        
        let prevCount = table.cells.count
        
        table.cells.element(boundBy: row).tap()
        table.cells.element(boundBy: row).swipeLeft()
        table.cells.element(boundBy: row).buttons["Delete"].tap()
        
        XCTAssertEqual( table.cells.count , prevCount - 1 )
        
    }
    
    
    func testClipboard() throws {

        let NUM_ITEMS = 51
        let ITEM_TEXT = { (index: Int) in "line\(index)" }
        
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        let table = app.tables.element
        
        XCTAssertEqual( table.cells.count, NUM_ITEMS )
        
        let ( _, textField1 ) = getCellElements( table: table, atRow: 1 )
        
        XCTAssertEqual(textField1.valueAsString(), ITEM_TEXT(1) )
        
        UIPasteboard.general.string = "ABCDE"

        textField1.tap()

        let paste = app.menuItems["Paste"]

        let lastCharCursor = textField1.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.0))
        lastCharCursor.tap()

        XCTAssertTrue(paste.exists)

        paste.tap()
        
        XCTAssertEqual(textField1.valueAsString(), "\(ITEM_TEXT(1))ABCDE")
        
        textField1.tap()

        textField1.typeText(XCUIKeyboardKey.delete.rawValue)
        
        XCTAssertEqual(textField1.valueAsString(), "\(ITEM_TEXT(1))ABCD")
        
    }
    
    func testExample() throws {
        
        var NUM_ITEMS = 51
        let LAST_ITEM = { NUM_ITEMS - 1 }
        
        let LAST_ITEM_TEXT = { "line\(LAST_ITEM())" }

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        let table = app.tables.element
        
        XCTAssertEqual( table.cells.count, NUM_ITEMS )
        
        let _ = getCellElements( table: table, atRow: LAST_ITEM()) {
            
            let ( _, textField)  =  $0
            
            XCTAssertEqual(textField.valueAsString(), LAST_ITEM_TEXT())
        }
        
        
        deleteRow( table: table, atRow: LAST_ITEM())
        
        NUM_ITEMS -= 1
        
        XCTAssertEqual( table.cells.count, NUM_ITEMS )
        
        let _ = getCellElements( table: table, atRow: LAST_ITEM()) {
            let ( text, textField) = $0
            
            XCTAssertEqual( text.label , "\(LAST_ITEM())")
            XCTAssertEqual( textField.valueAsString() , LAST_ITEM_TEXT())
            
            textField.tap()
            
        }
        
        waitUntilExists(elements: [ app.buttons["Add Above"], app.buttons["Add Below"]  ], timeout: 5) { btn in
            
            let addAbove = btn[0]; let addBelow = btn[1]
            
            addBelow.tap() // add Below
            NUM_ITEMS += 1
            XCTAssertEqual( table.cells.count, NUM_ITEMS )
            
            
            let ( _, textField1 ) = self.getCellElements( table: table, atRow: LAST_ITEM() )
            textField1.typeText( "+line\(LAST_ITEM())")

            let prev_last_item = LAST_ITEM()

            addAbove.tap() // Add Above
            NUM_ITEMS += 1
            XCTAssertEqual( table.cells.count, NUM_ITEMS )
            
            let ( _, textField2 ) = self.getCellElements( table: table, atRow: prev_last_item)
            textField2.typeText( "+line\(prev_last_item)")
            
            let ( _, textField3 ) = self.getCellElements( table: table, atRow: LAST_ITEM())
            textField3.tap()
            textField3.clearText()
            textField3.typeText( "+line\(LAST_ITEM())")
            
        }
        
        let prev_last_item = LAST_ITEM() - 1
        
        let _ = self.getCellElements( table: table, atRow: prev_last_item) {
            
            let ( text, textField) = $0
            XCTAssertEqual( text.label , "\(prev_last_item)")
            XCTAssertEqual( textField.valueAsString() , "+line\(prev_last_item)")
            
        }

        let _ = getCellElements( table: table, atRow: LAST_ITEM()) {
            
            let ( text, textField) = $0
            XCTAssertEqual( text.label , "\(LAST_ITEM())")
            XCTAssertEqual( textField.valueAsString() , "+line\(LAST_ITEM())")
            
        }

        
        for _ in 1...15 {
         
            deleteRow(table: table, atRow: 1 )
        }
        
        XCTAssertEqual( table.cells.count, NUM_ITEMS - 15 )
         
    }
    
    //    func testLaunchPerformance() throws {
    //        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
    //            // This measures how long it takes to launch your application.
    //            measure(metrics: [XCTApplicationLaunchMetric()]) {
    //                XCUIApplication().launch()
    //            }
    //        }
    //    }
}
