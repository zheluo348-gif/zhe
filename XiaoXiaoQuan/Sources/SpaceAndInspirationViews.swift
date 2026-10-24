import SwiftUI

struct MySpacesView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    var body: some View {
        CreativePage(title: "我的空间", subtitle: "把重要的人，放进自己的小小圈。") {
            ForEach(store.state.joinedSpaces ?? ["couple"], id: \.self) { mode in
                Button {
                    store.selectSpace(mode); NotificationCenter.default.post(name: .circleOpenHome, object: nil)
                } label: {
                    PaperCard(color: mode == "couple" ? Palette.pink : Color(hex: 0xDDEEE9)) {
                        HStack(spacing: 15) {
                            Image(systemName: mode == "couple" ? "heart.fill" : "person.3.fill")
                                .font(.title).foregroundStyle(mode == "couple" ? Palette.rose : Palette.teal)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(store.spaceName(for:mode)).font(.title3.bold())
                                Text(mode == "couple" ? "2人小空间 · 本机体验" : "6 / 8 人 · 本机体验").font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            if store.state.mode == mode { Pill(text: "当前空间", color: store.accent) }
                            else { Image(systemName: "arrow.right") }
                        }
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("space_\(mode)")
                    .accessibilityValue(store.state.mode == mode ? "已选择" : "未选择")
            }
            Button { adding = true } label: {
                Label("创建或加入空间", systemImage: "plus.circle").font(.headline)
                    .frame(maxWidth: .infinity).frame(minHeight: 62)
                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(Palette.rose.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5])))
            }.buttonStyle(.plain).foregroundStyle(Palette.rose).accessibilityIdentifier("createSpace")
            ConnectionNote(text: "当前为本机空间；邀请与成员确认将在联网后开放。")
        }.sheet(isPresented: $adding) {
            NavigationStack { CreativePage(title: "建立一个小圈子", subtitle: "只和你选择的人，一起分享日常。") {
                TuantuanSticker(pose: 0).frame(height: 160).frame(maxWidth: .infinity)
                if !(store.state.joinedSpaces ?? []).contains("friends") {
                    PrimaryButton(title: "体验闺蜜小窝（最多8人）", symbol: "person.3.fill", color: Palette.teal) {
                        store.addLocalSpace("friends"); adding = false; NotificationCenter.default.post(name: .circleOpenHome, object: nil)
                    }.accessibilityIdentifier("joinFriendsDemo")
                }
                if !(store.state.joinedSpaces ?? []).contains("couple") {
                    PrimaryButton(title: "体验两人空间", symbol: "heart.fill") { store.addLocalSpace("couple"); adding = false; NotificationCenter.default.post(name: .circleOpenHome, object: nil) }
                }
                Text("此按钮建立独立的本机体验空间，不会邀请或绑定真实联系人。真实加入需双方确认。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(6)
            }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { adding = false } } } }
            .presentationDetents([.medium, .large])
        }
    }
}
struct InspirationView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        CreativePage(title: "想怎么玩？", subtitle: "挑一个灵感，让聊天多一点可爱。") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                NavigationLink(value: Screen.stickers) { ArtFeatureCard(title: "心情表情包", detail: "把想说的话变成贴纸", pose: 0, color: Palette.pink) }.accessibilityIdentifier("inspireStickers")
                NavigationLink(value: Screen.tuantuan) { ArtFeatureCard(title: "@团团", detail: "一起想点有趣的小事", pose: 5, color: Color(hex: 0xDEF0E8)) }.accessibilityIdentifier("inspireTuantuan")
                NavigationLink(value: Screen.games) { ArtFeatureCard(title: "默契小游戏", detail: "一起来点轻松好玩的", pose: 4, color: Palette.lavender) }.accessibilityIdentifier("inspireGames")
                NavigationLink(value: Screen.expression) { ArtFeatureCard(title: "帮我表达", detail: "把心里话说得更贴心", pose: 1, color: Color(hex: 0xF9ECD2)) }.accessibilityIdentifier("inspireExpression")
            }.buttonStyle(.plain)
            NavigationLink(value: Screen.comic) { Label("把今天画成三格漫画", systemImage: "rectangle.split.3x1").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20)) }
            AIAvailabilityNote()
        }
    }
}
struct AISettingsView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        CreativePage(title: "AI 使用设置") {
            HStack {
                Text("每次由你选择\n交给 AI 的内容").font(.system(size: 26, weight: .bold)).lineSpacing(7)
                Spacer(); TuantuanSticker(pose: 1).frame(width: 115, height: 130)
            }
            Surface { VStack(alignment:.leading,spacing:12) {
                Toggle("开启AI灵感",isOn:Binding(get:{store.isAIEnabled},set:{store.setAIEnabled($0)})).tint(Palette.rose).accessibilityIdentifier("aiEnabledToggle")
                Text(store.isAIEnabled ? "需要时主动调用，团团不会自动插话。服务尚未配置，现在不会产生模型调用。":"当前是基础玩法：聊天、抱抱、画画、小游戏、喂团团和壁纸解锁都能用，不需要AI。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(6)
                Text("这个开关只表示你的选择，不会自动购买、订阅或扣费。正式接入后的额度与价格需在调用前明确展示。").font(.caption).foregroundStyle(Palette.muted)
            } }
            Surface { VStack(alignment: .leading, spacing: 19) {
                Label("调用前预览内容", systemImage: "eye").font(.headline)
                Text("每次确认，不自动提交聊天记录。当前图片请求接口只预留了文字描述；照片上传与授权流程还未接入。").font(.subheadline).foregroundStyle(Palette.muted)
                Divider()
                row("自动读取完整聊天", detail: "不启用")
                row("团团插话方式", detail: "仅点击或 @ 时")
                row("共同回忆生成", detail: "成员确认后")
            } }
            Surface { Toggle("播放互动动画", isOn: Binding(get: { store.creative.animations }, set: { value in store.updateCreative { $0.animations = value } })).tint(Palette.rose) }
            ConnectionNote(text: "当前未接入 AI 服务，本机体验不会把聊天或照片发送给模型。")
        }
    }
    func row(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.subheadline.bold()); Text(detail).font(.caption).foregroundStyle(Palette.muted) }
    }
}
struct InspirationDrawer: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            InspirationView()
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
                .navigationDestination(for: Screen.self) { screen in
                    switch screen {
                    case .stickers: StickerStudioView()
                    case .tuantuan: TuantuanPlayView()
                    case .games: GameHubView()
                    case .expression: ExpressionView()
                    case .aiSettings: AISettingsView()
                    case .comic: MemoryComicView()
                    case .gomoku: GomokuView()
                    case .truth: TruthCardsView()
                    case .story: StoryRelayView()
                    case .drawGuess: DrawGuessView()
                    case .wheel: DecisionWheelView()
                    default: InspirationView()
                    }
                }
        }
        .presentationDetents([.fraction(0.84), .large]).presentationDragIndicator(.visible)
        .onReceive(NotificationCenter.default.publisher(for: .circleOpenChat)) { _ in dismiss() }
        .onReceive(NotificationCenter.default.publisher(for: .circleOpenHome)) { _ in dismiss() }
    }
}
struct SharingPreferencesView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        CreativePage(title: "分享我的状态", subtitle: "每一项分享，都由你自己决定。") {
            Surface { VStack(alignment: .leading, spacing: 20) {
                Toggle("分享电量与充电状态", isOn: Binding(get: { store.creative.shareBattery }, set: { v in store.updateCreative { $0.shareBattery = v } })).tint(Palette.rose)
                Toggle("分享城市天气", isOn: Binding(get: { store.creative.shareWeather }, set: { v in store.updateCreative { $0.shareWeather = v } })).tint(Palette.teal)
                TextField("手动填写城市", text: Binding(get: { store.creative.city }, set: { v in store.updateCreative { $0.city = String(v.prefix(30)) } })).padding(12).background(Palette.cream, in: RoundedRectangle(cornerRadius: 12))
            } }
            Text("以上只保存分享偏好。当前尚未读取或同步设备电量，也未接入天气服务；首页不会用示例数字冒充对方状态。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(6)
        }
    }
}

