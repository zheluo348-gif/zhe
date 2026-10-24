import SwiftUI

struct HabitItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var symbol: String
    var goal: Int
    var counts: [String: Int] = [:]
}
struct LittleAgreement: Identifiable, Codable {
    var id = UUID()
    var title: String
    var note: String
    var flowers: Int
    var state = "待接受"
    var due: Date
}
struct RewardReceipt: Identifiable, Codable {
    var id = UUID()
    var title: String
    var cost: Int
    var used = false
    var date = Date()
}
struct TimeLetter: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var opensAt: Date
    var created = Date()
    var attachment: String?
    var opened = false
}
struct CircleEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var note: String
    var date: Date
}
struct CircleExpense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var cents: Int
    var members: [String]
    var paid: Set<String> = []
    var date = Date()
}
struct ChatKeyword: Identifiable, Codable {
    var id = UUID()
    var word: String
    var effect: Int
}
struct GomokuGame: Codable {
    var board: [Int] = Array(repeating: 0, count: 81)
    var moves: [Int] = []
    var turn = 1
    var winner = 0
    var draw = false
    mutating func place(_ cell: Int) {
        guard (0..<81).contains(cell), board[cell] == 0, winner == 0, !draw else { return }
        board[cell] = turn; moves.append(cell)
        let r = cell / 9, c = cell % 9
        for (dr, dc) in [(1, 0), (0, 1), (1, 1), (1, -1)] {
            var count = 1
            for sign in [-1, 1] {
                var rr = r + dr * sign, cc = c + dc * sign
                while (0..<9).contains(rr) && (0..<9).contains(cc) && board[rr * 9 + cc] == turn {
                    count += 1; rr += dr * sign; cc += dc * sign
                }
            }
            if count >= 5 { winner = turn; break }
        }
        draw = winner == 0 && moves.count == 81
        if winner == 0 && !draw { turn = 3 - turn }
    }
    mutating func undo() {
        guard let cell = moves.popLast() else { return }
        turn = board[cell]; board[cell] = 0; winner = 0; draw = false
    }
}
struct PlaygroundData: Codable {
    var habits = [
        HabitItem(title: "喝水小目标", symbol: "drop.fill", goal: 8),
        HabitItem(title: "认真吃早餐", symbol: "sun.max.fill", goal: 1),
        HabitItem(title: "一起动一动", symbol: "figure.walk", goal: 1),
        HabitItem(title: "说一句晚安", symbol: "moon.stars.fill", goal: 1)
    ]
    var agreements: [LittleAgreement] = []
    var flowers = 12
    var awarded: Set<String> = []
    var rewards: [RewardReceipt] = []
    var capsules: [TimeLetter] = []
    var events: [CircleEvent] = []
    var expenses: [CircleExpense] = []
    var outfit = 0
    var stickerDay: String?
    var dailySticker = 0
    var gomoku = GomokuGame()
    var story: [String] = []
    var wheelOptions = ["去散步", "喝奶茶", "做晚饭", "看电影"]
    var keywords = [ChatKeyword(word: "想你", effect: 0), ChatKeyword(word: "晚安", effect: 1), ChatKeyword(word: "小猫咪", effect: 2)]
    var readReceipt = false
    var showPreview = false
    var quietHours = false
    var musicFile: String?
    var musicTitle: String?
}
@MainActor extension CircleStore {
    var play: PlaygroundData { current.playground ?? PlaygroundData() }
    static func dayKey(_ date: Date = Date()) -> String {
        let d = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", d.year ?? 0, d.month ?? 0, d.day ?? 0)
    }
    func updatePlay(_ change: (inout PlaygroundData) -> Void) {
        update { data in
            var p = data.playground ?? PlaygroundData(); change(&p); data.playground = p
        }
    }
    func checkHabit(_ id: UUID) {
        updatePlay { p in
            guard let i = p.habits.firstIndex(where: { $0.id == id }) else { return }
            let key = Self.dayKey(), goal = p.habits[i].goal
            let count = p.habits[i].counts[key] ?? 0
            guard count < goal else { return }
            p.habits[i].counts[key] = count + 1
            let rewardID = "habit:\(id):\(key)"
            if count + 1 == goal && !p.awarded.contains(rewardID) { p.flowers += 2; p.awarded.insert(rewardID) }
        }
    }
    func addHabit(_ title: String, goal: Int) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, (1...20).contains(goal) else { return }
        updatePlay { $0.habits.append(HabitItem(title: String(title.prefix(40)), symbol: "sparkles", goal: goal)) }
    }
    func addAgreement(_ title: String, note: String, flowers: Int, due: Date) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, (1...20).contains(flowers) else { return }
        updatePlay { $0.agreements.insert(LittleAgreement(title: String(title.prefix(60)), note: String(note.prefix(300)), flowers: flowers, due: due), at: 0) }
    }
    func setAgreement(_ id: UUID, state: String) {
        updatePlay { p in
            guard let i = p.agreements.firstIndex(where: { $0.id == id }) else { return }
            let old = p.agreements[i].state
            let allowed: [String: [String]] = ["待接受": ["已接受", "想商量"], "想商量": ["已接受"], "已接受": ["已完成"]]
            guard allowed[old]?.contains(state) == true else { return }
            p.agreements[i].state = state
            if state == "已完成" && !p.awarded.contains("agreement:\(id)") {
                p.flowers += p.agreements[i].flowers; p.awarded.insert("agreement:\(id)")
            }
        }
    }
    func redeemReward(_ title: String, cost: Int) -> Bool {
        guard cost > 0, play.flowers >= cost else { return false }
        updatePlay { $0.flowers -= cost; $0.rewards.insert(RewardReceipt(title: title, cost: cost), at: 0) }
        return true
    }
    func addCapsule(title: String, body: String, opensAt: Date, photo: String?) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, opensAt > Date() else { return }
        updatePlay { $0.capsules.insert(TimeLetter(title: String(title.prefix(60)), body: String(body.prefix(2000)), opensAt: opensAt, attachment: photo), at: 0) }
    }
    func openCapsule(_ id: UUID) {
        guard let item = play.capsules.first(where: { $0.id == id }), item.opensAt <= Date() else { return }
        updatePlay { p in if let i = p.capsules.firstIndex(where: { $0.id == id }) { p.capsules[i].opened = true } }
    }
    func takeDailySticker() -> Int {
        let day = Self.dayKey()
        if play.stickerDay == day { return play.dailySticker }
        let pose = Int.random(in: 0..<6)
        updatePlay { $0.stickerDay = day; $0.dailySticker = pose }
        collectSticker(pose: pose, caption: ["抱抱今天的你", "才没有很想你", "请你喝一杯", "晚安小月亮", "一起玩一局", "画点可爱的小事"][pose])
        return pose
    }
    var memberNames: [String] { friends ? [myName, "柚柚", "桃桃", "糖糖", "栗栗", "朵朵"] : [myName, "阿哲"] }
    func localExitSpace() {
        let remaining = (state.joinedSpaces ?? ["couple"]).filter { $0 != state.mode }
        state.joinedSpaces = remaining
        if let mode = remaining.first { state.mode = mode }
        else { state.entered = false }
        persist()
    }
}

