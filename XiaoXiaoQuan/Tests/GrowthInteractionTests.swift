import XCTest

final class GrowthInteractionTests:XCTestCase {
    @MainActor private func fresh()->XCUIApplication { let app=XCUIApplication();app.launchArguments=["--uitesting","--reset"];app.launch();XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout:12));app.buttons["enterCircle"].tap();XCTAssertTrue(app.buttons["sceneFeed"].waitForExistence(timeout:6));return app }
    @MainActor private func tap(_ element:XCUIElement,_ app:XCUIApplication) { for _ in 0..<9 { if element.exists && element.isHittable { element.tap();return };app.swipeUp() };XCTFail("Cannot reach \(element)") }
    @MainActor private func shot(_ app:XCUIApplication,_ name:String) { let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a) }
    @MainActor private func reopen(_ app:XCUIApplication) { app.terminate();app.launchArguments=["--uitesting"];app.launch();XCTAssertTrue(app.buttons["sceneFeed"].waitForExistence(timeout:8)) }
    @MainActor func testMilestonePreviewsDoNotUnlockAndSceneWorks() {
        let app=fresh();shot(app,"50-成长小窝首页")
        app.buttons["sceneFeed"].tap();XCTAssertTrue(app.staticTexts["sceneFeedback"].waitForExistence(timeout:4));shot(app,"51-直接在小窝喂团团")
        tap(app.buttons["openGrowth"],app)
        for day in [1,2,3,7,10,30,60,90,180,360] {
            tap(app.buttons["stage_\(day)"],app)
            XCTAssertTrue(app.buttons["closeStagePreview"].waitForExistence(timeout:4));shot(app,String(format:"%02d-第%d天阶段",60+[1,2,3,7,10,30,60,90,180,360].firstIndex(of:day)!,day))
            app.buttons["closeStagePreview"].tap()
        }
        XCTAssertTrue(app.staticTexts["累计来访 1 天"].exists)
        reopen(app);XCTAssertTrue(app.staticTexts["小窝第1天 · 本机成长"].exists)
        tap(app.buttons["quick_2"],app);XCTAssertTrue(app.staticTexts["90%"].waitForExistence(timeout:4))
    }
    @MainActor func testChargedHugThreeLevelsAndReceiverPreview() {
        let app=fresh();app.buttons["tab_1"].tap()
        for (duration,title,number) in [(0.0,"软软地，抱住你",70),(1.0,"星星都向你靠近",71),(2.1,"整个宇宙，都在抱你",72)] {
            XCTAssertTrue(app.buttons["sendHug"].waitForExistence(timeout:5))
            if duration==0 { app.buttons["sendHug"].tap() } else { app.buttons["sendHug"].press(forDuration:duration) }
            let preview=app.buttons.matching(identifier:"previewHug").allElementsBoundByIndex.last!
            tap(preview,app)
            XCTAssertTrue(app.staticTexts["hugEffectTitle"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["hugEffectTitle"].label,title)
            shot(app,"\(number)-\(title)")
            app.buttons["receivePreviewHug"].tap();XCTAssertFalse(app.buttons["receivePreviewHug"].isEnabled)
            app.buttons["closeHugPreview"].tap()
        }
        shot(app,"73-聊天蓄力抱抱卡片")
        reopen(app);app.buttons["tab_1"].tap();XCTAssertTrue(app.staticTexts["抱抱接住啦 ♡"].firstMatch.waitForExistence(timeout:5))
    }
    @MainActor func testStoryInvitationReturnsToSameChatCard() {
        let app=fresh();app.buttons["tab_1"].tap();app.buttons["openInspiration"].tap();app.buttons["inspireGames"].tap()
        tap(app.buttons["invite_story"],app)
        XCTAssertTrue(app.buttons["playInvitation"].waitForExistence(timeout:5));shot(app,"74-聊天里的游戏邀请")
        app.buttons["playInvitation"].tap()
        let line=app.descendants(matching:.any).matching(identifier:"storyLine").firstMatch
        XCTAssertTrue(line.waitForExistence(timeout:5));line.tap();line.typeText("Our cat found a tiny star.")
        if app.buttons["完成"].exists { app.buttons["完成"].tap() }
        tap(app.buttons["addStoryLine"],app);XCTAssertTrue(app.buttons["finishInvitation"].isEnabled);app.buttons["finishInvitation"].tap()
        XCTAssertTrue(app.staticTexts["收好小回忆"].waitForExistence(timeout:5));shot(app,"75-游戏结果留在原卡片")
        reopen(app);app.buttons["tab_1"].tap();XCTAssertTrue(app.staticTexts["收好小回忆"].waitForExistence(timeout:5))
    }
    @MainActor func testTenthVisitUnlocksOnceAndKeepsMemory() {
        let app=XCUIApplication();app.launchArguments=["--uitesting","--reset","--growth-fixture-nine-days"];app.launch();XCTAssertTrue(app.buttons["enterCircle"].waitForExistence(timeout:12));app.buttons["enterCircle"].tap()
        XCTAssertTrue(app.buttons["claimStageGift"].waitForExistence(timeout:6));shot(app,"78-第十天升级惊喜")
        app.buttons["claimStageGift"].tap();XCTAssertTrue(app.staticTexts["小窝第10天 · 本机成长"].waitForExistence(timeout:5))
        reopen(app);XCTAssertFalse(app.buttons["claimStageGift"].exists);XCTAssertTrue(app.staticTexts["小窝第10天 · 本机成长"].exists)
        app.buttons["tab_2"].tap();XCTAssertTrue(app.staticTexts["第10天 · 星光搭子"].waitForExistence(timeout:5))
    }
    @MainActor func testChessInvitationSharedResultClosesSheet() {
        let app=fresh();app.buttons["tab_1"].tap();app.buttons["openInspiration"].tap();app.buttons["inspireGames"].tap();tap(app.buttons["invite_gomoku"],app)
        XCTAssertTrue(app.buttons["playInvitation"].waitForExistence(timeout:5));app.buttons["playInvitation"].tap()
        XCTAssertTrue(app.buttons["cell_0"].waitForExistence(timeout:5))
        for cell in [0,9,1,10,2,11,3,12,4] { app.buttons["cell_\(cell)"].tap() }
        tap(app.buttons["把这一局留在聊天"],app)
        XCTAssertTrue(app.staticTexts["收好小回忆"].waitForExistence(timeout:5));XCTAssertFalse(app.buttons["closeInvitationGame"].exists);shot(app,"77-棋局结果回到聊天")
    }
    @MainActor func testProfilePersonalizationAndMemoryOnWall() {
        let app=fresh();app.buttons["tab_3"].tap();app.buttons["editProfile"].tap()
        let name=app.textFields["profileNickname"];XCTAssertTrue(name.waitForExistence(timeout:5));name.tap();if let old=name.value as? String { name.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:old.count)) };name.typeText("Candy")
        app.textFields["profileSpaceName"].tap();app.textFields["profileSpaceName"].typeText("Candy Home")
        let pet=app.textFields["profilePetName"];pet.tap();if let old=pet.value as? String { pet.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:old.count)) };pet.typeText("Mochi")
        app.swipeUp();tap(app.buttons["favorite_capsules"],app);app.buttons["saveProfile"].tap()
        XCTAssertTrue(app.staticTexts["Candy"].waitForExistence(timeout:5));app.buttons["tab_0"].tap();XCTAssertTrue(app.staticTexts["Candy Home"].waitForExistence(timeout:5))
        tap(app.buttons["quick_0"],app);XCTAssertTrue(app.buttons["addCapsule"].waitForExistence(timeout:5));app.navigationBars.buttons.element(boundBy:0).tap()
        app.buttons["tab_2"].tap();tap(app.buttons.containing(.staticText,identifier:"终于一起看了海").firstMatch,app)
        tap(app.buttons["pinMemory"],app);XCTAssertTrue(app.buttons.containing(.staticText,identifier:"已挂在小窝墙上").firstMatch.exists)
        app.buttons["完成"].tap();app.buttons["tab_0"].tap();XCTAssertTrue(app.staticTexts["终于一起看了海"].waitForExistence(timeout:5));shot(app,"76-我的小窝与照片墙")
        reopen(app);XCTAssertTrue(app.staticTexts["Candy Home"].exists);app.buttons["sceneFeed"].tap();XCTAssertTrue(app.staticTexts["sceneFeedback"].label.contains("Mochi"))
    }
}
