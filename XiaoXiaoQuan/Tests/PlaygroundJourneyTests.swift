import XCTest

final class PlaygroundJourneyTests: XCTestCase {
    @MainActor private func fresh() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--reset"]; app.launch()
        XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout: 12)); app.buttons["enterCircle"].tap()
        showShortcuts(app); return app
    }
    @MainActor private func showShortcuts(_ app: XCUIApplication) {
        for _ in 0..<7 {
            if app.buttons["quick_0"].exists && app.buttons["quick_0"].isHittable { return }
            app.swipeUp()
        }
        XCTFail("Cannot reach home shortcuts")
    }
    @MainActor private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<7 { if element.exists && element.isHittable { element.tap(); return }; app.swipeUp() }
        XCTFail("Cannot reach \(element)")
    }
    @MainActor private func module(_ name: String, _ app: XCUIApplication) {
        tap(app.buttons["quick_5"], in: app)
        tap(app.buttons["module_" + name], in: app)
    }
    @MainActor private func back(_ app: XCUIApplication) { app.navigationBars.buttons.element(boundBy: 0).tap() }
    @MainActor private func reopen(_ app: XCUIApplication) { app.terminate(); app.launchArguments = ["--uitesting"]; app.launch(); XCTAssertTrue(app.buttons["sceneFeed"].waitForExistence(timeout: 8)); showShortcuts(app) }
    @MainActor private func shot(_ app: XCUIApplication, _ name: String) { let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
    @MainActor func testHabitRewardOnceAndRelaunch() {
        let app = fresh(); shot(app, "20-插画首页")
        app.buttons["quick_0"].tap()
        let breakfast = app.buttons["habit_认真吃早餐"]
        XCTAssertTrue(breakfast.waitForExistence(timeout: 5)); breakfast.tap()
        XCTAssertFalse(breakfast.isEnabled); shot(app, "21-今日打卡")
        reopen(app); app.buttons["quick_0"].tap(); XCTAssertFalse(breakfast.isEnabled)
        back(app); module("rewards", app)
        XCTAssertTrue(app.staticTexts["14 朵"].waitForExistence(timeout: 5))
        shot(app, "22-小红花奖励铺")
        app.buttons["reward_0"].tap(); app.alerts.buttons["确认兑换"].tap()
        if app.alerts["小票夹"].waitForExistence(timeout: 2) { app.alerts.buttons["知道了"].tap() }
        XCTAssertTrue(app.staticTexts["8 朵"].waitForExistence(timeout: 5))
        tap(app.buttons["useReward"], in: app); XCTAssertTrue(app.staticTexts["已标记使用"].exists)
        reopen(app); module("rewards", app); XCTAssertTrue(app.staticTexts["8 朵"].waitForExistence(timeout: 5)); tap(app.buttons["useReward"], in: app); XCTAssertFalse(app.buttons["useReward"].isEnabled)
    }
    @MainActor func testAgreementLifecycle() {
        let app = fresh(); app.buttons["quick_1"].tap(); tap(app.buttons["addAgreement"], in: app)
        app.textFields["agreementTitle"].tap(); app.textFields["agreementTitle"].typeText("Walk together")
        app.buttons["saveAgreement"].tap()
        tap(app.buttons.containing(.staticText, identifier: "Walk together").firstMatch, in: app)
        app.buttons["acceptAgreement"].tap(); XCTAssertTrue(app.buttons["completeAgreement"].waitForExistence(timeout: 5)); app.buttons["completeAgreement"].tap()
        XCTAssertTrue(app.staticTexts["完成记录已保存，收好 4 朵小红花"].waitForExistence(timeout: 5)); shot(app, "23-完成小约定")
        reopen(app); module("rewards", app); XCTAssertTrue(app.staticTexts["16 朵"].waitForExistence(timeout: 5))
    }
    @MainActor func testCapsuleSealedAndPersistent() {
        let app = fresh(); app.buttons["quick_4"].tap(); app.buttons["addCapsule"].tap()
        app.textFields["capsuleTitle"].tap(); app.textFields["capsuleTitle"].typeText("Future letter")
        let body = app.descendants(matching: .any).matching(identifier: "capsuleBody").firstMatch
        body.tap(); body.typeText("Our private future words")
        app.buttons["sealCapsule"].tap()
        XCTAssertTrue(app.buttons["capsule_Future letter"].waitForExistence(timeout: 5)); app.buttons["capsule_Future letter"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "sealedLetter").firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Our private future words"].exists); XCTAssertFalse(app.buttons["openCapsule"].exists); shot(app, "24-未到期胶囊")
        reopen(app); app.buttons["quick_4"].tap(); app.buttons["capsule_Future letter"].tap(); XCTAssertFalse(app.buttons["openCapsule"].exists)
    }
    @MainActor func testGomokuWinUndoPersistence() {
        let app = fresh(); app.buttons["quick_3"].tap(); tap(app.buttons["game_gomoku"], in: app)
        XCTAssertTrue(app.buttons["cell_0"].waitForExistence(timeout: 5))
        for cell in [0, 9, 1, 10, 2, 11, 3, 12, 4] { app.buttons["cell_\(cell)"].tap() }
        XCTAssertEqual(app.staticTexts["gomokuStatus"].label, "黑棋赢啦！"); shot(app, "25-五子棋胜局")
        app.buttons["undoGomoku"].tap(); XCTAssertEqual(app.buttons["cell_4"].value as? String, "空位")
        reopen(app); app.buttons["quick_3"].tap(); tap(app.buttons["game_gomoku"], in: app)
        XCTAssertEqual(app.buttons["cell_0"].value as? String, "黑棋"); XCTAssertEqual(app.buttons["cell_4"].value as? String, "空位")
    }
    @MainActor func testPetOutfitAndDailyGift() {
        let app = fresh(); app.buttons["quick_2"].tap(); tap(app.buttons["petAction_0"], in: app)
        XCTAssertTrue(app.staticTexts["90%"].exists); shot(app, "26-团团照料")
        tap(app.buttons["petWardrobe"], in: app); tap(app.buttons["outfit_1"], in: app)
        XCTAssertEqual(app.staticTexts["selectedOutfit"].label, "小绿蝴蝶结"); shot(app, "27-团团小衣橱")
        reopen(app); app.buttons["quick_2"].tap(); tap(app.buttons["petWardrobe"], in: app); XCTAssertEqual(app.staticTexts["selectedOutfit"].label, "小绿蝴蝶结")
        back(app); tap(app.buttons["petSurprise"], in: app); app.buttons["openDailySticker"].tap()
        XCTAssertTrue(app.buttons["sendDailySticker"].waitForExistence(timeout: 5)); shot(app, "28-每日小惊喜")
        reopen(app); app.buttons["quick_2"].tap(); tap(app.buttons["petSurprise"], in: app)
        XCTAssertFalse(app.buttons["openDailySticker"].exists); XCTAssertTrue(app.buttons["sendDailySticker"].exists)
    }
    @MainActor func testCalendarExpenseAndExactSplit() {
        let app = fresh(); module("calendar", app); tap(app.buttons["addEvent"], in: app)
        app.textFields["eventTitle"].tap(); app.textFields["eventTitle"].typeText("Weekend picnic"); app.buttons["saveEvent"].tap()
        tap(app.staticTexts["Weekend picnic"], in: app); shot(app, "29-日历与小约会")
        reopen(app); module("expenses", app); app.buttons["addExpense"].tap()
        app.textFields["expenseTitle"].tap(); app.textFields["expenseTitle"].typeText("Picnic snacks")
        app.textFields["expenseAmount"].tap(); app.textFields["expenseAmount"].typeText("10.01"); app.buttons["saveExpense"].tap()
        XCTAssertTrue(app.staticTexts["¥5.01"].waitForExistence(timeout: 5)); XCTAssertTrue(app.staticTexts["¥5.00"].exists)
        app.buttons["paid_小糖"].tap(); shot(app, "30-聚会小账本")
        reopen(app); module("calendar", app); tap(app.staticTexts["Weekend picnic"], in: app)
    }
    @MainActor func testStoryDrawGuessAndWheel() {
        let app = fresh(); app.buttons["quick_3"].tap(); tap(app.buttons["game_story"], in: app)
        let line = app.descendants(matching: .any).matching(identifier: "storyLine").firstMatch
        line.tap(); line.typeText("A tiny moon came to visit."); if app.buttons["完成"].exists { app.buttons["完成"].tap() }; tap(app.buttons["addStoryLine"], in: app)
        XCTAssertTrue(app.staticTexts["A tiny moon came to visit."].exists); shot(app, "31-故事接龙")
        reopen(app); app.buttons["quick_3"].tap(); tap(app.buttons["game_story"], in: app); XCTAssertTrue(app.staticTexts["A tiny moon came to visit."].exists)
        back(app); tap(app.buttons["game_drawGuess"], in: app); app.buttons["startDrawGuess"].tap()
        let canvas = app.descendants(matching: .any).matching(identifier: "guessCanvas").firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5)); canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)).press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.6)))
        app.buttons["handoverDrawing"].tap(); app.textFields["drawingGuess"].tap(); app.textFields["drawingGuess"].typeText("cat"); if app.buttons["完成"].exists { app.buttons["完成"].tap() }; tap(app.buttons["revealDrawing"], in: app)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "题目是：小猫")).firstMatch.waitForExistence(timeout: 5)); shot(app, "32-你画我猜揭晓")
        reopen(app); module("wheel", app); app.buttons["spinWheel"].tap(); XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "wheelResult").firstMatch.waitForExistence(timeout: 5)); shot(app, "33-决定小转盘")
    }
    @MainActor func testNewDataIsolationBetweenSpaces() {
        let app = fresh(); app.buttons["quick_0"].tap(); app.buttons["habit_认真吃早餐"].tap(); back(app)
        app.buttons["tab_3"].tap(); app.buttons["mySpaces"].tap(); app.buttons["createSpace"].tap(); app.buttons["joinFriendsDemo"].tap()
        XCTAssertTrue(app.buttons["sceneFeed"].waitForExistence(timeout: 5)); showShortcuts(app); shot(app, "34-闺蜜小窝首页")
        app.buttons["quick_0"].tap(); XCTAssertTrue(app.buttons["habit_认真吃早餐"].isEnabled)
        back(app); module("rewards", app); XCTAssertTrue(app.staticTexts["12 朵"].waitForExistence(timeout: 5))
    }
    @MainActor func testPaperNotesAndCustomKeyword() {
        let app = fresh(); module("keywords", app)
        let word = app.textFields["keywordWord"]
        tap(word, in: app); word.typeText("spark")
        if app.buttons["完成"].exists { app.buttons["完成"].tap() }
        tap(app.buttons["saveKeyword"], in: app)
        XCTAssertTrue(app.staticTexts["“spark”"].waitForExistence(timeout: 5))
        reopen(app); app.buttons["tab_1"].tap()
        let input = app.textFields["messageInput"]
        input.tap(); input.typeText("spark, a little note for you")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.staticTexts["给你的小纸条"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["spark, a little note for you"].exists)
        shot(app, "43-聊天小纸条与团团")
        app.buttons["messageStyle"].tap()
        input.tap(); input.typeText("A quiet message")
        app.buttons["sendMessage"].tap()
        XCTAssertTrue(app.staticTexts["A quiet message"].exists)
        reopen(app); app.buttons["tab_1"].tap()
        XCTAssertTrue(app.staticTexts["spark, a little note for you"].exists)
        XCTAssertTrue(app.staticTexts["A quiet message"].exists)
    }
    @MainActor func testModuleCatalogAndSecondaryPages() {
        let app = fresh(); app.buttons["quick_5"].tap(); shot(app, "35-游乐场图标入口"); app.swipeUp(); shot(app, "36-游乐场更多玩法")
        for (name, title) in [("keywords", "37-暗号特效"), ("annual", "38-年度回忆"), ("achievements", "39-成就册"), ("music", "40-本机一起听"), ("truth", "41-真心话")] {
            reopen(app)
            if name == "truth" { app.buttons["quick_3"].tap(); tap(app.buttons["game_truth"], in: app) } else { module(name, app) }
            shot(app, title)
        }
        reopen(app); app.buttons["tab_3"].tap(); tap(app.buttons["privacySettings"], in: app); shot(app, "42-隐私与空间退出")
        app.buttons["prepareExport"].tap(); XCTAssertTrue(app.buttons["选择备份保存位置"].waitForExistence(timeout: 5))
    }
}
