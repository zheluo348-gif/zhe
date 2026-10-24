from pathlib import Path
import re
from swift_rules import run_checks
root=Path(__file__).resolve().parents[2]
models=(root/'XiaoXiaoQuan/Sources/Models.swift').read_text()
types=models.split('@MainActor final class CircleStore')[0].replace('import SwiftUI','import Foundation').replace('    var creative: CreativeSpace?\n','')
play=(root/'XiaoXiaoQuan/Sources/PlaygroundModels.swift').read_text().replace('import SwiftUI','')
growth=(root/'XiaoXiaoQuan/Sources/GrowthModels.swift').read_text().split('@MainActor extension CircleStore')[0].replace('import SwiftUI','')
growth=re.sub(r'    var (sky|floor|accent|onPaperAccent): Color \{[^\n]+\}\n','',growth)

stub='''
@MainActor final class CircleStore {
 var state = SavedState()
 var collected = 0
 var myName:String { state.profile?.nickname ?? "小糖" }
 var friends: Bool { state.mode == "friends" }
 var current: SpaceData { friends ? state.friends : state.couple }
 init() { state.couple.playground = PlaygroundData(); state.friends.playground = PlaygroundData() }
 func update(_ change: (inout SpaceData) -> Void) { if friends { change(&state.friends) } else { change(&state.couple) } }
 func persist() {}
 func collectSticker(pose: Int, caption: String) { collected += 1 }
}
'''
tests='''
@main struct Checks {
 @MainActor static func main() throws {
 var count = 0
 func check(_ value: @autoclosure () -> Bool, _ label: String) { precondition(value(), label); count += 1 }
 let s = CircleStore(); let habit = s.play.habits[1].id
 s.checkHabit(habit); s.checkHabit(habit)
 check(s.play.flowers == 14, "habit awards once"); check(s.play.habits[1].counts[CircleStore.dayKey()] == 1, "habit capped")
 s.addAgreement("Walk", note: "", flowers: 4, due: Date()); let id = s.play.agreements[0].id
 s.setAgreement(id, state: "已完成"); check(s.play.agreements[0].state == "待接受", "cannot bypass acceptance")
 s.setAgreement(id, state: "已接受"); s.setAgreement(id, state: "已完成"); s.setAgreement(id, state: "已完成")
 check(s.play.flowers == 18, "completion awards once")
 check(s.redeemReward("Tea", cost: 6), "can redeem"); check(!s.redeemReward("Too much", cost: 99), "insufficient blocked"); check(s.play.flowers == 12, "no negative balance")
 s.addCapsule(title: "Future", body: "Secret", opensAt: Date().addingTimeInterval(60), photo: nil); let letter = s.play.capsules[0].id
 s.openCapsule(letter); check(!s.play.capsules[0].opened, "early opening blocked")
 s.updatePlay { $0.capsules[0].opensAt = Date().addingTimeInterval(-1) }; s.openCapsule(letter); check(s.play.capsules[0].opened, "due opening works")
 s.addCapsule(title: "Past", body: "No", opensAt: Date().addingTimeInterval(-10), photo: nil); check(s.play.capsules.count == 1, "past seal rejected")
 _ = s.takeDailySticker(); _ = s.takeDailySticker(); check(s.collected == 1, "daily sticker once")
 s.state.mode = "friends"; check(s.play.flowers == 12 && s.play.capsules.isEmpty, "space isolation")
 s.state.mode = "couple"
 for sequence in [[0,9,1,10,2,11,3,12,4], [0,1,9,2,18,3,27,4,36], [0,1,10,2,20,3,30,5,40], [4,0,12,1,20,2,28,3,36]] {
   var g = GomokuGame(); g.place(-1); g.place(81); check(g.moves.isEmpty, "invalid cell ignored")
   for cell in sequence { g.place(cell) }; check(g.winner == 1, "five in a line")
   let last = sequence.last!; g.place(80); check(g.moves.count == 9, "no play after win")
   g.undo(); check(g.winner == 0 && g.board[last] == 0 && g.turn == 1, "undo restores turn")
 }
 s.state.joinedSpaces = ["couple", "friends"]; s.state.entered = true
 s.localExitSpace(); check(s.state.mode == "friends" && s.state.couple.playground?.capsules.count == 1, "exit preserves records")
 s.localExitSpace(); check(!s.state.entered && s.state.joinedSpaces?.isEmpty == true, "last exit returns welcome")
 s.state.mode = "couple"
 let data = try JSONEncoder().encode(s.play); let saved = try JSONDecoder().decode(PlaygroundData.self, from: data)
 check(saved.capsules[0].opened && saved.flowers == 12 && saved.habits[1].counts[CircleStore.dayKey()] == 1, "codable round trip")
 print("{\\"assertions\\":\\(count),\\"failures\\":0,\\"scope\\":\\"Production playground rules with in-memory storage adapter\\"}")
 }
}
'''
(root/'tmp').mkdir(parents=True, exist_ok=True)
path=root/'tmp/PlaygroundLogicChecks.swift'
path.write_text(growth+types+stub+play+tests)
run_checks(path)
