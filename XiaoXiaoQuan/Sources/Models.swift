import SwiftUI

enum MessageBurnDuration: Int, CaseIterable, Codable, Identifiable {
    case five = 5, ten = 10, thirty = 30, sixty = 60
    var id: Int { rawValue }
    var title: String { "查看后\(rawValue)秒销毁" }
}

struct DisappearingContent: Codable, Equatable {
    var body: String?
    let duration: MessageBurnDuration
    var expiresAt: Date?

    func readableBody(at date: Date) -> String? {
        guard expiresAt.map({ $0 > date }) ?? true else { return nil }
        return body
    }
}

struct SharedDrawingRound: Identifiable, Codable, Equatable {
    var id = UUID()
    let author: String
    let drawing: Data
    let note: String
}

struct SharedDrawingSession: Codable, Equatable {
    let players: [String]
    var rounds: [SharedDrawingRound] = []
    var finished = false
    var savedMemoryID: UUID?
    var currentPlayer: String { players.isEmpty ? "小伙伴" : players[rounds.count % players.count] }
    var canFinish: Bool { !finished && Set(rounds.map(\.author)).count >= 2 }

    mutating func append(drawing: Data, note: String, revision: Int) -> Bool {
        let note = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        guard !finished, revision == rounds.count, rounds.count < 24,
              (2...8).contains(players.count), Set(players).count == players.count,
              players.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              drawing.count <= 131072, !drawing.isEmpty || !note.isEmpty else { return false }
        rounds.append(SharedDrawingRound(author: currentPlayer, drawing: drawing, note: note))
        return true
    }

    mutating func finish(revision: Int) -> Bool {
        guard revision == rounds.count, canFinish else { return false }
        finished = true
        return true
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var sender: String
    var mine: Bool
    var kind: String = "text"
    var attachment: String?
    var date = Date()
    var invitation: PlayInvitation?
    var disappearing: DisappearingContent?
    var sharedDrawing: SharedDrawingSession?
}
struct Wish: Identifiable, Codable {
    var id = UUID()
    var title: String
    var note: String
    var done = false
    var theme: String = "sunset"
}
struct MemoryItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var note: String
    var kind: String = "小事"
    var theme: String = "coffee"
    var attachment: String?
    var date = Date()
}
struct SpaceData: Codable {
    var growth: GrowthState?
    var playground: PlaygroundData?
    var creative: CreativeSpace?
    var draft: String?
    var messages: [ChatMessage] = []
    var memories: [MemoryItem] = []
    var wishes: [Wish] = []
    var pokes = 0
    var answer = ""
    var vote: String?
    var status = ""
    var satiety = 80
    var mood = 75
    var clean = 40
    var petLog: [String] = ["一起入住了小窝"]

    var exportableCopy: SpaceData {
        var copy = self
        copy.messages.removeAll { $0.disappearing != nil }
        return copy
    }

    mutating func expireDisappearingMessages(at date: Date) -> Bool {
        var changed = false
        for i in messages.indices {
            guard let content = messages[i].disappearing, content.body != nil,
                  let deadline = content.expiresAt, deadline <= date else { continue }
            messages[i].disappearing?.body = nil
            changed = true
        }
        return changed
    }

    var nextMessageExpiration: Date? {
        messages.compactMap { message in
            guard message.disappearing?.body != nil else { return nil }
            return message.disappearing?.expiresAt
        }.min()
    }
}
struct SavedState: Codable {
    var aiEnabled: Bool?
    var profile: CircleProfile?
    var joinedSpaces: [String]?
    var entered = false
    var mode = "couple"
    var couple = SpaceData()
    var friends = SpaceData()
    var haptics = true
    var joined = Date()
}

@MainActor final class CircleStore: ObservableObject {
    @Published var state: SavedState
    @Published var saveError: String?
    private let defaults: UserDefaults
    private let key = "xiaoxiaoquan.preview.v1"
    private var messageExpirationTask: Task<Void, Never>?
    var friends: Bool { state.mode == "friends" }
    var accent: Color { friends ? Palette.teal : Palette.rose }
    var spaceName: String { spaceName(for:state.mode) }
    func spaceName(for mode:String) -> String {
        let data=mode=="friends" ? state.friends:state.couple
        if let name=data.growth?.spaceName,!name.isEmpty { return name }
        return mode=="friends" ? "六颗小丸子":"\(myName) & 阿哲"
    }
    var current: SpaceData { friends ? state.friends : state.couple }
    var background: Color { friends ? Palette.mint : Palette.cream }
    var togetherDays: Int { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: state.joined), to: Calendar.current.startOfDay(for: Date())).day ?? 0) }
    var nextAnniversary: (years: Int, days: Int) {
        let cal = Calendar.current, today = cal.startOfDay(for: Date())
        let parts = cal.dateComponents([.month, .day], from: state.joined)
        let year = cal.component(.year, from: today)
        var target = cal.date(from: DateComponents(year: year, month: parts.month, day: parts.day)) ?? today
        if target < today { target = cal.date(byAdding: .year, value: 1, to: target) ?? today }
        return (max(1, cal.dateComponents([.year], from: state.joined, to: target).year ?? 1), max(0, cal.dateComponents([.day], from: today, to: target).day ?? 0))
    }

    init() {
        let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
        defaults = testing ? UserDefaults(suiteName: "com.xiaoxiaoquan.preview.uitests")! : .standard
        if testing && ProcessInfo.processInfo.arguments.contains("--reset") { defaults.removeObject(forKey: key) }
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode(SavedState.self, from: data) {
            state = saved
        } else { state = Self.seed() }
        if state.joinedSpaces == nil {
            state.joinedSpaces = state.entered && state.mode == "friends" ? ["couple", "friends"] : ["couple"]
        }
        if state.couple.playground == nil { state.couple.playground = PlaygroundData() }
        if state.friends.playground == nil { state.friends.playground = PlaygroundData() }
        if state.couple.growth == nil { state.couple.growth = GrowthState() }
        if state.friends.growth == nil { state.friends.growth = GrowthState() }
        // Fixture only for isolated UI tests; normal user data never enters this path.
        if testing && ProcessInfo.processInfo.arguments.contains("--reset") && ProcessInfo.processInfo.arguments.contains("--growth-fixture-nine-days") {
            var g=GrowthState()
            g.visits=Set((1...9).map { Self.dayKey(Calendar.current.date(byAdding:.day,value:-$0,to:Date())!) })
            g.seenStageDay=7;state.couple.growth=g
        }
        if testing && ProcessInfo.processInfo.arguments.contains("--reset") && ProcessInfo.processInfo.arguments.contains("--wallpaper-fixture-eighty-nine-days") {
            var g=GrowthState()
            g.visits=Set((1...89).map { Self.dayKey(Calendar.current.date(byAdding:.day,value:-$0,to:Date())!) })
            g.seenStageDay=90;state.couple.growth=g
        }
        let renamedCouple = state.couple.adoptSugarName()
        let renamedFriends = state.friends.adoptSugarName()
        if renamedCouple || renamedFriends { persist() }
        expireDisappearingMessages()
    }
    deinit { messageExpirationTask?.cancel() }
    static func seed() -> SavedState {
        var s = SavedState()
        s.joined = Calendar.current.date(byAdding: .day, value: -712, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        s.couple.messages = [
            ChatMessage(text: "到家啦，今天地铁好挤", sender: "阿哲", mine: false),
            ChatMessage(text: "辛苦啦，给你点了奶茶", sender: "小糖", mine: true),
            ChatMessage(text: "那周末一起去看海吧", sender: "阿哲", mine: false),
            ChatMessage(text: "一个抱抱正在路上～", sender: "阿哲", mine: false, kind: "hug")
        ]
        s.friends.messages = [
            ChatMessage(text: "周六终于能见面啦！", sender: "桃桃", mine: false),
            ChatMessage(text: "我想吃火锅", sender: "柚柚", mine: false),
            ChatMessage(text: "那我们投票决定吧", sender: "小糖", mine: true),
            ChatMessage(text: "我不是胖，是被生活压扁了", sender: "糖糖", mine: false)
        ]
        s.couple.wishes = [Wish(title: "去海边看日落", note: "周六 16:30 · 海边公园"), Wish(title: "一起做一顿晚饭", note: "周日 18:00 · 选一道拿手菜", theme: "coffee")]
        s.friends.wishes = [Wish(title: "周六一起吃火锅", note: "等大家投票，一起选时间", theme: "coffee")]
        s.couple.memories = [MemoryItem(title: "终于一起看了海", note: "海风很轻，你也刚好在身边。", kind: "照片", theme: "sunset"), MemoryItem(title: "下班后的第一杯热奶茶", note: "普通的一天，也值得被记住。", kind: "小事", theme: "coffee")]
        s.friends.memories = [MemoryItem(title: "六个人的周末", note: "下次也要一起。", kind: "照片", theme: "sunset"), MemoryItem(title: "我不是胖，是被生活压扁了", note: "糖糖的名场面 · 示例", kind: "梗墙", theme: "coffee")]
        return s
    }
    func persist() {
        do { defaults.set(try JSONEncoder().encode(state), forKey: key); saveError = nil }
        catch { saveError = "本次更改未保存，请重试。" }
    }
    func update(_ transform: (inout SpaceData) -> Void) {
        if friends { transform(&state.friends) } else { transform(&state.couple) }
        persist()
    }
    func enter(_ mode: String) { state.mode = mode; state.entered = true; if !(state.joinedSpaces ?? []).contains(mode) { state.joinedSpaces = (state.joinedSpaces ?? []) + [mode] }; persist() }
    func selectSpace(_ mode: String) {
        guard (state.joinedSpaces ?? ["couple"]).contains(mode), state.mode != mode else { return }
        state.mode = mode
        persist()
    }
    func send(_ text: String, kind: String = "text") {
        let value = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !value.isEmpty else { return }
        let sender = myName
        update { $0.messages.append(ChatMessage(text: value, sender: sender, mine: true, kind: kind)); $0.playground?.awarded.insert("firstMessage") }
    }
    func sendDisappearingMessage(_ text: String, duration: MessageBurnDuration) {
        let value = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !value.isEmpty else { return }
        let sender = myName
        update {
            $0.messages.append(ChatMessage(text: "阅后即焚消息", sender: sender, mine: true,
                kind: "disappearing", disappearing: DisappearingContent(body: value, duration: duration)))
            $0.draft = nil
            $0.playground?.awarded.insert("firstMessage")
        }
    }
    func revealDisappearingMessage(_ id: UUID, space: String, at date: Date = Date()) -> Bool {
        guard ["couple", "friends"].contains(space) else { return false }
        var data = space == "friends" ? state.friends : state.couple
        guard let i = data.messages.firstIndex(where: { $0.id == id }),
              let content = data.messages[i].disappearing,
              content.readableBody(at: date) != nil else {
            expireDisappearingMessages(at: date)
            return false
        }
        if content.expiresAt == nil {
            data.messages[i].disappearing?.expiresAt = date.addingTimeInterval(Double(content.duration.rawValue))
            if space == "friends" { state.friends = data } else { state.couple = data }
            persist()
        }
        scheduleMessageExpiration()
        return true
    }
    func expireDisappearingMessages(at date: Date = Date()) {
        let coupleChanged = state.couple.expireDisappearingMessages(at: date)
        let friendsChanged = state.friends.expireDisappearingMessages(at: date)
        if coupleChanged || friendsChanged { persist() }
        scheduleMessageExpiration()
    }
    private func scheduleMessageExpiration() {
        messageExpirationTask?.cancel()
        guard let deadline = [state.couple.nextMessageExpiration, state.friends.nextMessageExpiration]
            .compactMap({ $0 }).min() else { messageExpirationTask = nil; return }
        let delay = max(0, deadline.timeIntervalSinceNow)
        messageExpirationTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.expireDisappearingMessages()
        }
    }
    func poke() { update { $0.pokes += 1 }; if state.haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() } }
    func answer(_ value: String) { update { $0.answer = value }; }
    func addWish(_ title: String, note: String) {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        update { $0.wishes.insert(Wish(title: value, note: note), at: 0) }
    }
    func addMemory(_ title: String, note: String, kind: String = "小事", theme: String = "coffee", attachment: String? = nil) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        update { $0.memories.insert(MemoryItem(title: title, note: note, kind: kind, theme: theme, attachment: attachment), at: 0) }
    }
    func toggleWish(_ id: UUID) { update { data in if let i = data.wishes.firstIndex(where: { $0.id == id }) { data.wishes[i].done.toggle() } } }
    func pet(_ action: String) {
        let actor = myName, companion = petName
        update { d in
            if action == "喂食" { d.satiety = min(100, d.satiety + 10) }
            if action == "洗澡" { d.clean = min(100, d.clean + 20) }
            if action == "陪玩" { d.mood = min(100, d.mood + 10) }
            d.petLog.insert("\(actor)给\(companion)" + (action == "喂食" ? "喂了一块小饼干" : action == "洗澡" ? "洗了个香香的澡" : "带来了一点快乐"), at: 0)
            d.petLog = Array(d.petLog.prefix(30))
        }
    }
}

extension CircleStore {
    private var photoDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let name = ProcessInfo.processInfo.arguments.contains("--uitesting") ? "TestPhotos" : "Photos"
        return base.appendingPathComponent(name, isDirectory: true)
    }
    func savePhoto(_ data: Data) throws -> String {
        guard let image = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
        let ratio = min(1, 1500 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileWriteUnknown) }
        try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        try jpeg.write(to: photoDirectory.appendingPathComponent(name), options: .atomic)
        return name
    }
    func sendPhoto(_ data: Data) throws {
        let name = try savePhoto(data)
        let sender = myName
        update { $0.messages.append(ChatMessage(text: "一张照片", sender: sender, mine: true, kind: "photo", attachment: name)) }
    }
    func addPhotoMemory(_ data: Data, caption: String) throws {
        let name = try savePhoto(data)
        addMemory(caption.isEmpty ? "分享此刻" : caption, note: "由\(myName)主动分享", kind: "照片", attachment: name)
    }
    func photo(named: String) -> UIImage? {
        guard !named.contains("/"), !named.contains("..") else { return nil }
        return UIImage(contentsOfFile: photoDirectory.appendingPathComponent(named).path)
    }
}
