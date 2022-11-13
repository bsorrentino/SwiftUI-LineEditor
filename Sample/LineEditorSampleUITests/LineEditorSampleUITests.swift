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
        
        let label = table.cells.element(boundBy: row).staticTexts["LineLabel"]
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
    
    private func waitUntilExists( elements:[XCUIElement], timeout: TimeInterval, handler: (( [XCUIElement] ) -> Void)? = nil ) {
        
        let expectations = elements.map {
            expectation( for: NSPredicate(format: "exists == 1"), evaluatedWith: $0 )
        }
        
        wait( for: expectations, timeout: timeout )
        
        handler?( elements )
    }
    
    private func waitUntilExists( element:XCUIElement, timeout: TimeInterval, handler: (( XCUIElement) -> Void)? = nil ) {
        
        let result = element.waitForExistence(timeout: timeout)
        XCTAssertTrue( result )
        
        handler?( element )
        
    }
    
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        let table = app.tables.element
        
        XCTAssertEqual( table.cells.count, 22 )
        
        let _ = getCellElements( table: table, atRow: 21) {
            
            let ( _, textField)  =  $0
            
            XCTAssertEqual(textField.valueAsString(), "line_last")
        }
        
        
        deleteRow( table: table, atRow: 21)
        
        XCTAssertEqual( table.cells.count, 21 )
        
        let _ = getCellElements( table: table, atRow: 20) {
            let ( text, textField) = $0
            
            XCTAssertEqual( text.label , "20")
            XCTAssertEqual( textField.valueAsString() , "line21")
            
            textField.tap()
            
        }
        
        waitUntilExists(elements: [ app.buttons["Add Above"], app.buttons["Add Below"]  ], timeout: 5) { btn in
            
            let addAbove = btn[0]; let addBelow = btn[1]
            
            addBelow.tap() // add Below
            XCTAssertEqual( table.cells.count, 22 )
            
            let ( _, textField1 ) = self.getCellElements( table: table, atRow: 21)
            textField1.typeText( "+line21")
            
            addAbove.tap() // Add Above
            XCTAssertEqual( table.cells.count, 23 )
            
            let ( _, textField2 ) = self.getCellElements( table: table, atRow: 21)
            textField2.typeText( "+line21")
            
            let ( _, textField3 ) = self.getCellElements( table: table, atRow: 22)
            textField3.tap()
            textField3.clearText()
            
            textField3.typeText( "+line22")
        }
        
        let _ = getCellElements( table: table, atRow: 21) {
            
            let ( text, textField) = $0
            XCTAssertEqual( text.label , "21")
            XCTAssertEqual( textField.valueAsString() , "+line21")
            
        }
        
        let _ = getCellElements( table: table, atRow: 22) {
            
            let ( text, textField) = $0
            XCTAssertEqual( text.label , "22")
            XCTAssertEqual( textField.valueAsString() , "+line22")
            
        }
        
        
        for _ in 1...15 {
         
            deleteRow(table: table, atRow: 1 )
        }
        
        XCTAssertEqual( table.cells.count, 23 - 15 )
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
