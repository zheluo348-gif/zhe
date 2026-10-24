import SwiftUI

struct GrowthState: Codable {
    var visits: Set<String> = []
    var firstVisit = Date()
    var spaceName = ""
    var petName = "团团"
    var wallMemoryID: UUID?
    var favoriteModules: [String] = []
    var seenStageDay: Int?
    var selectedWallpaperDay: Int?
}
struct CircleProfile: Codable {
    var nickname = "小糖"
    var avatarPhoto: String?
}
struct GrowthStage: Identifiable, Equatable {
    let day: Int
    let title: String
    let line: String
    let gift: String
    let kind: Int
    let skyHex: UInt32
    let floorHex: UInt32
    let accentHex: UInt32
    var variation: Int = 0
    var id: Int { day }
    var sky: Color { Color(hex: skyHex) }
    var floor: Color { Color(hex: floorHex) }
    var accent: Color { Color(hex: accentHex) }
    var onPaperAccent: Color { dark ? Color(hex: 0x755779) : accent }
    var dark: Bool { [4, 5, 7, 8, 9, 10, 12, 13].contains(kind) }
    static let all: [GrowthStage] = [
        .init(day: 1, title: "初见糖纸", line: "先给彼此，留一个软软的位置。", gift: "糖纸小窗", kind: 0, skyHex: 0xF8E7DB, floorHex: 0xF5D5CB, accentHex: 0xB95972),
        .init(day: 2, title: "心意发芽", line: "昨天的一点心意，今天冒出了芽。", gift: "发芽盆栽", kind: 1, skyHex: 0xDBEFE5, floorHex: 0xB9D9C9, accentHex: 0x347D70),
        .init(day: 3, title: "默契拼图", line: "你的奇思妙想，刚好拼进我的日常。", gift: "拼图相框", kind: 2, skyHex: 0xE7E1F5, floorHex: 0xCFC2E8, accentHex: 0x8572AA),
        .init(day: 7, title: "落日来信", line: "收好一周的日落，寄给最想念的人。", gift: "落日露台", kind: 3, skyHex: 0xF8D4B5, floorHex: 0xDB9BA3, accentHex: 0xB85676),
        .init(day: 10, title: "星光搭子", line: "把普通的日子，过成小小的太空旅行。", gift: "星光观察舱", kind: 4, skyHex: 0x25294F, floorHex: 0x49486E, accentHex: 0x9ECCE2),
        .init(day: 30, title: "月光小窝", line: "月亮也知道，这里有个属于我们的小窝。", gift: "月光玻璃穹顶", kind: 5, skyHex: 0x34334F, floorHex: 0x5A5177, accentHex: 0xF1CD95),
        .init(day: 60, title: "云端花园", line: "那些一起照顾的小事，慢慢开了花。", gift: "漂浮花园", kind: 6, skyHex: 0xCDECEB, floorHex: 0xA8CFBD, accentHex: 0x3D8F87),
        .init(day: 90, title: "星河同行", line: "每次回来，都有人值得分享。", gift: "星河传送门", kind: 7, skyHex: 0x242845, floorHex: 0x424A6D, accentHex: 0xC1A8E7),
        .init(day: 120, title: "深海来信", line: "沉进一片蓝，听见温柔的回音。", gift: "海底观景窗", kind: 10, skyHex: 0x193E59, floorHex: 0x30677B, accentHex: 0x9CDDD7),
        .init(day: 150, title: "花间慢车", line: "不用赶路，和你一起慢慢到达。", gift: "春日列车窗", kind: 11, skyHex: 0xEDDDE8, floorHex: 0xC7B7D3, accentHex: 0x8A617C),
        .init(day: 180, title: "极光漫游", line: "走过慢慢的日子，也见到新的颜色。", gift: "极光天幕", kind: 8, skyHex: 0x183C4D, floorHex: 0x416675, accentHex: 0x8BD9C9),
        .init(day: 210, title: "雨夜小铺", line: "外面下着雨，小窝给你留着灯。", gift: "雨夜霓虹招牌", kind: 12, skyHex: 0x293549, floorHex: 0x485065, accentHex: 0xEBA8C9),
        .init(day: 240, title: "萤火森林", line: "把微小的光，留在彼此身边。", gift: "萤火树屋", kind: 13, skyHex: 0x203F3E, floorHex: 0x47715D, accentHex: 0xD2E1A4),
        .init(day: 270, title: "糖果星港", line: "靠岸啦，今天也有甜甜的小事。", gift: "糖果停泊台", kind: 14, skyHex: 0xEFDFEC, floorHex: 0xC8BEDF, accentHex: 0x8E6B9E),
        .init(day: 300, title: "雪夜壁炉", line: "雪慢慢落，我们慢慢说。", gift: "暖光小壁炉", kind: 15, skyHex: 0xECE6DE, floorHex: 0xC7AF9E, accentHex: 0x9A624E),
        .init(day: 330, title: "风铃海岸", line: "有风，有海，还有想分享给你的今天。", gift: "海岸风铃窗", kind: 16, skyHex: 0xD8EEEB, floorHex: 0xB5D0CF, accentHex: 0x467F85),
        .init(day: 360, title: "宇宙纪念", line: "把这一段路的光，装进我们的纪念盒。", gift: "周年星球", kind: 9, skyHex: 0x3B334B, floorHex: 0x6F5E76, accentHex: 0xF0C98F)
    ]
    static func at(_ days: Int) -> GrowthStage {
        if days < 30 { return all.last { $0.day < 30 && $0.day <= max(1,days) } ?? all[0] }
        return monthly(max(1,days/30))
    }
    static func exact(_ day:Int) -> GrowthStage? {
        if day<30 { return all.first { $0.day==day } }
        guard day>0,day%30==0 else { return nil };return monthly(day/30)
    }
    static func monthly(_ period:Int) -> GrowthStage {
        let period=max(1,period),bases=Array(all.filter{$0.day>=30})
        let cycle=(period-1)/bases.count,base=bases[(period-1)%bases.count]
        if cycle==0 { return base }
        let hue=Double((period*37+cycle*19)%360)/360
        return GrowthStage(day:period*30,title:"\(base.title)·第\(cycle+1)季",line:"把第\(period)期的小光景，也留给喜欢的人。",gift:"\(base.gift)·第\(cycle+1)季",kind:base.kind,skyHex:rgb(hue,base.dark ? 0.48:0.12,base.dark ? 0.29:0.96),floorHex:rgb(hue+0.04,0.22,base.dark ? 0.46:0.83),accentHex:rgb(hue+0.13,base.dark ? 0.20:0.45,base.dark ? 0.91:0.58),variation:cycle)
    }
    static func catalog(through days:Int) -> [GrowthStage] {
        Array(all.filter{$0.day<30})+(1...max(12,max(1,days)/30+12)).map { monthly($0) }
    }
    private static func rgb(_ hue:Double,_ saturation:Double,_ value:Double)->UInt32 {
        let h=(hue.truncatingRemainder(dividingBy:1)+1).truncatingRemainder(dividingBy:1)*6,i=Int(h),f=h-Double(i),p=value*(1-saturation),q=value*(1-f*saturation),t=value*(1-(1-f)*saturation)
        let c:[[Double]]=[[value,t,p],[q,value,p],[p,value,t],[p,q,value],[t,p,value],[value,p,q]]
        let color=c[i%6].map{UInt32(max(0,min(255,Int(($0*255).rounded()))))};return color[0]<<16 | color[1]<<8 | color[2]
    }
    var next: GrowthStage? { day<30 ? Self.all.first{$0.day>day}:Self.monthly(day/30+1) }

}
enum InvitationGame: String, Codable, CaseIterable, Identifiable {
    case quiz, story, gomoku
    var id: String { rawValue }
    var title: String { switch self { case .quiz: return "默契猜猜"; case .story: return "故事接龙"; case .gomoku: return "小窝五子棋" } }
    var symbol: String { switch self { case .quiz: return "heart.text.square"; case .story: return "pencil.and.outline"; case .gomoku: return "circle.grid.3x3" } }
}
struct PlayInvitation: Codable, Equatable {
    var game: InvitationGame
    var state = "等你来玩"
    var summary: String?
}
@MainActor extension CircleStore {
    var growth: GrowthState { current.growth ?? GrowthState() }
    var growthDays: Int { max(1, growth.visits.count) }
    var growthStage: GrowthStage { GrowthStage.at(growthDays) }
    var stage: GrowthStage { if let day=growth.selectedWallpaperDay,day<=growthDays,let wallpaper=GrowthStage.exact(day) { return wallpaper };return growthStage }
    func useWallpaper(_ day:Int) {
        guard day<=growthDays,GrowthStage.exact(day) != nil else { return }
        updateGrowth { $0.selectedWallpaperDay=day }
    }
    func followNewestWallpaper() { updateGrowth { $0.selectedWallpaperDay=nil } }
    var myName: String { state.profile?.nickname ?? "小糖" }
    var petName: String { growth.petName }
    func updateGrowth(_ change: (inout GrowthState) -> Void) {
        update { data in var g = data.growth ?? GrowthState(); change(&g); data.growth = g }
    }
    func recordVisit(_ date: Date = Date()) {
        guard state.entered else { return }
        let key = Self.dayKey(date)
        guard !growth.visits.contains(key) else { return }
        updateGrowth { $0.visits.insert(key) }
    }
    func setProfile(_ nickname: String, photo: String?, space: String, pet: String, favorites: [String]) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 8, !["阿哲", "柚柚", "桃桃", "糖糖", "栗栗", "朵朵"].contains(name) else { return }
        state.profile = CircleProfile(nickname: name, avatarPhoto: photo)
        updateGrowth { $0.spaceName = String(space.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16)); $0.petName = String(pet.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8)); if $0.petName.isEmpty { $0.petName = "团团" }; $0.favoriteModules = favorites }
    }
    func sendChargedHug(level: Int) {
        let level = min(3, max(1, level))
        send(["软软抱抱", "星星抱抱", "宇宙抱抱"][level - 1], kind: "hug:\(level)")
    }
    func inviteToPlay(_ game: InvitationGame) {
        let sender = myName
        update { $0.messages.append(ChatMessage(text: "陪我玩一会\(game.title)吧", sender: sender, mine: true, kind: "invite", invitation: PlayInvitation(game: game))) }
    }
    func acceptInvitation(_ id: UUID) {
        guard let message = current.messages.first(where: { $0.id == id }), message.invitation?.state == "等你来玩" else { return }
        if message.invitation?.game == .quiz && (creative.quiz == nil || creative.quiz?.finished == true) { startQuiz() }
        update { if let i = $0.messages.firstIndex(where: { $0.id == id }) { $0.messages[i].invitation?.state = "一起玩着" } }
    }
    func invitationSummary(_ id: UUID) -> String? {
        guard let game = current.messages.first(where: { $0.id == id })?.invitation?.game else { return nil }
        switch game {
        case .quiz: return creative.quiz?.finished == true ? "收好了3题小默契。" : nil
        case .story: return play.story.isEmpty ? nil : "当前故事共\(play.story.count)句。\n" + String(play.story.suffix(2).joined(separator: "\n").prefix(200))
        case .gomoku: let g = play.gomoku; return g.winner > 0 || g.draw ? "当前棋局：\(g.winner == 0 ? "平局" : (g.winner == 1 ? "黑棋胜出" : "白棋胜出"))，共\(g.moves.count)步。" : nil
        }
    }
    func finishInvitation(_ id: UUID) {
        guard let summary = invitationSummary(id) else { return }
        update { if let i = $0.messages.firstIndex(where: { $0.id == id }), $0.messages[i].invitation?.state == "一起玩着" { $0.messages[i].invitation?.state = "收好小回忆"; $0.messages[i].invitation?.summary = summary } }
    }
}
