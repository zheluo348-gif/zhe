import XCTest

final class PreviewJourneyTests: XCTestCase {
    @MainActor private func freshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset"]; app.launch()
        XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout: 12))
        app.buttons["enterCircle"].tap()
        XCTAssertTrue(app.buttons["tab_0"].waitForExistence(timeout: 6))
        return app
    }
    @MainActor private func spaces(_ app: XCUIApplication) {
        if app.buttons["返回首页"].exists { app.buttons["返回首页"].tap() }
        app.buttons["tab_3"].tap(); app.buttons["mySpaces"].tap()
        XCTAssertTrue(app.buttons["space_couple"].waitForExistence(timeout: 5))
    }
    @MainActor func testSpaceIsolationAndRelaunch() throws {
        let app = freshApp()
        XCTAssertFalse(app.buttons["space_friends"].exists)
        XCTAssertFalse(app.buttons["space_couple"].exists)
        attach(app, "01-首页与插画")
        app.buttons["tab_1"].tap()
        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("Couple saved message")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.staticTexts["Couple saved message"].waitForExistence(timeout: 5))
        input.tap(); input.typeText("Couple draft")
        spaces(app)
        XCTAssertFalse(app.buttons["space_friends"].exists)
        attach(app, "02-我的空间")
        app.buttons["createSpace"].tap()
        XCTAssertTrue(app.buttons["joinFriendsDemo"].waitForExistence(timeout: 5))
        app.buttons["joinFriendsDemo"].tap()
        app.buttons["tab_1"].tap()
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Couple saved message"].exists)
        input.tap(); input.typeText("Friends draft")
        spaces(app); app.buttons["space_couple"].tap()
        app.buttons["tab_1"].tap()
        XCTAssertEqual(input.value as? String, "Couple draft")
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["tab_1"].tap()
        XCTAssertEqual(input.value as? String, "Couple draft")
        XCTAssertTrue(app.staticTexts["Couple saved message"].exists)
        spaces(app); app.buttons["space_friends"].tap()
        app.buttons["tab_1"].tap()
        XCTAssertEqual(input.value as? String, "Friends draft")
        XCTAssertFalse(app.staticTexts["Couple saved message"].exists)
        attach(app, "03-闺蜜聊天-空间隔离")
    }
    @MainActor func testHugStickerFailureFallbackAndPersistence() throws {
        let app = freshApp()
        app.buttons["tab_3"].tap()
        for _ in 0..<5 { if app.buttons["aiSettings"].isHittable { break };app.swipeUp() }
        app.buttons["aiSettings"].tap()
        XCTAssertTrue(app.switches["aiEnabledToggle"].waitForExistence(timeout:5));app.switches["aiEnabledToggle"].tap()
        app.navigationBars.buttons.element(boundBy:0).tap()

        app.buttons["tab_1"].tap()
        XCTAssertTrue(app.buttons["acceptHug"].waitForExistence(timeout: 5))
        app.buttons["acceptHug"].tap()
        if app.buttons["closeHugPreview"].waitForExistence(timeout: 5) { app.buttons["closeHugPreview"].tap() }
        XCTAssertTrue(app.staticTexts["抱抱接住啦 ♡"].exists)
        attach(app, "04-趣味聊天")
        app.buttons["openInspiration"].tap()
        XCTAssertTrue(app.buttons["inspireStickers"].waitForExistence(timeout: 5))
        attach(app, "05-灵感入口")
        app.buttons["inspireStickers"].tap()
        let prompt = app.descendants(matching: .any).matching(identifier: "stickerPrompt").firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        prompt.tap(); prompt.typeText("A shy hug")
        app.swipeUp()
        app.buttons["generateSticker"].tap()
        XCTAssertTrue(app.alerts["确认本次内容"].waitForExistence(timeout: 5))
        app.alerts.buttons["尝试生成"].tap()
        XCTAssertTrue(app.staticTexts["aiFailureReason"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A shy hug"].exists)
        attach(app, "06-AI未接入-草稿保留")
        app.buttons["fallbackStickers"].tap()
        let caption = app.textFields["stickerCaption"]
        XCTAssertTrue(caption.waitForExistence(timeout: 5))
        caption.tap()
        if let current = caption.value as? String { caption.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)) }
        caption.typeText("Made with love")
        if app.buttons["完成"].exists { app.buttons["完成"].tap() }
        app.swipeUp()
        app.buttons["collectSticker"].tap()
        XCTAssertTrue(app.staticTexts["已收藏"].exists)
        attach(app, "07-贴纸编辑与收藏")
        app.buttons["sendSticker"].tap()
        XCTAssertTrue(app.alerts["贴纸已保存到聊天"].waitForExistence(timeout: 5))
        app.alerts.buttons["查看聊天"].tap()
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["tab_1"].tap()
        XCTAssertTrue(app.images["messagePhoto"].waitForExistence(timeout: 5))
        app.buttons["openInspiration"].tap(); app.buttons["inspireStickers"].tap()
        XCTAssertTrue(app.staticTexts["我的收藏 · 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Made with love"].exists)
    }
    @MainActor func testQuizHandoverAndRoomCare() throws {
        let app = freshApp()
        app.swipeUp()
        app.buttons["homeInspiration"].tap()
        XCTAssertTrue(app.buttons["inspireGames"].waitForExistence(timeout: 5))
        app.buttons["inspireGames"].tap()
        XCTAssertTrue(app.buttons["startQuiz"].waitForExistence(timeout: 5))
        app.buttons["startQuiz"].tap()
        app.buttons["quizChoice_0"].tap(); app.buttons["submitQuiz"].tap()
        XCTAssertTrue(app.buttons["nextQuizPlayer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["这题想到一起啦！"].exists)
        attach(app, "08-默契问答-交给下一位")
        app.buttons["nextQuizPlayer"].tap()
        app.buttons["quizChoice_0"].tap(); app.buttons["submitQuiz"].tap()
        XCTAssertTrue(app.staticTexts["这题想到一起啦！"].waitForExistence(timeout: 5))
        attach(app, "09-默契问答-全员揭晓")
        app.swipeUp(); app.buttons["shareQuiz"].tap()
        XCTAssertTrue(app.staticTexts["已保存到聊天"].exists)
        app.terminate(); app.launchArguments = ["--uitesting"]; app.launch()
        app.swipeUp(); app.buttons["homeRoom"].tap()
        XCTAssertTrue(app.buttons["roomFeed"].waitForExistence(timeout: 5))
        app.buttons["roomFeed"].tap()
        XCTAssertTrue(app.staticTexts["90%"].waitForExistence(timeout: 5))
        attach(app, "10-小房间-照料")
        app.buttons["findTuantuan"].tap(); app.buttons["tuantuanActivity_0"].tap()
        app.swipeUp(); app.buttons["sendWeekendPlan"].tap()
        XCTAssertTrue(app.alerts["灵感卡已保存到聊天"].waitForExistence(timeout: 5))
        app.alerts.buttons["查看聊天"].tap()
        XCTAssertTrue(app.staticTexts["周末小灵感"].waitForExistence(timeout: 5))
    }
    @MainActor func testDrawingImageAndVoiceEntry() throws {
        let app = freshApp()
        app.buttons["tab_1"].tap(); app.buttons["openDrawing"].tap()
        let canvas = app.descendants(matching: .any).matching(identifier: "drawingCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.35)).press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.55)))
        attach(app, "11-手绘画布")
        app.buttons["sendDrawing"].tap()
        XCTAssertTrue(app.images["messagePhoto"].waitForExistence(timeout: 5))
        app.buttons["openVoice"].tap()
        XCTAssertTrue(app.buttons["开始录音"].waitForExistence(timeout: 5))
        attach(app, "12-原声语音便签")
    }
    @MainActor func testExpressionReturnsUnsentDraft() throws {
        let app = freshApp()
        app.buttons["tab_1"].tap(); app.buttons["openInspiration"].tap()
        XCTAssertTrue(app.buttons["inspireExpression"].waitForExistence(timeout: 5))
        app.buttons["inspireExpression"].tap()
        let original = app.descendants(matching: .any).matching(identifier: "expressionOriginal").firstMatch
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        original.tap(); original.typeText("Need time together")
        if app.buttons["完成"].exists { app.buttons["完成"].tap() }
        app.buttons["试用本机表达模板"].tap()
        app.swipeUp()
        app.buttons["returnExpressionDraft"].tap()
        let draft = app.textFields["messageInput"]
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        XCTAssertTrue((draft.value as? String)?.contains("Need time together") == true)
        XCTAssertFalse(app.staticTexts["有件小事想和你聊聊：Need time together\n也想听听你的想法。"].exists)
        attach(app, "13-表达回填-等待本人发送")
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
