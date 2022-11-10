//
//  LineEditorSampleUITests.swift
//  LineEditorSampleUITests
//
//  Created by Bartolomeo Sorrentino on 09/11/22.
//

import XCTest

final class LineEditorSampleUITests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        if UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .landscapeLeft
        }
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        XCTAssertEqual(  app.tables.count, 1 )
        
        let table = app.tables.element
        
        XCTAssertEqual( table.cells.count , 22 )
        
        var lastTextField = table.cells.element(boundBy: 21).textFields["LineText"]
        
        XCTAssertTrue(lastTextField.exists)
        XCTAssertEqual(lastTextField.value as! String, "line_last")

       
        table.cells.element(boundBy: 21).swipeLeft()
        table.cells.element(boundBy: 21).buttons["Delete"].tap()
        
        XCTAssertEqual( table.cells.count , 21 )
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        lastTextField = table.cells.element(boundBy: 20).textFields["LineText"]
        
        XCTAssertTrue(lastTextField.exists)
        XCTAssertEqual(lastTextField.value as! String, "line21")


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
