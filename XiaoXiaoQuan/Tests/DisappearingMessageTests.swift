import XCTest

final class DisappearingMessageTests: XCTestCase {
    @MainActor private func fresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()
        XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout: 12))
        app.buttons["enterCircle"].tap()
        app.buttons["tab_1"].tap()
        XCTAssertTrue(app.buttons["messageRetention"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor private func send(_ body: String, duration: Int?, app: XCUIApplication) {
        if let duration {
            app.buttons["messageRetention"].tap()
            app.buttons["burnDuration_\(duration)"].tap()
        }
        let input = app.textFields["messageInput"]
        input.tap(); input.typeText(body)
        app.buttons["sendMessage"].tap()
    }

    @MainActor func testOptionalModeLeavesOrdinaryHistory() {
        let app = fresh()
        send("Ordinary saved message", duration: nil, app: app)
        XCTAssertTrue(app.staticTexts["Ordinary saved message"].waitForExistence(timeout: 5))
        send("Only inside the envelope", duration: 5, app: app)
        XCTAssertTrue(app.buttons["openDisappearingMessage"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Only inside the envelope"].exists)
        XCTAssertTrue(app.buttons["messageRetention"].label.contains("普通消息"))
        send("Another ordinary message", duration: nil, app: app)
        XCTAssertTrue(app.staticTexts["Another ordinary message"].waitForExistence(timeout: 5))
    }

    @MainActor func testCountdownStartsWhenOpenedAndErasesBody() {
        let app = fresh()
        send("A short lived secret", duration: 5, app: app)
        let open = app.buttons["openDisappearingMessage"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        // Leaving an envelope unopened must not start its timer.
        let prematureExpiry = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: open)
        prematureExpiry.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [prematureExpiry], timeout: 6), .completed)
        XCTAssertTrue(open.exists)
        open.tap()
        let body = app.staticTexts["disappearingBody"]
        XCTAssertTrue(body.waitForExistence(timeout: 3))
        XCTAssertEqual(body.label, "A short lived secret")
        XCTAssertTrue(app.staticTexts["burnCountdown"].exists)
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: body)
        XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 8), .completed)
        XCTAssertTrue(app.staticTexts["disappearingExpired"].waitForExistence(timeout: 5))
        XCTAssertFalse(open.exists)
    }

    @MainActor func testExpiredContentStaysGoneAfterRelaunch() {
        let app = fresh()
        send("Erase even while away", duration: 5, app: app)
        app.buttons["openDisappearingMessage"].tap()
        XCTAssertTrue(app.staticTexts["disappearingBody"].waitForExistence(timeout: 3))
        app.terminate()
        Thread.sleep(forTimeInterval: 6)
        app.launchArguments = ["--uitesting"]
        app.launch(); app.buttons["tab_1"].tap()
        XCTAssertTrue(app.staticTexts["disappearingExpired"].waitForExistence(timeout: 6))
        XCTAssertFalse(app.staticTexts["Erase even while away"].exists)
        XCTAssertFalse(app.buttons["openDisappearingMessage"].exists)
    }
}
