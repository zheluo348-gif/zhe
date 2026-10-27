import XCTest

final class HomeAndSharedDrawingTests: XCTestCase {
    @MainActor private func fresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()
        XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout: 12))
        app.buttons["enterCircle"].tap()
        XCTAssertTrue(app.buttons["sceneFeed"].waitForExistence(timeout: 6))
        return app
    }
    @MainActor private func tap(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { element.tap(); return }
            app.swipeUp()
        }
        XCTFail("Cannot reach \(element)")
    }

    @MainActor func testHomeStatusCanBeEditedAndPersists() {
        let app = fresh()
        XCTAssertTrue(app.staticTexts["阿哲的此刻"].exists)
        XCTAssertTrue(app.staticTexts["心情 · 待分享"].exists)
        XCTAssertFalse(app.staticTexts["电量：68%"].exists)
        tap(app.buttons["updateMyMoment"], app: app)
        let field = app.descendants(matching: .any).matching(identifier: "momentStatusInput").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("A quiet evening together")
        tap(app.buttons["saveMomentStatus"], app: app)
        XCTAssertEqual(app.staticTexts["myMomentText"].label, "A quiet evening together")
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch()
        XCTAssertTrue(app.staticTexts["myMomentText"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.staticTexts["myMomentText"].label, "A quiet evening together")
    }

    @MainActor func testSharedDrawingTwoTurnsFinishAndSave() {
        let app = fresh()
        app.buttons["tab_1"].tap()
        app.buttons["startSharedDrawing"].tap()
        let canvas = app.otherElements["sharedDrawingCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)
        app.textFields["sharedDrawingNote"].tap(); app.textFields["sharedDrawingNote"].typeText("Half a cat")
        app.buttons["closeSharedDrawing"].tap()
        app.buttons["交出本轮并返回"].tap()
        XCTAssertTrue(app.buttons["openSharedDrawing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["轮到阿哲啦"].exists)
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch(); app.buttons["tab_1"].tap()
        app.buttons["openSharedDrawing"].tap()
        XCTAssertTrue(app.textFields["sharedDrawingNote"].waitForExistence(timeout: 5))
        app.textFields["sharedDrawingNote"].tap(); app.textFields["sharedDrawingNote"].typeText("And a little fish")
        app.buttons["closeSharedDrawing"].tap(); app.buttons["交出本轮并返回"].tap()
        app.buttons["openSharedDrawing"].tap()
        XCTAssertTrue(app.buttons["finishSharedDrawing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["finishSharedDrawing"].isEnabled)
        app.buttons["finishSharedDrawing"].tap()
        tap(app.buttons["saveSharedDrawingMemory"], app: app)
        XCTAssertFalse(app.buttons["saveSharedDrawingMemory"].isEnabled)
        app.buttons["closeSharedDrawing"].tap()
        app.buttons["返回首页"].tap(); app.buttons["tab_2"].tap()
        XCTAssertTrue(app.staticTexts["我们一起画的小日常"].waitForExistence(timeout: 5))
    }
}
