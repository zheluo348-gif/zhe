import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct AchievementsView: View {
    @EnvironmentObject var store: CircleStore
    var badges: [(String, String, Bool)] { [
        ("第一句心意", "发送一条自己的新消息", store.play.awarded.contains("firstMessage")),
        ("小习惯发芽", "完成任意一个今日目标", store.play.awarded.contains { $0.hasPrefix("habit:") }),
        ("说到做到", "完成一张小约定", store.play.agreements.contains { $0.state == "已完成" }),
        ("未来邮差", "封好一封时光胶囊", !store.play.capsules.isEmpty),
        ("团团的朋友", "陪团团玩一次", store.current.petLog.count > 1),
        ("贴纸收藏家", "收藏至少三张贴纸", store.creative.stickers.count >= 3),
        ("一起编故事", "接龙写下至少三句", store.play.story.count >= 3),
        ("小小棋手", "下完一局五子棋", store.play.gomoku.winner > 0 || store.play.gomoku.draw)
    ] }
    var body: some View {
        CreativePage(title: "我们的小小成就", subtitle: "没有排行榜，只收藏一起发生过的小事。") {
            HStack { MiniIllustration(index: 10).frame(width: 100, height: 100); VStack(alignment: .leading, spacing: 8) { Text("点亮 \(badges.filter { $0.2 }.count) / \(badges.count)").font(.title2.bold()); Text("每一颗星星都有来处").font(.caption).foregroundStyle(Palette.muted) } }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(Array(badges.enumerated()), id: \.offset) { i, badge in VStack(spacing: 12) { MiniIllustration(index: 10).frame(height: 88).saturation(badge.2 ? 1 : 0).opacity(badge.2 ? 1 : 0.35); Text(badge.0).font(.headline); Text(badge.1).font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center).frame(minHeight: 32); Text(badge.2 ? "已经点亮" : "等一个小瞬间").font(.caption.bold()).foregroundStyle(badge.2 ? Palette.rose : Palette.muted) }.padding(15).frame(maxWidth: .infinity).background(badge.2 ? Palette.pink.opacity(0.6) : .white, in: RoundedRectangle(cornerRadius: 20)) }
            }
            Text("按当前空间本机记录点亮；部分历史内容为体验样例，正式账号会从真实记录开始。").font(.caption).foregroundStyle(Palette.muted)
        }
    }
}
struct AnnualRecapView: View {
    @EnvironmentObject var store: CircleStore
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var shared = false
    var messages: Int { store.current.messages.filter { Calendar.current.component(.year, from: $0.date) == year }.count }
    var memories: Int { store.current.memories.filter { Calendar.current.component(.year, from: $0.date) == year }.count }
    var checks: Int { store.play.habits.reduce(0) { total, habit in total + habit.counts.filter { $0.key.hasPrefix("\(year)-") && $0.value >= habit.goal }.count } }
    var body: some View {
        CreativePage(title: "这一年的小日常", subtitle: "不用宏大，也值得被好好记住。") {
            Picker("年份", selection: $year) { ForEach((Calendar.current.component(.year, from: Date()) - 3)...Calendar.current.component(.year, from: Date()), id: \.self) { Text(String($0)).tag($0) } }.pickerStyle(.menu).onChange(of: year) { _, _ in shared = false }
            recap
            PrimaryButton(title: shared ? "已保存进回忆" : "把这一页收进回忆", symbol: "bookmark") {
                store.addMemory("\(year)年的小日常", note: "\(messages)条消息 · \(memories)条回忆 · \(checks)次目标完成\n本机统计，含体验样例。", kind: "年度回忆"); shared = true
            }.disabled(shared).accessibilityIdentifier("saveAnnualRecap")
            Text("只统计选定年份的本机消息、回忆与打卡目标完成记录，包含已有体验样例。还未产生的数据不会编造；AI回忆漫画待服务接通后另行生成。").font(.caption).foregroundStyle(Palette.muted)
        }
    }
    var recap: some View {
        PaperCard(color: Palette.lavender) {
            VStack(spacing: 24) {
                Text("\(String(year)) · \(store.spaceName)").font(.title3.bold())
                MiniIllustration(index: 8).frame(height: 175)
                Text("好多普通的小事\n拼成了我们的这一年").font(.title2.bold()).multilineTextAlignment(.center).lineSpacing(7)
                HStack { metric("\(messages)", "条小消息"); metric("\(memories)", "页回忆"); metric("\(checks)", "次目标完成") }
                Text("愿明年的日子，也有你在。").font(.caption).foregroundStyle(Palette.teal)
            }.frame(maxWidth: .infinity)
        }
    }
    func metric(_ number: String, _ name: String) -> some View { VStack(spacing: 9) { Text(number).font(.title.bold()).foregroundStyle(Palette.rose); Text(name).font(.caption) }.frame(maxWidth: .infinity) }
}
@MainActor final class LocalMusicPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var playing = false
    @Published var error: String?
    private var player: AVAudioPlayer?
    var duration: Double { player?.duration ?? 0 }
    var progress: Double { player?.currentTime ?? 0 }
    func load(_ url: URL) throws { player?.stop(); playing = false; let next = try AVAudioPlayer(contentsOf: url); next.delegate = self; next.prepareToPlay(); player = next }
    func toggle() { guard let player else { return }; if player.isPlaying { player.pause(); playing = false } else { if player.currentTime >= player.duration { player.currentTime = 0 }; playing = player.play() } }
    func seek(_ time: Double) { player?.currentTime = time }
    func stop() { player?.pause(); playing = false }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { Task { @MainActor in self.playing = false } }
}
struct TogetherMusicView: View {
    @EnvironmentObject var store: CircleStore
    @StateObject private var audio = LocalMusicPlayer()
    @State private var importing = false
    @State private var error: String?
    private var directory: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(ProcessInfo.processInfo.arguments.contains("--uitesting") ? "TestMusic" : "CircleMusic", isDirectory: true) }
    var body: some View {
        CreativePage(title: "给小窝一点声音", subtitle: "导入一段自己的音频，坐下来听一会。") {
            MiniIllustration(index: 9).frame(height: 235).frame(maxWidth: .infinity)
            Text(store.play.musicTitle ?? "还没有放进音乐").font(.title3.bold()).frame(maxWidth: .infinity)
            if store.play.musicFile != nil {
                TimelineView(.periodic(from: .now, by: 0.3)) { _ in VStack(spacing: 9) {
                    Slider(value: Binding(get: { audio.progress }, set: { audio.seek($0) }), in: 0...max(1, audio.duration)).tint(Palette.rose).accessibilityIdentifier("musicProgress")
                    HStack { Text(time(audio.progress)); Spacer(); Text(time(audio.duration)) }.font(.caption.monospacedDigit()).foregroundStyle(Palette.muted)
                } }
                PrimaryButton(title: audio.playing ? "暂停一下" : "开始听", symbol: audio.playing ? "pause.fill" : "play.fill") { audio.toggle() }.accessibilityIdentifier("playMusic")
            }
            Button { importing = true } label: { Label("从文件导入音频", systemImage: "folder").frame(maxWidth: .infinity, minHeight: 48) }.accessibilityIdentifier("importMusic")
            ConnectionNote(text: "当前在本机播放，不会同步对方进度。联网一起听和音乐平台授权尚未接入。")
            Text("可以导入自己有权使用的 m4a、mp3、wav 等音频，单个文件最多30MB。离开页面会暂停。").font(.caption).foregroundStyle(Palette.muted)
        }.onAppear { load() }.onDisappear { audio.stop() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.audio]) { result in
                do {
                    let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size > 0 && size <= 30 * 1024 * 1024 else { error = "请选择30MB以内的有效音频。"; return }
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    let name = UUID().uuidString + "." + url.pathExtension.lowercased(); let target = directory.appendingPathComponent(name)
                    try FileManager.default.copyItem(at: url, to: target)
                    do { try audio.load(target) } catch { try? FileManager.default.removeItem(at: target); throw error }
                    let previous = store.play.musicFile
                    store.updatePlay { $0.musicFile = name; $0.musicTitle = String(url.deletingPathExtension().lastPathComponent.prefix(80)) }
                    if let previous, previous != name { try? FileManager.default.removeItem(at: directory.appendingPathComponent(previous)) }
                } catch { self.error = "这段音频无法读取或播放，请换一个文件重试。" }
            }.alert("音频未添加", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了") {} } message: { Text(error ?? "") }
    }
    func load() { guard let name = store.play.musicFile, !name.contains("/"), !name.contains("..") else { return }; do { try audio.load(directory.appendingPathComponent(name)) } catch { self.error = "之前的音频暂时无法打开，请重新导入。" } }
    func time(_ seconds: Double) -> String { String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60) }
}
struct PrivacyAndExitView: View {
    @EnvironmentObject var store: CircleStore
    @State private var leaving = false
    @State private var export: URL?
    @State private var error: String?
    var body: some View {
        CreativePage(title: "安心待在小圈里", subtitle: "自己的记录和分享，由自己决定。") {
            Surface { VStack(alignment: .leading, spacing: 15) {
                Label("本机保存", systemImage: "lock.shield").font(.headline)
                Text("这个开发版没有登录服务器。聊天、胶囊、照片和小游戏记录保存在此设备，AI不会自动读取聊天。").font(.subheadline).lineSpacing(7)
                Text("还没有接入远程消息与推送，因此暂不提供已读回执、通知预览或免打扰开关，避免让未生效的设置造成误解。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(6)
            } }
            NavigationLink(value: Screen.sharing) { Label("管理电量与天气分享意愿", systemImage: "battery.75percent").frame(minHeight: 44) }
            NavigationLink(value: Screen.aiSettings) { Label("查看AI内容范围与动画设置", systemImage: "sparkles").frame(minHeight: 44) }
            PrimaryButton(title: "准备导出本机文字记录", symbol: "square.and.arrow.up") {
                do {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("小小圈文字备份-\(store.state.mode).json")
                    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
                    try encoder.encode(store.current.exportableCopy).write(to: url, options: .atomic); export = url
                } catch { self.error = "备份文件没有准备成功，请重试。" }
            }.accessibilityIdentifier("prepareExport")
            if let export { ShareLink(item: export) { Label("选择备份保存位置", systemImage: "folder").frame(maxWidth: .infinity, minHeight: 48) } }
            Text("导出当前空间文字与记录信息，包含一起续画的笔迹数据；不包含阅后即焚消息、独立照片和音频文件，也不是云备份。文件中包含私密信件内容，请自行选择保存位置。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(6)
            Button("暂时离开这个本机空间") { leaving = true }.foregroundStyle(Palette.rose).frame(maxWidth: .infinity, minHeight: 48).accessibilityIdentifier("leaveSpace")
            Text("离开会从“我的空间”列表移除，保留本机记录；重新添加本机体验空间后仍可查看。真实解绑、删除账号与云端数据处理将在联网版实现。").font(.caption).foregroundStyle(Palette.muted)
        }.confirmationDialog("离开“\(store.spaceName)”？本机记录会保留。", isPresented: $leaving, titleVisibility: .visible) { Button("保留记录并离开", role: .destructive) { store.localExitSpace(); NotificationCenter.default.post(name: .circleOpenHome, object: nil) } }
            .alert("导出未完成", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了") {} } message: { Text(error ?? "") }
    }
}
struct InvitationPreviewView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        CreativePage(title: "给你留了一个位置", subtitle: "邀请卡的样式先准备好，等联网后一起入住。") {
            PaperCard(color: store.friends ? Palette.mint : Palette.pink) {
                VStack(spacing: 23) {
                    TuantuanSticker(pose: 0).frame(height: 180)
                    Text(store.friends ? "小窝还差你的可爱" : "想和你拥有一个小小圈").font(.title2.bold()).multilineTextAlignment(.center)
                    Text(store.friends ? "最多8人 · 只和熟悉的人分享" : "只容纳两个人的日常").font(.subheadline).foregroundStyle(Palette.muted)
                    Label("邀请样式预览 · 暂不可加入", systemImage: "envelope").font(.caption.bold()).foregroundStyle(Palette.rose)
                }.frame(maxWidth: .infinity)
            }
            ConnectionNote(text: "真实邀请码、成员申请与双方确认，需要账号和服务器。此处不生成无法使用的假邀请码。")
        }
    }
}
