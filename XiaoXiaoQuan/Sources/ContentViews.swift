import SwiftUI
import PhotosUI

struct ChatView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    @State private var text = ""
    @State private var reply: String?
    @State private var toast: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @State private var loadingPhoto = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { if let onBack { onBack() } else { dismiss() } } label: { Image(systemName: "chevron.left").font(.title3).frame(width: 32, height: 42) }.accessibilityLabel("返回首页")
                Avatar(name: store.friends ? "六" : "哲", color: store.friends ? Color(hex: 0xD5EAE7) : Color(hex: 0xE6DDD5), size: 40)
                VStack(alignment: .leading, spacing: 4) { Text(store.friends ? store.spaceName : "阿哲").font(.headline); Text("本机聊天体验 · 尚未连接其他用户").font(.caption2).foregroundStyle(Palette.muted) }
                Spacer()
            }.padding(.horizontal, 10).padding(.vertical, 7).background(store.background)
            Rectangle().fill(Palette.border).frame(height: 0.5)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 17) {
                        Text("以下历史内容为示例，新消息仅保存在本机").font(.caption2).foregroundStyle(Palette.muted).padding(.vertical, 10)
                        ForEach(store.current.messages) { message in
                            messageRow(message).id(message.id)
                        }
                        if store.friends { Surface { PollContent() }.padding(.vertical, 4) }
                        if store.current.pokes > 0 { Text("♥ 你留下了 \(store.current.pokes) 次想念").font(.caption).foregroundStyle(store.accent).padding(9).background(store.accent.opacity(0.08), in: Capsule()) }
                        Color.clear.frame(height: 1).id("bottom")
                    }.padding(.horizontal, 17).padding(.bottom, 15)
                }.scrollDismissesKeyboard(.interactively).onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
                    .onChange(of: store.current.messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                    .onChange(of: focused) { _, value in if value { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } } } }
            }
        }.background(store.background)
            .onAppear { text = store.current.draft ?? "" }
            .onChange(of: text) { _, value in store.update { $0.draft = value } }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .top) { if let toast { Text(toast).font(.caption).foregroundStyle(.white).padding(12).background(Palette.ink.opacity(0.9), in: Capsule()).padding(.top, 70).allowsHitTesting(false) } }
            .alert("照片未添加", isPresented: Binding(get: { photoError != nil }, set: { if !$0 { photoError = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(photoError ?? "") }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }; loadingPhoto = true
                Task {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self) else { throw CocoaError(.fileReadCorruptFile) }
                        try store.sendPhoto(data)
                    } catch { photoError = "无法读取这张照片，请重新选择。" }
                    selectedPhoto = nil; loadingPhoto = false
                }
            }
    }
    func messageRow(_ m: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 9) {
            if m.mine { Spacer(minLength: 45) } else { Avatar(name: m.sender, color: store.friends ? Color(hex: 0xD5EAE7) : Color(hex: 0xE6DDD5), size: 32) }
            VStack(alignment: m.mine ? .trailing : .leading, spacing: 5) {
                if store.friends && !m.mine { Text(m.sender).font(.caption2).foregroundStyle(Palette.muted) }
                Group {
                    if let filename = m.attachment, let image = store.photo(named: filename) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 220, maxHeight: 260).clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        Text(m.text).font(.system(size: 16)).lineSpacing(4).padding(.horizontal, 15).padding(.vertical, 12).foregroundStyle(m.mine ? .white : Palette.ink).background(m.mine ? store.accent : .white, in: RoundedRectangle(cornerRadius: 18))
                    }
                }.contextMenu {
                    Button("回复", systemImage: "arrowshape.turn.up.left") { reply = m.text; focused = true }
                    Button(store.friends ? "上梗墙" : "存成回忆", systemImage: "bookmark") { store.addMemory(String(m.text.prefix(60)), note: "来自\(m.sender)的聊天", kind: m.attachment != nil ? "照片" : (store.friends ? "梗墙" : "小事"), attachment: m.attachment); flash("已保存到\(store.friends ? "梗墙" : "回忆")") }
                    if m.attachment == nil { Button("复制", systemImage: "doc.on.doc") { UIPasteboard.general.string = m.text } }
                    if m.mine { Button("删除本机消息", systemImage: "trash", role: .destructive) { store.update { $0.messages.removeAll { $0.id == m.id } } } }
                }
                Text(m.mine ? "本机保存" : "示例消息").font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
            if !m.mine { Spacer(minLength: 45) }
        }
    }
    var composer: some View {
        VStack(spacing: 9) {
            if let reply { HStack { Text("回复：\(reply)").lineLimit(1); Spacer(); Button { self.reply = nil } label: { Image(systemName: "xmark.circle.fill") } }.font(.caption).foregroundStyle(Palette.muted) }
            HStack(spacing: 9) {
                ForEach(store.friends ? ["拍一下", "哈哈", "晚安"] : ["抱抱", "想你了", "晚安"], id: \.self) { word in
                    Button { store.send(["抱抱": "🫂 给你一个抱抱", "想你了": "♥ 想你了", "晚安": "🌙 晚安，做个好梦", "拍一下": "👋 轻轻拍了拍大家", "哈哈": "哈哈哈哈 😄"][word] ?? word) } label: { Text(word).font(.caption).foregroundStyle(store.accent).padding(.horizontal, 13).padding(.vertical, 8).background(store.accent.opacity(0.08), in: Capsule()) }
                }
                Spacer()
            }
            HStack(alignment: .bottom, spacing: 10) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Group { if loadingPhoto { ProgressView() } else { Image(systemName: "photo.badge.plus").font(.title3) } }.frame(width: 38, height: 44) }.disabled(loadingPhoto).accessibilityLabel("添加照片")
                TextField("说点什么…", text: $text, axis: .vertical).font(.system(size: 16)).lineLimit(1...4).padding(.horizontal, 14).padding(.vertical, 12).background(.white, in: RoundedRectangle(cornerRadius: 23)).focused($focused).accessibilityIdentifier("messageInput").onChange(of: text) { _, value in if value.count > 2000 { text = String(value.prefix(2000)) } }
                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.send(reply.map { "回复「\($0.prefix(50))」\n" + trimmed } ?? trimmed); text = ""; reply = nil
                } label: { Image(systemName: "arrow.up").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white).frame(width: 44, height: 44).background(store.accent, in: Circle()) }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1).accessibilityIdentifier("sendMessage")
            }
        }.padding(.horizontal, 17).padding(.top, 10).padding(.bottom, 8).background(store.background).overlay(alignment: .top) { Rectangle().fill(Palette.border).frame(height: 0.5) }
    }
    func flash(_ value: String) { toast = value; DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } }
}

struct PollContent: View {
    @EnvironmentObject var store: CircleStore
    private let options = ["火锅", "日料", "烧烤"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("周六聚餐吃什么？").font(.headline); Spacer(); Text(store.current.vote == nil ? "5 人已投 · 示例" : "已记录你的选择").font(.caption2).foregroundStyle(Palette.muted) }
            ForEach(Array(options.enumerated()), id: \.offset) { i, item in
                let count = [3, 2, 0][i] + (store.current.vote == item ? 1 : 0)
                Button { store.update { $0.vote = item } } label: {
                    HStack {
                        Image(systemName: store.current.vote == item ? "checkmark.circle.fill" : "circle").foregroundStyle(Palette.teal)
                        Text(item).font(.subheadline.weight(.medium)); Spacer(); Text("\(count) 票").font(.subheadline.bold())
                    }.foregroundStyle(Palette.ink).padding(11).background(Palette.teal.opacity(store.current.vote == item ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain).accessibilityIdentifier("vote_\(i)")
            }
            Text("可改选 · 新投票仅在本机记录").font(.caption2).foregroundStyle(Palette.muted)
        }
    }
}

struct QuestionView: View {
    @EnvironmentObject var store: CircleStore
    @State private var answer = ""
    @State private var added = false
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 23) {
            Pill(text: "每日一问 · 第 128 题")
            Text("如果明天放假，\n你想一起去哪？").font(.system(size: 29, weight: .bold)).lineSpacing(8)
            Text("留下一句答案，收藏今天的小默契。").font(.subheadline).foregroundStyle(Palette.muted)
            if store.current.answer.isEmpty {
                Surface { TextField("写下你的答案…", text: $answer, axis: .vertical).lineLimit(4...7).accessibilityIdentifier("answerInput").onChange(of: answer) { _, value in if value.count > 300 { answer = String(value.prefix(300)) } } }
                PrimaryButton(title: "保存并揭晓示例答案") {
                    let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmed.isEmpty else { return }
                    store.answer(trimmed)
                    store.addMemory("如果明天放假，你想一起去哪？", note: "我的答案：\(trimmed)\n阿哲的示例答案：海边，再吃烧烤。", kind: "问答", theme: "sunset")
                }.disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).opacity(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1).accessibilityIdentifier("saveAnswer")
            } else {
                Surface { VStack(alignment: .leading, spacing: 12) { Label("小糖的答案", systemImage: "heart").font(.caption.bold()).foregroundStyle(Palette.rose); Text(store.current.answer).font(.title3.weight(.medium)) } }
                Surface { VStack(alignment: .leading, spacing: 12) { Text("阿哲的示例答案").font(.caption.bold()).foregroundStyle(Palette.teal); Text("海边，再吃烧烤。").font(.title3.weight(.medium)) } }
                PrimaryButton(title: added ? "已加入愿望清单" : "加入愿望清单", symbol: added ? "checkmark" : "list.bullet") { store.addWish("去海边看日落", note: "来自每日一问，一起选个时间吧"); added = true }.disabled(added)
                Text("答案已存入问答本。真实双人揭晓将在联网版本开放。").font(.caption).foregroundStyle(Palette.muted)
            }
        }.padding(22) }.background(store.background).navigationTitle("每日一问").navigationBarTitleDisplayMode(.inline)
    }
}

struct EntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    var heading: String
    var titlePrompt: String
    var initialTitle = ""
    var initialNote = ""
    var onSave: (String, String) -> Void
    @State private var title = ""
    @State private var note = ""
    var body: some View {
        NavigationStack { Form {
            Section("标题") { TextField(titlePrompt, text: $title).accessibilityIdentifier("entryTitle").onChange(of: title) { _, value in if value.count > 80 { title = String(value.prefix(80)) } } }
            Section("补充一句话") { TextField("时间、地点，或者此刻的心情…", text: $note, axis: .vertical).lineLimit(4...7).accessibilityIdentifier("entryNote").onChange(of: note) { _, value in if value.count > 500 { note = String(value.prefix(500)) } } }
        }.scrollContentBackground(.hidden).background(Palette.cream).navigationTitle(heading).navigationBarTitleDisplayMode(.inline).toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("保存") { onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), note); dismiss() }.fontWeight(.semibold).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveEntry") }
        }.onAppear { title = initialTitle; note = initialNote } }.tint(Palette.rose)
    }
}

struct MemoriesView: View {
    @EnvironmentObject var store: CircleStore
    @State private var filter = "全部"
    @State private var editor = false
    @State private var selected: MemoryItem?
    var filtered: [MemoryItem] { store.current.memories.filter { filter == "全部" || $0.kind == filter } }
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack { VStack(alignment: .leading, spacing: 5) { Text("我们的回忆").font(.system(size: 27, weight: .bold)); Text(store.spaceName).font(.subheadline).foregroundStyle(Palette.muted) }; Spacer(); Button { editor = true } label: { Image(systemName: "plus").font(.title3).foregroundStyle(.white).frame(width: 43, height: 43).background(store.accent, in: Circle()) }.accessibilityLabel("添加回忆") }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 7) { ForEach(["全部", "照片", "问答", "小事"] + (store.friends ? ["梗墙"] : []), id: \.self) { kind in Button { filter = kind } label: { Text(kind).font(.subheadline.weight(.medium)).padding(.horizontal, 19).padding(.vertical, 10).foregroundStyle(filter == kind ? .white : Palette.muted).background(filter == kind ? store.accent : store.accent.opacity(0.06), in: Capsule()) } } } }
            Text("把平凡的一天，留成以后会微笑的瞬间。").font(.caption).foregroundStyle(Palette.muted)
            if filtered.isEmpty { EmptyState(icon: "photo.on.rectangle", title: "这里还空着", detail: "点右上角，留下你们的第一段回忆。") }
            ForEach(filtered) { item in
                Button { selected = item } label: {
                    Surface(padding: 12) { VStack(alignment: .leading, spacing: 13) {
                        if item.kind == "照片" {
                            if let attachment = item.attachment, let photo = store.photo(named: attachment) { Image(uiImage: photo).resizable().scaledToFill().frame(height: 190).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 15)) }
                            else { SunsetArt(theme: item.theme).frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 15)) }
                        }
                        HStack(alignment: .top) {
                            if item.kind != "照片" { Image(systemName: item.kind == "问答" ? "heart.text.clipboard" : "cup.and.saucer").font(.title2).foregroundStyle(store.accent).frame(width: 42, height: 45).background(store.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12)) }
                            VStack(alignment: .leading, spacing: 6) { Text(item.title).font(.headline).multilineTextAlignment(.leading); Text(item.note).font(.caption).foregroundStyle(Palette.muted).lineLimit(2).multilineTextAlignment(.leading); Text(item.date.formatted(.dateTime.month().day()) + " · " + item.kind).font(.caption2).foregroundStyle(Palette.muted) }
                            Spacer(minLength: 0)
                        }.padding(.horizontal, 3).padding(.bottom, 3)
                    } }
                }.buttonStyle(.plain).contextMenu { Button("删除这条本机回忆", systemImage: "trash", role: .destructive) { store.update { $0.memories.removeAll { $0.id == item.id } } } }
            }
            Text("在聊天中长按，也能存成回忆").font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity).padding(.vertical, 10)
        }.padding(20) }.background(store.background).sheet(isPresented: $editor) { EntryEditor(heading: "留下一段回忆", titlePrompt: "给这个瞬间起个名字") { store.addMemory($0, note: $1) } }
            .sheet(item: $selected) { item in NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 20) { Group { if let attachment = item.attachment, let photo = store.photo(named: attachment) { Image(uiImage: photo).resizable().scaledToFit() } else { SunsetArt(theme: item.theme).frame(height: 230) } }.clipShape(RoundedRectangle(cornerRadius: 24)); Pill(text: item.kind, color: store.accent); Text(item.title).font(.title.bold()); Text(item.note).lineSpacing(7); Text(item.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(Palette.muted); Button { store.updateGrowth { $0.wallMemoryID = item.id } } label: { Label(store.growth.wallMemoryID == item.id ? "已挂在小窝墙上" : "挂在小窝照片墙", systemImage: "photo.on.rectangle.angled").frame(minHeight: 44) }.accessibilityIdentifier("pinMemory") }.padding(24) }.background(store.background).toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { selected = nil } } } } }
    }
}

struct WishesView: View {
    @EnvironmentObject var store: CircleStore
    @State private var filter = "待完成"
    @State private var editor = false
    @State private var memoryWish: Wish?
    var items: [Wish] { store.current.wishes.filter { $0.done == (filter == "已完成") } }
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 15) { Image(systemName: "heart.fill").font(.title2).foregroundStyle(store.accent).frame(width: 53, height: 53).background(.white.opacity(0.65), in: Circle()); VStack(alignment: .leading, spacing: 7) { Text("想和你一起完成的事").font(.headline); Text("已完成 \(store.current.wishes.filter(\.done).count) 件小事").font(.caption).foregroundStyle(Palette.muted) }; Spacer() }.padding(20).background(store.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
            Picker("清单状态", selection: $filter) { Text("待完成").tag("待完成"); Text("已完成").tag("已完成") }.pickerStyle(.segmented)
            if items.isEmpty { EmptyState(icon: "checklist", title: filter == "已完成" ? "好事慢慢发生" : "下一件想一起做什么？", detail: filter == "已完成" ? "完成的共同愿望会出现在这里。" : "点下面的按钮，留下一个小愿望。") }
            ForEach(items) { wish in
                Surface(padding: 15) { VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top, spacing: 14) { SunsetArt(theme: wish.theme).frame(width: 85, height: 92).clipShape(RoundedRectangle(cornerRadius: 13)); VStack(alignment: .leading, spacing: 8) { Text(wish.title).font(.headline); Text(wish.note.isEmpty ? "时间待定，一起慢慢计划" : wish.note).font(.subheadline).foregroundStyle(Palette.muted); HStack(spacing: -5) { MyAvatar(size: 25); Avatar(name: store.friends ? "柚" : "哲", color: Color(hex: 0xE6DDD5), size: 25) } }; Spacer(minLength: 0) }
                    if wish.done { Button("重新放回待完成") { store.toggleWish(wish.id) }.font(.caption).foregroundStyle(store.accent) }
                    else { PrimaryButton(title: "完成并留下回忆", symbol: "checkmark", color: store.accent) { store.toggleWish(wish.id); memoryWish = wish }.accessibilityIdentifier("completeWish") }
                } }
            }
        }.padding(20) }.background(store.background).navigationTitle("愿望清单").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { PrimaryButton(title: "添加一个共同愿望", symbol: "plus", color: store.accent) { editor = true }.padding(.horizontal, 20).padding(.vertical, 10).background(store.background).accessibilityIdentifier("addWish") }
            .sheet(isPresented: $editor) { EntryEditor(heading: "添加共同愿望", titlePrompt: "想一起做什么？") { store.addWish($0, note: $1) } }
            .sheet(item: $memoryWish) { wish in EntryEditor(heading: "愿望完成啦", titlePrompt: "这个瞬间叫什么？", initialTitle: wish.title, initialNote: wish.note) { store.addMemory($0, note: $1, theme: wish.theme) } }
    }
}

struct StatusView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoError = false
    @State private var loading = false
    private let statuses = ["在看电影 🎬", "今天有点累 💤", "想你了 ♥", "忙着呢，晚点聊 ☕️", "今天超开心 ☀️", "一起吃饭吗 🍜"]
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) {
            Text("给此刻留一句话").font(.title2.bold()); Text("由你主动分享，随时可以修改或清除。").font(.subheadline).foregroundStyle(Palette.muted)
            Surface { TextField("我现在…", text: $text, axis: .vertical).lineLimit(2...3).onChange(of: text) { _, v in if v.count > 80 { text = String(v.prefix(80)) } } }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Surface { HStack(spacing: 14) {
                    if let photoData, let image = UIImage(data: photoData) { Image(uiImage: image).resizable().scaledToFill().frame(width: 70, height: 70).clipped().clipShape(RoundedRectangle(cornerRadius: 12)) }
                    else { Image(systemName: "photo.badge.plus").font(.title).foregroundStyle(Palette.teal).frame(width: 60, height: 60) }
                    VStack(alignment: .leading, spacing: 6) { Text(loading ? "正在读取…" : (photoData == nil ? "加一张随手拍" : "已选择照片")).font(.subheadline.bold()); Text("保存后出现在共同回忆里").font(.caption).foregroundStyle(Palette.muted) }
                    Spacer()
                } }
            }.buttonStyle(.plain).disabled(loading)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(statuses, id: \.self) { s in Button { text = s } label: { Text(s).font(.subheadline).frame(maxWidth: .infinity).padding(15).background(.white, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(Palette.ink) } } }
            PrimaryButton(title: "保存此刻", color: store.accent) {
                do {
                    if let photoData { try store.addPhotoMemory(photoData, caption: text.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    store.update { $0.status = text.trimmingCharacters(in: .whitespacesAndNewlines) }; dismiss()
                } catch { photoError = true }
            }.disabled(loading)
            Button("清除我的状态") { store.update { $0.status = "" }; dismiss() }.font(.subheadline).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
            Text("本版状态只保存在本机，不读取位置、电量或其他应用。").font(.caption).foregroundStyle(Palette.muted)
        }.padding(22) }.background(store.background).navigationTitle("我的此刻").navigationBarTitleDisplayMode(.inline).onAppear { text = store.current.status }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }; loading = true
                Task { do { photoData = try await item.loadTransferable(type: Data.self); if photoData == nil { photoError = true } } catch { photoError = true }; loading = false }
            }
            .alert("照片未保存", isPresented: $photoError) { Button("知道了", role: .cancel) {} } message: { Text("无法读取这张照片，请重新选择。") }
    }
}
struct WallView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            Text("收藏我们的名场面").font(.title2.bold()); Text("在群聊里长按一条消息，选择“上梗墙”。").font(.subheadline).foregroundStyle(Palette.muted)
            ForEach(store.current.memories.filter { $0.kind == "梗墙" }) { item in Surface { VStack(alignment: .leading, spacing: 12) { Image(systemName: "quote.opening").foregroundStyle(Palette.teal); Text(item.title).font(.title3.bold()); Text(item.note).font(.caption).foregroundStyle(Palette.muted) } } }
        }.padding(20) }.background(store.background).navigationTitle("梗墙").navigationBarTitleDisplayMode(.inline)
    }
}
struct ProfileView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 22) {
            Text("我的").font(.system(size: 28, weight: .bold)).padding(.top, 10)
            NavigationLink(value: Screen.profileEditor) { Surface { HStack(spacing: 14) { MyAvatar(size: 58); VStack(alignment: .leading, spacing: 7) { Text(store.myName).font(.title3.bold()); Text("昵称、头像、小窝和团团名字").font(.caption).foregroundStyle(Palette.muted) }; Spacer(); Image(systemName: "pencil") } } }.buttonStyle(.plain).accessibilityIdentifier("editProfile")
            NavigationLink(value: Screen.spaces) { Surface { IconTile(icon: "square.stack.3d.up", title: "我的空间", subtitle: "当前：\(store.spaceName)", color: store.accent) } }.buttonStyle(.plain).accessibilityIdentifier("mySpaces")
            NavigationLink(value: Screen.aiSettings) { Surface { IconTile(icon: "sparkles", title: "AI 使用设置", subtitle: "查看内容范围与互动方式") } }.buttonStyle(.plain).accessibilityIdentifier("aiSettings")
            NavigationLink(value: Screen.modules) { Surface { IconTile(icon: "sparkles", title: "小圈游乐场", subtitle: "打卡、约定、游戏和时光胶囊") } }.buttonStyle(.plain).accessibilityIdentifier("allPlaygrounds")
            NavigationLink(value: Screen.invitation) { Surface { IconTile(icon: "envelope", title: "邀请卡预览", subtitle: "给重要的人留一个位置") } }.buttonStyle(.plain)
            NavigationLink(value: Screen.privacy) { Surface { IconTile(icon: "lock.shield", title: "隐私与空间退出", subtitle: "本机导出、分享与离开") } }.buttonStyle(.plain).accessibilityIdentifier("privacySettings")
            NavigationLink(value: Screen.stickers) { Surface { IconTile(icon: "heart.square", title: "我的贴纸", subtitle: "创作、收藏，再发给喜欢的人") } }.buttonStyle(.plain)
            NavigationLink(value: Screen.sharing) { Surface { IconTile(icon: "battery.75percent", title: "状态分享", subtitle: "电量与城市天气，由你决定", color: Palette.teal) } }.buttonStyle(.plain)
            if !store.friends { Surface { VStack(alignment: .leading, spacing: 12) { Text("在一起的日期").font(.subheadline.bold()); DatePicker("起始日", selection: Binding(get: { store.state.joined }, set: { store.state.joined = Calendar.current.startOfDay(for: $0); store.persist() }), in: ...Date(), displayedComponents: .date).datePickerStyle(.compact).font(.subheadline); Text("修改后首页的天数与周年倒数会一起更新。").font(.caption).foregroundStyle(Palette.muted) } } }
            Surface { Toggle("互动触感", isOn: Binding(get: { store.state.haptics }, set: { store.state.haptics = $0; store.persist() })).font(.subheadline).tint(store.accent) }
            Surface { VStack(alignment: .leading, spacing: 13) { Label("关于这个开发版", systemImage: "iphone").font(.headline); Text("小小圈 0.4.2 · 本机开发版").font(.subheadline); Text("按 V2 / V3 设计逐步制作。消息、贴纸、绘图、原声录音、回忆和试玩进度保存在此设备。\n\nAI、登录邀请、跨设备聊天、推送与付费仍待接入。此处的本机模板和题库不会冒充 AI 或真人回复。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(6) } }
            Text("只属于彼此的一点小小日常。 ").font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity).padding(.vertical, 15)
        }.padding(20) }.background(store.background)
    }
}
