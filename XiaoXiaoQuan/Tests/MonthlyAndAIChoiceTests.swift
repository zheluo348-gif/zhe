import XCTest

final class MonthlyAndAIChoiceTests:XCTestCase {
    @MainActor private func app(fixture:Bool=false)->XCUIApplication { let a=XCUIApplication();a.launchArguments=["--uitesting","--reset"]+(fixture ? ["--wallpaper-fixture-eighty-nine-days"]:[]);a.launch();XCTAssertTrue(a.buttons["enterCircle"].waitForExistence(timeout:12));a.buttons["enterCircle"].tap();XCTAssertTrue(a.buttons["sceneFeed"].waitForExistence(timeout:6));return a }
    @MainActor private func tap(_ element:XCUIElement,_ a:XCUIApplication) { for _ in 0..<16 { if element.exists && element.isHittable && element.frame.midY < a.frame.maxY-130 && element.frame.midY > 125 { element.tap();return };a.swipeUp(velocity:.slow) };XCTFail("Cannot reach \(element)") }
    @MainActor private func shot(_ a:XCUIApplication,_ title:String) { let x=XCTAttachment(screenshot:a.screenshot());x.name=title;x.lifetime = .keepAlways;add(x) }
    @MainActor private func settings(_ a:XCUIApplication) { a.buttons["tab_3"].tap();tap(a.buttons["aiSettings"],a);XCTAssertTrue(a.switches["aiEnabledToggle"].waitForExistence(timeout:5)) }
    @MainActor func testAIChoicePersistsAndManualPlayRemains() {
        let a=app();settings(a);XCTAssertEqual(a.switches["aiEnabledToggle"].value as? String,"0");shot(a,"80-基础玩法AI默认关闭")
        a.switches["aiEnabledToggle"].tap();XCTAssertEqual(a.switches["aiEnabledToggle"].value as? String,"1");shot(a,"81-用户选择开启AI灵感")
        a.terminate();a.launchArguments=["--uitesting"];a.launch();settings(a);XCTAssertEqual(a.switches["aiEnabledToggle"].value as? String,"1")
        a.switches["aiEnabledToggle"].tap();a.navigationBars.buttons.element(boundBy:0).tap();a.buttons["tab_1"].tap();a.buttons["openInspiration"].tap();a.buttons["inspireStickers"].tap()
        XCTAssertTrue(a.buttons["useReadyStickers"].waitForExistence(timeout:5));XCTAssertFalse(a.buttons["generateSticker"].exists);tap(a.buttons["useReadyStickers"],a)
        XCTAssertTrue(a.textFields["stickerCaption"].waitForExistence(timeout:5));shot(a,"82-关闭AI仍能制作贴纸")
        tap(a.buttons["sendSticker"],a);XCTAssertTrue(a.alerts["贴纸已保存到聊天"].waitForExistence(timeout:5));a.alerts.buttons["查看聊天"].tap();XCTAssertTrue(a.buttons["openDrawing"].waitForExistence(timeout:5))
    }
    @MainActor func testMonthlyWallpaperCatalogAndFutureLocked() {
        let a=app();a.buttons["openGrowth"].tap()
        for day in [30,60,90,120,150,180,210,240,270,300,330,360] {
            tap(a.buttons["stage_\(day)"],a);XCTAssertTrue(a.buttons["closeStagePreview"].waitForExistence(timeout:5));XCTAssertFalse(a.buttons["useWallpaper"].exists);shot(a,"壁纸-第\(day)天")
            a.buttons["closeStagePreview"].tap()
        }
        XCTAssertTrue(a.staticTexts["累计来访 1 天"].exists)
    }
    @MainActor func testUnlockedWallpaperCanBeReusedWithoutChangingProgress() {
        let a=app(fixture:true);XCTAssertTrue(a.staticTexts["小窝第90天 · 本机成长"].exists);a.buttons["openGrowth"].tap();tap(a.buttons["stage_30"],a)
        XCTAssertTrue(a.buttons["useWallpaper"].waitForExistence(timeout:5));a.buttons["useWallpaper"].tap();a.navigationBars.buttons.element(boundBy:0).tap();XCTAssertTrue(a.staticTexts["月光小窝"].waitForExistence(timeout:5));XCTAssertTrue(a.staticTexts["小窝第90天 · 本机成长"].exists);shot(a,"83-已解锁旧壁纸可换回")
        a.terminate();a.launchArguments=["--uitesting"];a.launch();XCTAssertTrue(a.staticTexts["月光小窝"].waitForExistence(timeout:6));a.buttons["openGrowth"].tap();tap(a.buttons["followNewestWallpaper"],a);a.navigationBars.buttons.element(boundBy:0).tap();XCTAssertTrue(a.staticTexts["星河同行"].waitForExistence(timeout:5));shot(a,"84-自动跟随最新壁纸")
    }
}
