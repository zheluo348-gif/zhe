import SwiftUI
import UIKit

enum PlaygroundArt {
    static func icon(_ index: Int) -> UIImage? {
        guard let cg = UIImage(named: "PlaygroundIcons")?.cgImage else { return nil }
        let column = max(0, min(3, index % 4))
        let x = [25, 390, 745, 1090][column], w = [360, 345, 340, 358][column]
        let row = max(0, min(2, index / 4))
        let y = [75, 410, 730][row], h = [330, 317, 310][row]
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: w, height: h)) else { return nil }
        return UIImage(cgImage: cropped)
    }
}
struct MiniIllustration: View {
    var index: Int
    var symbol = "sparkles"
    var body: some View {
        if let image = PlaygroundArt.icon(index) { Image(uiImage: image).resizable().scaledToFit().accessibilityHidden(true) }
        else { Image(systemName: symbol).font(.system(size: 30)).foregroundStyle(Palette.rose).accessibilityHidden(true) }
    }
}
struct PlaygroundHomeView: View {
    @EnvironmentObject var store: CircleStore
    var open: (Screen) -> Void
    @State private var unlockedStage: GrowthStage?
    private var shortcuts: [(String, Int, Screen)] {
        let all: [(String, Int, Screen)] = [
        ("打卡", 0, .habits), ("小约定", 1, .agreements), ("团团", 2, .pet),
        ("今天玩什么", 3, .games), ("时光胶囊", 4, .capsules), ("更多玩法", 10, .modules)
        ]
        let favorites = store.growth.favoriteModules
        return favorites.compactMap { key in all.first { $0.2.rawValue == key } } + all.filter { !favorites.contains($0.2.rawValue) }
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 17) {
                HStack {
                    HStack(spacing: -7) { MyAvatar(size: 37); Avatar(name: store.friends ? "柚" : "哲", size: 37) }
                    VStack(alignment: .leading, spacing: 4) { Text(store.spaceName).font(.title3.bold()); Text(store.friends ? "把小日常，过成一窝热闹" : "只属于我们的，一点小日常").font(.caption).foregroundStyle(Palette.muted) }
                    Spacer()
                    NavigationLink(value: Screen.status) { Image(systemName: "face.smiling").frame(width: 40, height: 44).foregroundStyle(Palette.ink) }.accessibilityLabel("我的心情")
                }.padding(.top, 7)
                GrowingRoomCard(open: open)
                HStack {
                    Button { open(.growth) } label: { Label("成长旅行", systemImage: "sparkles").font(.system(size: 12, weight: .semibold)) }.accessibilityIdentifier("openGrowth")
                    Spacer()
                    Text(store.friends ? "熟悉的人，一起点亮日常" : "在一起 \(store.togetherDays) 天 · 距周年 \(store.nextAnniversary.days) 天").font(.system(size: 10)).foregroundStyle(Palette.muted)
                }.padding(.horizontal, 3)
                Surface(padding: 13) { HStack {
                    Avatar(name: store.friends ? "柚" : "哲", size: 34)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.friends ? "小窝的此刻" : "阿哲的此刻").font(.subheadline.bold())
                        Text("等待连接并主动分享状态").font(.caption).foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    NavigationLink(value: Screen.sharing) { Image(systemName: "battery.75percent").foregroundStyle(Palette.teal).frame(width: 44, height: 44) }
                } }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 13) {
                    ForEach(Array(shortcuts.enumerated()), id: \.offset) { i, item in
                        Button { open(item.2) } label: {
                            VStack(spacing: 5) {
                                MiniIllustration(index: item.1).frame(height: 54)
                                Text(item.0).font(.system(size: 13, weight: .semibold))
                            }.frame(maxWidth: .infinity).padding(.vertical, 10).background(.white, in: RoundedRectangle(cornerRadius: 20))
                        }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("quick_\(i)")
                    }
                }
                Button { open(.inspiration) } label: {
                    PaperCard(color: Palette.lavender, tape: false) { HStack { TuantuanSticker(pose: 5).frame(width: 58, height: 58); VStack(alignment: .leading, spacing: 6) { Text("今天一起玩点什么？").font(.headline); Text("创作贴纸 · 找团团 · 小默契").font(.caption).foregroundStyle(Palette.muted) }; Spacer(); Image(systemName: "arrow.right") } }
                }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("homeInspiration")
                HStack(spacing: 12) {
                    Button { open(.room) } label: { Surface(padding: 13) { IconTile(icon: "sofa.fill", title: "小房间", subtitle: "陪你坐一会") } }.accessibilityIdentifier("homeRoom")
                    Button { store.poke(); open(.heart) } label: { Surface(padding: 13) { IconTile(icon: "heart.fill", title: "想你了", subtitle: "留一个小心意") } }.accessibilityIdentifier("pokeButton")
                }.buttonStyle(.plain)
                Button { open(.question) } label: {
                    PaperCard { HStack { VStack(alignment: .leading, spacing: 8) { Text("每日一问").font(.caption.bold()).foregroundStyle(Palette.rose); Text("如果明天放假，你想一起去哪？").font(.headline) }; Spacer(); Image(systemName: "chevron.right") } }
                }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("dailyQuestion")
                if store.friends { Surface { PollContent() } }
                Text("本机开发体验 · 内容独立保存").font(.caption2).foregroundStyle(Palette.muted)
            }.padding(.horizontal, 20).padding(.bottom, 22)
        }.onAppear { checkMilestone() }
            .onChange(of: store.growthStage.day) { _, _ in checkMilestone() }
            .sheet(item: $unlockedStage) { stage in StageUnlockView(stage:stage) }
    }
    func checkMilestone() {
        let stage=store.growthStage
        guard stage.day>1,(store.growth.seenStageDay ?? 1)<stage.day else { return }
        store.updateGrowth { $0.seenStageDay=stage.day };unlockedStage=stage
    }
}
struct PlayModule: Identifiable {
    let title: String
    let detail: String
    let icon: Int
    let screen: Screen
    var id: String { title }
}
struct AllPlaygroundsView: View {
    let groups: [(String, [PlayModule])] = [
        ("一起过日子", [
            PlayModule(title: "今日打卡", detail: "给小习惯盖个章", icon: 0, screen: .habits),
            PlayModule(title: "小约定", detail: "商量着一起完成", icon: 1, screen: .agreements),
            PlayModule(title: "奖励小铺", detail: "兑换一张小心意", icon: 7, screen: .rewards),
            PlayModule(title: "共同愿望", detail: "慢慢完成小期待", icon: 8, screen: .wishes),
            PlayModule(title: "日历与聚会", detail: "记下见面的日子", icon: 6, screen: .calendar),
            PlayModule(title: "聚会份子", detail: "只记份额，不付款", icon: 11, screen: .expenses)
        ]),
        ("一起玩一会", [
            PlayModule(title: "今天玩什么", detail: "默契、画画、小故事", icon: 3, screen: .games),
            PlayModule(title: "决定小转盘", detail: "纠结的时候转一下", icon: 10, screen: .wheel),
            PlayModule(title: "找团团玩", detail: "周末小主意", icon: 2, screen: .tuantuan),
            PlayModule(title: "团团小衣橱", detail: "换个小装扮", icon: 5, screen: .wardrobe),
            PlayModule(title: "每日小惊喜", detail: "收好今天的贴纸", icon: 7, screen: .surprise),
            PlayModule(title: "暗号特效", detail: "只有小圈懂的词", icon: 10, screen: .keywords)
        ]),
        ("把日子收藏起来", [
            PlayModule(title: "时光胶囊", detail: "写给未来的一封信", icon: 4, screen: .capsules),
            PlayModule(title: "年度回忆", detail: "翻翻真实的小记录", icon: 8, screen: .annual),
            PlayModule(title: "成就册", detail: "点亮自己的小星星", icon: 10, screen: .achievements),
            PlayModule(title: "表情包工坊", detail: "照片加一句小心情", icon: 2, screen: .stickers),
            PlayModule(title: "一起听", detail: "导入自己的音频", icon: 9, screen: .music),
            PlayModule(title: "心情手账", detail: "三格小故事", icon: 8, screen: .comic)
        ])
    ]
    var body: some View {
        CreativePage(title: "小圈游乐场", subtitle: "好多小事，都想和你一起玩。") {
            ForEach(groups, id: \.0) { title, modules in
                Text(title).font(.title3.bold())
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(modules) { item in NavigationLink(value: item.screen) {
                        HStack(spacing: 7) { MiniIllustration(index: item.icon).frame(width: 54, height: 61); VStack(alignment: .leading, spacing: 6) { Text(item.title).font(.system(size: 14, weight: .semibold)); Text(item.detail).font(.system(size: 10)).foregroundStyle(Palette.muted).lineLimit(2) }; Spacer(minLength: 0) }.padding(11).frame(maxWidth: .infinity, minHeight: 88).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("module_\(item.screen.rawValue)") }
                }
            }
        }
    }
}

