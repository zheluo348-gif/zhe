import SwiftUI

struct DressedTuantuan: View {
    var outfit: Int
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MiniIllustration(index: 2)
                if outfit == 1 { Image(systemName: "bowtie.fill").font(.system(size: geo.size.width * 0.17)).foregroundStyle(Palette.teal).offset(y: geo.size.height * 0.05).rotationEffect(.degrees(-8)) }
                if outfit == 2 { Image(systemName: "flower.fill").font(.system(size: geo.size.width * 0.15)).foregroundStyle(Color(hex: 0xE3B348)).offset(x: -geo.size.width * 0.22, y: -geo.size.height * 0.24) }
                if outfit == 3 { Image(systemName: "party.popper.fill").font(.system(size: geo.size.width * 0.19)).foregroundStyle(Color(hex: 0xA997D2)).rotationEffect(.degrees(-25)).offset(x: geo.size.width * 0.18, y: -geo.size.height * 0.26) }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityLabel(["团团的日常装", "戴绿色蝴蝶结的团团", "戴小花的团团", "庆祝中的团团"][min(3, max(0, outfit))])
    }
}
struct PetPlayView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubble = "今天也想和你贴贴～"
    @State private var bounce = false
    var body: some View {
        CreativePage(title: "我们的小\(store.petName)", subtitle: "有空来陪它玩一会，忙几天也不会受罚。") {
            ZStack(alignment: .bottom) {
                Ellipse().fill(Palette.pink).frame(height: 45).padding(.bottom, 10)
                DressedTuantuan(outfit: store.play.outfit).frame(height: 240).scaleEffect(bounce ? 1.08 : 1)
            }.frame(height: 260)
            Text(bubble).font(.headline).frame(maxWidth: .infinity).padding(15).background(.white, in: Capsule()).accessibilityIdentifier("petBubble")
            Surface { VStack(spacing: 16) {
                petMeter("饱食值", value: store.current.satiety, symbol: "carrot.fill", color: Palette.teal)
                petMeter("好心情", value: store.current.mood, symbol: "heart.fill", color: Palette.rose)
                petMeter("干净值", value: store.current.clean, symbol: "bubbles.and.sparkles", color: Color(hex: 0x9082BC))
            } }
            HStack(spacing: 10) { ForEach(0..<3) { i in Button { interact(i) } label: {
                VStack(spacing: 10) { Image(systemName: ["birthday.cake.fill", "drop.fill", "hand.raised.fill"][i]).font(.title2); Text(["喂一口", "洗香香", "摸摸头"][i]).font(.subheadline.bold()) }.frame(maxWidth: .infinity).frame(height: 88).foregroundStyle(i == 1 ? Palette.teal : Palette.rose).background([Palette.pink, Palette.mint, Palette.lavender][i], in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain).accessibilityIdentifier("petAction_\(i)") } }
            HStack(spacing: 12) {
                NavigationLink(value: Screen.wardrobe) { iconCard("小衣橱", icon: 5) }.accessibilityIdentifier("petWardrobe")
                NavigationLink(value: Screen.surprise) { iconCard("每日小惊喜", icon: 7) }.accessibilityIdentifier("petSurprise")
            }.buttonStyle(.plain)
            NavigationLink(value: Screen.tuantuan) { Label("找团团想个周末小主意", systemImage: "pawprint.fill").frame(maxWidth: .infinity, minHeight: 44) }
            Text("团团日记").font(.title3.bold())
            Surface { VStack(alignment: .leading, spacing: 14) { ForEach(Array(store.current.petLog.prefix(12).enumerated()), id: \.offset) { _, text in Text(text).font(.subheadline).lineSpacing(5) } } }
        }
    }
    func iconCard(_ title: String, icon: Int) -> some View { Surface(padding: 10) { HStack { MiniIllustration(index: icon).frame(width: 47, height: 58); Text(title).font(.system(size: 14, weight: .semibold)); Spacer(minLength: 0) } }.foregroundStyle(Palette.ink) }
    func petMeter(_ name: String, value: Int, symbol: String, color: Color) -> some View {
        HStack { Image(systemName: symbol).foregroundStyle(color).frame(width: 25); Text(name).font(.caption); ProgressView(value: Double(value), total: 100).tint(color); Text("\(value)%").font(.caption.monospacedDigit()).frame(width: 40) }
    }
    func interact(_ index: Int) {
        store.pet(["喂食", "洗澡", "陪玩"][index]); bubble = ["小饼干好香呀，谢谢你！", "洗得香喷喷，贴贴更开心。", "摸摸头，把今天的疲惫抖掉～"][index]
        if store.state.haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        if store.creative.animations && !reduceMotion { withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { bounce = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { bounce = false } } }
    }
}
struct WardrobeView: View {
    @EnvironmentObject var store: CircleStore
    private let names = ["软乎乎的日常", "小绿蝴蝶结", "春天的小花", "今天要庆祝"]
    var body: some View {
        CreativePage(title: "团团的小衣橱", subtitle: "不花钱，也可以打扮得可可爱爱。") {
            DressedTuantuan(outfit: store.play.outfit).frame(height: 255).frame(maxWidth: .infinity)
            Text(names[store.play.outfit]).font(.title3.bold()).frame(maxWidth: .infinity).accessibilityIdentifier("selectedOutfit")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                ForEach(0..<4) { i in Button { store.updatePlay { $0.outfit = i } } label: {
                    VStack(spacing: 10) { DressedTuantuan(outfit: i).frame(height: 108); Text(names[i]).font(.subheadline.bold()); Label(store.play.outfit == i ? "正在穿" : "试试看", systemImage: store.play.outfit == i ? "checkmark.circle.fill" : "tshirt").font(.caption).foregroundStyle(Palette.teal) }.padding(12).frame(maxWidth: .infinity).background(store.play.outfit == i ? Palette.mint : .white, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(store.play.outfit == i ? Palette.teal : .clear, lineWidth: 1.5))
                }.buttonStyle(.plain).accessibilityIdentifier("outfit_\(i)") }
            }
            Text("装扮已自动保存在当前空间。当前为二维小配饰，后续可以继续增加原创服饰。").font(.caption).foregroundStyle(Palette.muted)
        }
    }
}
struct DailySurpriseView: View {
    @EnvironmentObject var store: CircleStore
    @State private var opened = false
    @State private var sent = false
    var already: Bool { store.play.stickerDay == CircleStore.dayKey() }
    var body: some View {
        CreativePage(title: "今天的小惊喜", subtitle: "每天一张免费贴纸，收集一点小可爱。") {
            if already || opened {
                TuantuanSticker(pose: store.play.dailySticker).frame(height: 255).frame(maxWidth: .infinity)
                Text("今天的团团，已经放进收藏啦").font(.title3.bold()).frame(maxWidth: .infinity)
                PrimaryButton(title: sent ? "已放进聊天" : "把可爱发进聊天", symbol: "paperplane") { store.sendSticker(pose: store.play.dailySticker, caption: "送你今天的小可爱"); sent = true }.disabled(sent).accessibilityIdentifier("sendDailySticker")
                NavigationLink(value: Screen.stickers) { Text("去看看我的贴纸收藏").frame(maxWidth: .infinity, minHeight: 44) }
                Text("今天已经拆过啦，明天再来遇见小惊喜。重复进入不会重复领取。").font(.caption).foregroundStyle(Palette.muted)
            } else {
                MiniIllustration(index: 7).frame(height: 245).frame(maxWidth: .infinity)
                PaperCard(color: Palette.lavender) { Text("团团为你藏好了一张小贴纸，\n要不要现在拆开？").font(.title3.bold()).lineSpacing(9) }
                PrimaryButton(title: "拆开今天的小惊喜", symbol: "gift.fill") { _ = store.takeDailySticker(); opened = true }.accessibilityIdentifier("openDailySticker")
            }
            Text("开发版为6款原创贴纸随机赠送，无付费抽取、无现金价值。").font(.caption2).foregroundStyle(Palette.muted)
        }
    }
}
struct KeywordsView: View {
    @EnvironmentObject var store: CircleStore
    @State private var word = ""
    @State private var effect = 0
    @State private var preview: Int?
    private let names = ["飘一点爱心", "闪一下星星", "团团来踩踩"]
    var body: some View {
        CreativePage(title: "只有我们懂的暗号", subtitle: "一句平常的话，也可以有一点小魔法。") {
            if let preview { KeywordCelebration(effect: preview).frame(height: 100) }
            ForEach(store.play.keywords) { item in Surface { HStack { VStack(alignment: .leading, spacing: 7) { Text("“\(item.word)”").font(.headline); Text(names[item.effect]).font(.caption).foregroundStyle(Palette.muted) }; Spacer(); Button("预览") { show(item.effect) }; Button { store.updatePlay { $0.keywords.removeAll { $0.id == item.id } } } label: { Image(systemName: "minus.circle").frame(width: 40, height: 44) }.accessibilityLabel("删除暗号\(item.word)") } } }
            PaperCard(color: Palette.lavender) {
                VStack(alignment: .leading, spacing: 15) {
                    TextField("写一个小暗号，最多12字", text: $word).padding(13).background(.white, in: Capsule()).onChange(of: word) { _, v in if v.count > 12 { word = String(v.prefix(12)) } }.accessibilityIdentifier("keywordWord")
                    Picker("小魔法", selection: $effect) { ForEach(0..<3) { Text(names[$0]).tag($0) } }.pickerStyle(.menu)
                    Button("收好这个暗号") { let value = word.trimmingCharacters(in: .whitespacesAndNewlines); store.updatePlay { $0.keywords.append(ChatKeyword(word: value, effect: effect)) }; word = ""; show(effect) }.disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.play.keywords.count >= 12 || store.play.keywords.contains { $0.word == word.trimmingCharacters(in: .whitespacesAndNewlines) }).accessibilityIdentifier("saveKeyword")
                }
            }
            Text("在聊天发送包含暗号的文字，会在本机出现一次小特效。关闭互动动画或开启系统减弱动态效果时，将不播放。").font(.caption).foregroundStyle(Palette.muted)
        }
    }
    func show(_ i: Int) { preview = i; DispatchQueue.main.asyncAfter(deadline: .now() + 2) { preview = nil } }
}
struct KeywordCelebration: View {
    let effect: Int
    @State private var rise = false
    var body: some View {
        HStack(spacing: 22) { ForEach(0..<5) { i in Image(systemName: ["heart.fill", "sparkle", "pawprint.fill"][min(2, max(0, effect))]).font(.system(size: CGFloat(22 + (i % 3) * 8))).foregroundStyle([Palette.rose, Color(hex: 0xD9A546), Palette.teal][min(2, max(0, effect))]).rotationEffect(.degrees(Double(i * 13 - 26))).offset(y: rise ? CGFloat(-25 - (i % 2) * 24) : 30).opacity(rise ? 1 : 0.1) } }.frame(maxWidth: .infinity, maxHeight: .infinity).allowsHitTesting(false).accessibilityHidden(true).onAppear { withAnimation(.easeOut(duration: 0.7)) { rise = true } }
    }
}
struct HeartMomentView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var warm = false
    var body: some View {
        CreativePage(title: "想你这件小事") {
            TuantuanSticker(pose: 0).frame(height: 230).frame(maxWidth: .infinity)
            Text("把手指放在这里\n留一点温柔给今天").font(.title2.bold()).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            Button { store.poke(); if store.state.haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }; withAnimation(reduceMotion ? nil : .spring()) { warm = true } } label: { Image(systemName: "heart.fill").font(.system(size: 65)).foregroundStyle(.white).frame(width: 155, height: 155).background(Palette.rose.gradient, in: Circle()).scaleEffect(warm ? 1.05 : 1) }.frame(maxWidth: .infinity).accessibilityIdentifier("heartTouch")
            Text("这个空间里，记录了 \(store.current.pokes) 次想念").font(.headline).frame(maxWidth: .infinity)
            ConnectionNote(text: "当前只记录本机触碰。两人同时按住的互动，需要连接两台设备后开放。")
        }
    }
}
