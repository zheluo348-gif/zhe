import SwiftUI

@main struct XiaoXiaoQuanApp: App {
    @StateObject private var store = CircleStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store) } }
}
enum Screen: String, Hashable { case chat, wishes, room, pet, question, wall, status, spaces, inspiration, stickers, tuantuan, games, comic, expression, aiSettings, sharing, habits, habitReport, agreements, rewards, capsules, calendar, expenses, modules, wardrobe, surprise, keywords, heart, gomoku, truth, story, drawGuess, wheel, annual, achievements, music, privacy, invitation, growth, memoryGallery, profileEditor }
struct RootView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var path: [Screen] = []
    var body: some View {
        Group {
            if !store.state.entered { WelcomeView() }
            else {
                NavigationStack(path: $path) {
                    ZStack {
                        store.background.ignoresSafeArea()
                        switch tab {
                        case 1: PlayfulChatView(onBack: { tab = 0 })
                        case 2: MemoriesView()
                        case 3: ProfileView()
                        default: PlaygroundHomeView(open: { path.append($0) })
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if tab != 1 { tabBar }
                    }
                    .navigationDestination(for: Screen.self) { screen in
                        Group {
                            switch screen {
                            case .chat: PlayfulChatView()
                            case .wishes: WishesView()
                            case .room: IllustratedRoomView()
                            case .pet: PetPlayView()
                            case .question: QuestionView()
                            case .wall: WallView()
                            case .status: StatusView()
                            case .spaces: MySpacesView()
                            case .inspiration: InspirationView()
                            case .stickers: StickerStudioView()
                            case .tuantuan: TuantuanPlayView()
                            case .games: GameHubView()
                            case .comic: MemoryComicView()
                            case .expression: ExpressionView()
                            case .aiSettings: AISettingsView()
                            case .sharing: SharingPreferencesView()
                            case .habits: HabitsView()
                            case .habitReport: HabitReportView()
                            case .agreements: AgreementsView()
                            case .rewards: RewardsView()
                            case .capsules: CapsulesView()
                            case .calendar: CircleCalendarView()
                            case .expenses: ExpensesView()
                            case .modules: AllPlaygroundsView()
                            case .wardrobe: WardrobeView()
                            case .surprise: DailySurpriseView()
                            case .keywords: KeywordsView()
                            case .heart: HeartMomentView()
                            case .gomoku: GomokuView()
                            case .truth: TruthCardsView()
                            case .story: StoryRelayView()
                            case .drawGuess: DrawGuessView()
                            case .wheel: DecisionWheelView()
                            case .annual: AnnualRecapView()
                            case .achievements: AchievementsView()
                            case .music: TogetherMusicView()
                            case .privacy: PrivacyAndExitView()
                            case .invitation: InvitationPreviewView()
                            case .growth: GrowthJourneyView()
                            case .memoryGallery: MemoriesView()
                            case .profileEditor: ProfileEditorView()
                            }
                        }.toolbarBackground(screen == .room ? Palette.night : store.background, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(screen == .room ? .dark : .light, for: .navigationBar).tint(screen == .room ? .white : store.accent)
                    }
                }.id(store.state.mode)
            }
        }.fontDesign(.rounded).foregroundStyle(Palette.ink).tint(store.accent).preferredColorScheme(path.last == .room ? .dark : .light)
            .onAppear { store.recordVisit() }
            .onChange(of: store.state.entered) { _, entered in if entered { store.recordVisit() } }
            .onChange(of: store.state.mode) { _, _ in store.recordVisit() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { store.recordVisit() } }
            .onReceive(NotificationCenter.default.publisher(for: .circleOpenChat)) { _ in path = []; tab = 1 }
            .onReceive(NotificationCenter.default.publisher(for: .circleOpenHome)) { _ in path = []; tab = 0 }
            .alert("保存提示", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) { Button("重试") { store.persist() } } message: { Text(store.saveError ?? "") }
    }
    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { i in
                let names = [store.friends ? "小窝" : "首页", store.friends ? "群聊" : "聊天", "回忆", "我的"]
                let icons = ["house", "bubble.left", "photo.on.rectangle", "person.crop.circle"]
                Button { tab = i } label: {
                    VStack(spacing: 5) { Image(systemName: icons[i] + (tab == i && i == 0 ? ".fill" : "")).font(.system(size: 21, weight: .regular)); Text(names[i]).font(.system(size: 11, weight: tab == i ? .semibold : .regular)) }
                        .foregroundStyle(tab == i ? store.accent : Palette.muted).frame(maxWidth: .infinity).frame(height: 55).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("tab_\(i)")
            }
        }.padding(.horizontal, 8).padding(.top, 8).background(.white).overlay(alignment: .top) { Rectangle().fill(Palette.border).frame(height: 0.5) }
    }
}
struct WelcomeView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        ZStack { Palette.cream.ignoresSafeArea(); ScrollView { VStack(alignment: .leading, spacing: 26) {
            HStack { Image(systemName: "heart.circle.fill").font(.system(size: 34)).foregroundStyle(Palette.rose); Text("小小圈").font(.title3.bold()); Spacer(); Pill(text: "原生体验版") }.padding(.top, 30)
            Text("把日子过成\n我们的小故事。").font(.system(size: 34, weight: .bold)).lineSpacing(8)
            Text("给彼此留一点位置，\n分享小事，也收藏那些值得记住的时刻。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(5)
            SunsetArt().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 28))
            PrimaryButton(title: "进入小小圈", symbol: "heart.fill") { store.enter("couple") }.accessibilityIdentifier("enterCircle")
            Text("只显示你加入的空间。创建、加入和管理，都在“我的 → 我的空间”。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
            HStack(alignment: .top, spacing: 8) { Image(systemName: "iphone"); Text("这是本机体验版。人物和历史内容为示例；你的操作保存在此设备，尚未连接其他用户。").lineSpacing(4) }.font(.caption).foregroundStyle(Palette.muted)
        }.padding(26) } }
    }
}
struct HomeView: View {
    @EnvironmentObject var store: CircleStore
    var open: (Screen) -> Void
    @State private var pokeAnimation = false
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    if !store.friends { HStack(spacing: -8) { Avatar(name: "小糖"); Avatar(name: "哲", color: Color(hex: 0xE6DDD5)) } }
                    VStack(alignment: .leading, spacing: 4) {
                        if store.friends { Text("闺蜜小窝").font(.caption).foregroundStyle(Palette.muted) }
                        Text(store.spaceName).font(.title3.bold()).foregroundStyle(Palette.ink)
                        if !store.friends { Text("我们的小空间").font(.caption).foregroundStyle(Palette.muted) }
                    }
                    Spacer(minLength: 5)
                    NavigationLink { ProfileView() } label: { Image(systemName: "gearshape").font(.title3).foregroundStyle(Palette.ink).frame(width: 42, height: 42).background(.white, in: Circle()) }
                }.padding(.top, 8)
                HStack(spacing: 6) { Circle().fill(store.accent).frame(width: 5, height: 5); Text("本机体验 · 内容独立保存").font(.caption2); Spacer(); Text(store.friends ? "闺蜜示例" : "情侣示例").font(.caption2) }.foregroundStyle(Palette.muted)
                if store.friends { friendsHome } else { coupleHome }
                NavigationLink(value: Screen.inspiration) { PaperCard(color: Palette.lavender) { HStack { VStack(alignment: .leading, spacing: 7) { Text("今天一起玩点什么？").font(.headline); Text("团团 · 心情贴纸 · 默契小游戏").font(.caption).foregroundStyle(Palette.muted) }; Spacer(); TuantuanSticker(pose: 4).frame(width: 75, height: 75) } } }.buttonStyle(.plain).accessibilityIdentifier("homeInspiration")
                HStack(spacing: 12) {
                    Button { open(.room) } label: { Surface(padding: 12) { IconTile(icon: "sofa.fill", title: "小房间", subtitle: "陪你坐一会", color: store.accent) } }.accessibilityIdentifier("homeRoom")
                    Button { open(.wishes) } label: { Surface(padding: 12) { IconTile(icon: "list.bullet", title: "愿望清单", subtitle: "一起慢慢完成", color: store.accent) } }.accessibilityIdentifier("homeWishes")
                }.buttonStyle(.plain)
            }.padding(.horizontal, 20).padding(.bottom, 20)
        }.scrollIndicators(.hidden)
    }
    var coupleHome: some View {
        Group {
            SofaBanner().clipShape(RoundedRectangle(cornerRadius: 23))
            VStack(alignment: .leading, spacing: 12) {
                Text("我们在一起已经").font(.subheadline).foregroundStyle(.white.opacity(0.85))
                HStack(alignment: .firstTextBaseline, spacing: 5) { Text("\(store.togetherDays)").font(.system(size: 60, weight: .bold, design: .rounded)); Text("天").font(.title3.bold()) }.foregroundStyle(.white)
                HStack { Text("恋爱 \(store.nextAnniversary.years) 周年"); Spacer(); Text(store.nextAnniversary.days == 0 ? "就是今天" : "还有 \(store.nextAnniversary.days) 天").bold() }.font(.subheadline).foregroundStyle(.white).padding(12).background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 13))
            }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(LinearGradient(colors: [Palette.rose, Color(hex: 0xAE355F)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 25))
            Button {
                store.poke(); withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { pokeAnimation = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { pokeAnimation = false } }
            } label: {
                Surface { HStack(spacing: 15) {
                    Image(systemName: "heart.fill").font(.system(size: 26)).foregroundStyle(Palette.rose).frame(width: 58, height: 58).background(Palette.pink, in: Circle()).scaleEffect(pokeAnimation ? 1.18 : 1)
                    VStack(alignment: .leading, spacing: 6) { Text("想你了").font(.headline); Text(store.current.pokes == 0 ? "轻点，留一个小心意" : "已在本机记录 \(store.current.pokes) 次想念").font(.caption).foregroundStyle(Palette.muted) }
                    Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.muted)
                } }
            }.buttonStyle(.plain).accessibilityIdentifier("pokeButton")
            Button { open(.question) } label: {
                Surface { VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("每日一问").font(.subheadline.bold()).foregroundStyle(Palette.rose); Spacer(); Pill(text: store.current.answer.isEmpty ? "等你回答" : "已揭晓") }
                    Text("如果明天放假，你想一起去哪？").font(.headline).multilineTextAlignment(.leading)
                    HStack(spacing: 7) { Image(systemName: store.current.answer.isEmpty ? "lock" : "checkmark.circle"); Text(store.current.answer.isEmpty ? "留下答案，一起翻开今天" : "看看你们的答案") }.font(.caption).foregroundStyle(Palette.muted).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Palette.cream, in: RoundedRectangle(cornerRadius: 12))
                } }
            }.buttonStyle(.plain).accessibilityIdentifier("dailyQuestion")
            Button { open(.status) } label: { Surface(padding: 15) { HStack { Avatar(name: "小糖", size: 38); VStack(alignment: .leading, spacing: 5) { Text("我的此刻").font(.subheadline.bold()); Text(store.current.status.isEmpty ? "分享一个心情或状态" : store.current.status).font(.subheadline).foregroundStyle(Palette.teal) }; Spacer(); Image(systemName: "square.and.pencil").foregroundStyle(Palette.muted) } } }.buttonStyle(.plain)
        }
    }
    var friendsHome: some View {
        Group {
            Surface(padding: 15) { VStack(alignment: .leading, spacing: 13) {
                HStack { Text("成员").font(.subheadline.bold()); Spacer(); Text("6 / 8").font(.subheadline.bold()).foregroundStyle(Palette.teal) }
                HStack(spacing: 6) {
                    ForEach(Array(["柚", "小糖", "桃", "糖", "栗", "朵"].enumerated()), id: \.offset) { i, n in Avatar(name: n, color: [Color(hex: 0xD5EAE7), Palette.pink, Color(hex: 0xF2E6C5), Palette.lavender][i % 4], size: 31) }
                    ForEach(0..<2) { _ in Image(systemName: "plus").font(.caption).foregroundStyle(Palette.teal).frame(width: 29, height: 29).overlay(Circle().strokeBorder(Palette.teal.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3]))) }
                }
                Text("邀请与审批将在联网版本开放").font(.caption2).foregroundStyle(Palette.muted)
            } }
            VStack(alignment: .leading, spacing: 14) {
                HStack { VStack(alignment: .leading, spacing: 5) { Text("今日随手拍").font(.title3.bold()); Text("分享一点普通又可爱的日常").font(.caption).opacity(0.85) }; Spacer(); Image(systemName: "camera") }.foregroundStyle(.white)
                HStack(spacing: 9) {
                    let recent = Array(store.current.memories.filter { $0.attachment != nil }.prefix(3))
                    ForEach(0..<3) { i in
                        VStack(alignment: .leading, spacing: 6) {
                            Group {
                                if i < recent.count, let name = recent[i].attachment, let image = store.photo(named: name) { Image(uiImage: image).resizable().scaledToFill() }
                                else { SunsetArt(theme: ["sunset", "coffee", "sunset"][i]) }
                            }.frame(height: 110).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                            Text(i < recent.count ? "我的分享" : ["柚柚 · 示例", "桃桃 · 示例", "糖糖 · 示例"][i]).font(.caption2).foregroundStyle(.white.opacity(0.9))
                        }.frame(maxWidth: .infinity)
                    }
                }
                Button { open(.status) } label: { Label("分享我的此刻", systemImage: "camera").font(.subheadline.bold()).foregroundStyle(Palette.teal).frame(maxWidth: .infinity).padding(13).background(.white, in: Capsule()) }
            }.padding(18).background(Palette.teal, in: RoundedRectangle(cornerRadius: 23))
            Surface { PollContent() }
            Surface(padding: 15) { HStack { VStack(spacing: 1) { Text("11月").font(.caption2); Text("02").font(.title3.bold()) }.foregroundStyle(Palette.rose).frame(width: 46, height: 48).background(Palette.pink, in: RoundedRectangle(cornerRadius: 13)); VStack(alignment: .leading, spacing: 5) { Text("柚柚生日").font(.subheadline.bold()); Text("一起准备一份小惊喜 · 示例").font(.caption).foregroundStyle(Palette.muted) }; Spacer() } }
            Button { open(.wall) } label: { Surface(padding: 14) { IconTile(icon: "star.fill", title: "梗墙", subtitle: "收藏我们的名场面", color: Color(hex: 0xB48132)) } }.buttonStyle(.plain)
        }
    }
}
