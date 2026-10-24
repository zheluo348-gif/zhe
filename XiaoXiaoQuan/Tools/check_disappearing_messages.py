"""Exercise production message expiry, persistence and export rules."""

from pathlib import Path
import re

from swift_rules import run_checks

root = Path(__file__).resolve().parents[2]
src = root / "XiaoXiaoQuan/Sources"
model_source = (src / "Models.swift").read_text()
models = model_source.split("@MainActor final class CircleStore")[0].replace(
    "import SwiftUI", "import Foundation"
)
creative = (src / "CreativeModels.swift").read_text().split("struct AIReply")[0]
creative = creative.replace("import SwiftUI", "").replace("import UIKit", "")
play = (src / "PlaygroundModels.swift").read_text().split("@MainActor extension CircleStore")[0].replace("import SwiftUI", "")
growth = (src / "GrowthModels.swift").read_text().split("@MainActor extension CircleStore")[0].replace("import SwiftUI", "")
growth = re.sub(r"    var (sky|floor|accent|onPaperAccent): Color \{[^\n]+\}\n", "", growth)


def function(name):
    signature = "    func " + name
    if signature not in model_source:
        signature = "    private func " + name
    start = model_source.index(signature)
    end = model_source.index("{", start) + 1
    depth = 1
    while depth:
        if model_source[end] == "{":
            depth += 1
        elif model_source[end] == "}":
            depth -= 1
        end += 1
    return model_source[start:end]


adapter = """
@MainActor final class CircleStore {
    var state = SavedState()
    var myName: String { "Tester" }
    var current: SpaceData { state.mode == "friends" ? state.friends : state.couple }
    var savedData: Data?
    private var messageExpirationTask: Task<Void, Never>?
    deinit { messageExpirationTask?.cancel() }
    func persist() { savedData = try! JSONEncoder().encode(state) }
    func update(_ change: (inout SpaceData) -> Void) {
        if state.mode == "friends" { change(&state.friends) } else { change(&state.couple) }
        persist()
    }
""" + "\n".join(function(name) for name in [
    "send(", "sendDisappearingMessage(", "revealDisappearingMessage(",
    "expireDisappearingMessages(", "scheduleMessageExpiration(",
]) + "\n}\n"

tests = r'''
@main struct Checks {
    @MainActor static func main() async throws {
        var count = 0
        func check(_ value: @autoclosure () -> Bool, _ label: String) {
            precondition(value(), label); count += 1
        }
        let base = Date().addingTimeInterval(3600)
        for duration in MessageBurnDuration.allCases {
            let s = CircleStore(), secret = "temporary-payload-\(duration.rawValue)"
            s.state.couple.draft = secret
            s.sendDisappearingMessage("  " + secret + "  ", duration: duration)
            let id = s.current.messages[0].id
            check(s.current.messages.count == 1, "one message sent")
            check(s.current.messages[0].text == "阅后即焚消息", "chat previews contain no payload")
            check(s.current.messages[0].disappearing?.body == secret, "trimmed body retained while unread")
            check(s.current.messages[0].disappearing?.expiresAt == nil, "sending does not start timer")
            check(s.current.draft == nil, "sent payload not retained as a draft")
            let unread = try JSONDecoder().decode(SavedState.self, from: s.savedData!)
            check(unread.couple.messages[0].disappearing?.body == secret, "unread message survives relaunch")
            check(unread.couple.messages[0].disappearing?.expiresAt == nil, "relaunch does not start unread timer")
            s.expireDisappearingMessages(at: base.addingTimeInterval(10000))
            check(s.current.messages[0].disappearing?.body == secret, "unopened content does not expire")
            let export = try JSONEncoder().encode(s.current.exportableCopy)
            check(!String(decoding: export, as: UTF8.self).contains(secret), "exports omit unread payloads")
            check(s.current.exportableCopy.messages.isEmpty, "exports omit disappearing cards")
            check(!s.revealDisappearingMessage(id, space: "friends", at: base), "wrong space cannot open message")
            check(!s.revealDisappearingMessage(id, space: "invalid", at: base), "invalid space rejected")
            check(s.revealDisappearingMessage(id, space: "couple", at: base), "first reveal allowed")
            let deadline = base.addingTimeInterval(Double(duration.rawValue))
            check(s.current.messages[0].disappearing?.expiresAt == deadline, "selected duration applied on reveal")
            let restored = CircleStore()
            restored.state = try JSONDecoder().decode(SavedState.self, from: s.savedData!)
            check(restored.state.couple.messages[0].disappearing?.expiresAt == deadline, "deadline persisted")
            check(restored.revealDisappearingMessage(id, space: "couple", at: base.addingTimeInterval(1)), "can return while time remains")
            check(restored.current.messages[0].disappearing?.expiresAt == deadline, "reopening cannot extend timer")
            restored.expireDisappearingMessages(at: deadline.addingTimeInterval(-0.1))
            check(restored.current.messages[0].disappearing?.body == secret, "not erased before deadline")
            check(restored.current.messages[0].disappearing?.readableBody(at: deadline) == nil, "UI cannot read expired payload before cleanup")
            restored.expireDisappearingMessages(at: deadline)
            check(restored.current.messages[0].disappearing?.body == nil, "erased at exact deadline")
            check(!restored.revealDisappearingMessage(id, space: "couple", at: deadline), "expired message cannot reopen")
            check(!String(decoding: restored.savedData!, as: UTF8.self).contains(secret), "persisted state contains no expired payload")
            let expired = try JSONDecoder().decode(SavedState.self, from: restored.savedData!)
            check(expired.couple.messages[0].disappearing?.body == nil, "erasure survives relaunch")
            s.expireDisappearingMessages(at: deadline.addingTimeInterval(300))
            check(s.current.messages[0].disappearing?.body == nil, "late foreground cleanup uses original deadline")
        }

        let spaces = CircleStore()
        spaces.send("ordinary history")
        let ordinary = spaces.current.messages[0]
        spaces.sendDisappearingMessage("couple-secret", duration: .five)
        let coupleID = spaces.current.messages[1].id
        spaces.state.mode = "friends"
        spaces.sendDisappearingMessage("friends-secret", duration: .thirty)
        let friendsID = spaces.current.messages[0].id
        spaces.sendDisappearingMessage("unopened-secret", duration: .five)
        check(spaces.revealDisappearingMessage(coupleID, space: "couple", at: base), "explicit target works independently of current space")
        check(spaces.state.friends.messages[0].disappearing?.expiresAt == nil, "other space timer untouched")
        check(spaces.revealDisappearingMessage(friendsID, space: "friends", at: base), "second space timer starts independently")
        spaces.expireDisappearingMessages(at: base.addingTimeInterval(5))
        check(spaces.state.couple.messages[1].disappearing?.body == nil, "inactive space expires")
        check(spaces.state.friends.messages[0].disappearing?.body == "friends-secret", "later deadline preserved")
        check(spaces.state.couple.messages[0] == ordinary, "ordinary history unchanged")
        spaces.expireDisappearingMessages(at: base.addingTimeInterval(30))
        check(spaces.state.friends.messages[0].disappearing?.body == nil, "second space expires at own deadline")
        check(spaces.state.friends.messages[1].disappearing?.body == "unopened-secret", "unopened messages preserved")
        check(spaces.state.couple.exportableCopy.messages == [ordinary], "ordinary export unchanged")
        check(!spaces.revealDisappearingMessage(ordinary.id, space: "couple"), "ordinary message cannot be burned")
        check(!spaces.revealDisappearingMessage(UUID(), space: "couple"), "missing message rejected")

        let validation = CircleStore()
        validation.sendDisappearingMessage(" \n ", duration: .ten)
        check(validation.current.messages.isEmpty, "empty messages rejected")
        validation.sendDisappearingMessage(String(repeating: "猫", count: 2001), duration: .ten)
        check(validation.current.messages[0].disappearing?.body?.count == 2000, "message length capped by characters")
        let oldData = try JSONEncoder().encode(ordinary)
        let legacy = try JSONDecoder().decode(ChatMessage.self, from: oldData)
        check(legacy == ordinary && legacy.disappearing == nil, "legacy message without new field decodes")

        let live = CircleStore()
        live.sendDisappearingMessage("live-secret", duration: .five)
        check(live.revealDisappearingMessage(live.current.messages[0].id, space: "couple", at: Date().addingTimeInterval(-4.75)), "live scheduler starts")
        try await Task.sleep(for: .seconds(1))
        check(live.current.messages[0].disappearing?.body == nil, "background task clears content without view polling")
        check(!String(decoding: live.savedData!, as: UTF8.self).contains("live-secret"), "scheduled erasure persisted")
        print(String(data: try JSONSerialization.data(withJSONObject: ["checks": count, "failures": 0,
            "scope": "Production disappearing-message rules with in-memory persistence adapter"]), encoding: .utf8)!)
    }
}
'''

(root / "tmp").mkdir(exist_ok=True)
path = root / "tmp/DisappearingMessageChecks.swift"
path.write_text(models + creative + play + growth + adapter + tests)
run_checks(path)
