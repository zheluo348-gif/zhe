import SwiftUI
import PhotosUI

struct PlayfulChatView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onBack: (() -> Void)?
    @State private var celebration: Int?
    @State private var celebrationID = UUID()
    @State private var hugPreview: HugPreviewRequest?
    @State private var gameToPlay: ChatMessage?
    @State private var noteMode = true
    @State private var draft = ""
    @State private var drawing = false
    @State private var voice = false
    @State private var inspiration = false
    @State private var photoItem: PhotosPickerItem?
    @State private var error: String?
    @State private var reply: String?
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        HStack { Image(systemName:store.stage.dark ? "sparkles":"leaf"); Text(store.stage.title); Spacer(); NavigationLink(value:Screen.growth) { Text("成长旅行").fontWeight(.semibold) } }.font(.system(size:10)).foregroundStyle(store.stage.dark ? Color(hex:0x735B94):store.stage.accent).padding(.horizontal,12).padding(.vertical,9).background(.white.opacity(0.7),in:Capsule())
                        Text("本机体验 · 新消息尚未同步给其他设备").font(.system(size: 10)).foregroundStyle(Palette.muted)
                        ForEach(store.current.messages) { message in row(message).id(message.id) }
                        Color.clear.frame(height: 1).id("chatBottom")
                    }.padding(.horizontal, 17).padding(.bottom, 12)
                }.scrollDismissesKeyboard(.interactively)
                    .onAppear { proxy.scrollTo("chatBottom", anchor: .bottom) }
                    .onChange(of: store.current.messages.count) { _, _ in withAnimation { proxy.scrollTo("chatBottom", anchor: .bottom) } }
                    .onChange(of: focused) { _, value in if value { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { proxy.scrollTo("chatBottom", anchor: .bottom) } } }
            }
        }.background { ChatStageBackdrop(stage:store.stage) }
            .overlay { if let celebration { KeywordCelebration(effect: celebration).id(celebrationID) } }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { draft = store.current.draft ?? "" }
            .onChange(of: draft) { _, v in
                if v.count > 2000 { draft = String(v.prefix(2000)) }
                store.update { $0.draft = String(v.prefix(2000)) }
            }
            .fullScreenCover(item:$hugPreview) { request in HugReceiverPreview(message:request.message) }
            .sheet(item:$gameToPlay) { message in GameInvitationSheet(message:message) }
            .sheet(isPresented: $drawing) { DrawingNoteView() }
            .sheet(isPresented: $voice) { VoiceNoteView() }
            .sheet(isPresented: $inspiration) { InspirationDrawer() }
            .onReceive(NotificationCenter.default.publisher(for: .circleOpenChat)) { _ in draft = store.current.draft ?? "" }
            .alert("没有添加成功", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(error ?? "") }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    do { guard let data = try await item.loadTransferable(type: Data.self) else { throw CocoaError(.fileReadCorruptFile) }; try store.sendPhoto(data) }
                    catch { self.error = "无法读取所选照片，请重试。" }
                    photoItem = nil
                }
            }
    }
    var header: some View {
        HStack(spacing: 11) {
            Button { if let onBack { onBack() } else { dismiss() } } label: { Image(systemName: "chevron.left").font(.title3).frame(width: 32, height: 46) }.accessibilityLabel("返回首页")
            Avatar(name: store.friends ? "六" : "哲", size: 40)
            VStack(alignment: .leading, spacing: 5) {
                Text(store.friends ? "\(store.spaceName) · 6人" : "阿哲").font(.headline)
                Text("把小事说给TA听").font(.caption2).foregroundStyle(Palette.muted)
            }
            Spacer()
            NavigationLink(value: Screen.room) { Image(systemName: "sofa").font(.title3).frame(width: 44, height: 44) }.accessibilityLabel("进入小房间")
        }.foregroundStyle(Palette.ink).padding(.horizontal, 12).padding(.vertical, 6).background(Palette.cream)
    }
    func row(_ m: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if m.mine { Spacer(minLength: 35) }
            else { Avatar(name: m.sender, color: store.friends ? Color(hex: 0xD5EAE7) : Palette.pink, size: 33) }
            VStack(alignment: m.mine ? .trailing : .leading, spacing: 5) {
                if store.friends { Text(m.mine ? store.myName:m.sender).font(.caption2).foregroundStyle(Palette.muted) }
                messageContent(m).contextMenu {
                    Button("回复", systemImage: "arrowshape.turn.up.left") { reply = m.text; focused = true }
                    if !m.kind.hasPrefix("voice:") {
                        Button(store.friends ? "上梗墙" : "保存回忆", systemImage: "bookmark") {
                            store.addMemory(String((m.text.isEmpty ? "聊天的小片段" : m.text).prefix(60)), note: "来自\(m.sender)的聊天", kind: m.attachment != nil ? "照片" : (store.friends ? "梗墙" : "小事"), attachment: m.attachment)
                        }
                    }
                    Button("复制文字", systemImage: "doc.on.doc") { UIPasteboard.general.string = m.text }
                    if m.mine { Button("删除本机消息", systemImage: "trash", role: .destructive) { store.update { $0.messages.removeAll { $0.id == m.id } } } }
                }
                Text(m.mine ? "本机保存 · \(m.date.formatted(.dateTime.hour().minute()))" : "历史示例").font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
            if m.mine { MyAvatar(size: 33) }
            else { Spacer(minLength: 35) }
        }
    }
    @ViewBuilder func messageContent(_ m: ChatMessage) -> some View {
        if m.kind.hasPrefix("voice:") { VoiceMessageCard(message: m) }
        else if m.isHug {
            HugMessageCard(message:m) { focused=false;hugPreview=HugPreviewRequest(message:m) }
        } else if m.kind == "invite" {
            GameInvitationCard(message:m) { focused=false;gameToPlay=m }
        } else if m.kind.hasPrefix("sticker:") {
            VStack(spacing: 0) {
                TuantuanSticker(pose: Int(m.kind.split(separator: ":").last ?? "0") ?? 0).frame(width: 185, height: 175)
                Text(m.text).font(.system(size: 22, weight: .bold)).multilineTextAlignment(.center)
            }.frame(maxWidth: 220)
        } else if let name = m.attachment, let image = store.photo(named: name) {
            Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 215, maxHeight: 270).clipShape(RoundedRectangle(cornerRadius: 19)).accessibilityIdentifier("messagePhoto")
        } else if m.kind == "note" {
            PaperCard(color: m.mine ? store.stage.floor.opacity(0.50) : Palette.mint) {
                HStack { Text("给你的小纸条").font(.system(size: 10, weight: .semibold)).foregroundStyle(Palette.rose); Spacer(); Image(systemName: "heart").font(.caption).foregroundStyle(Palette.rose) }
                Text(m.text).font(.system(size: 16)).lineSpacing(7).textSelection(.enabled)
            }.frame(maxWidth: 245).rotationEffect(.degrees(m.mine ? 1 : -1))
        } else if ["quiz", "plan"].contains(m.kind) {
            PaperCard(color: m.kind == "quiz" ? Palette.lavender : Color(hex: 0xDDEEE6), tape: false) {
                Label(m.kind == "quiz" ? "一起玩过的小默契" : (m.text.hasPrefix("周末灵感") ? "周末小灵感" : "小圈日常卡"), systemImage: m.kind == "quiz" ? "gamecontroller" : "sparkles").font(.caption.bold()).foregroundStyle(Palette.teal)
                Text(m.text).font(.subheadline).lineSpacing(6)
            }.frame(maxWidth: 255)
        } else {
            Text(m.text).font(.system(size: 16)).lineSpacing(4).padding(.horizontal, 15).padding(.vertical, 12)
                .foregroundStyle(m.mine ? .white : Palette.ink)
                .background(m.mine ? (store.stage.dark ? Color(hex:0x735B94):store.stage.accent) : .white, in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(m.mine ? .clear : Palette.border.opacity(0.7), lineWidth: 1))
        }
    }
    var composer: some View {
        VStack(spacing: 9) {
            HStack(spacing: 7) {
                TuantuanSticker(pose: 1).frame(width: 29, height: 30)
                Text("团团替你把小心意收好").font(.system(size: 10)).foregroundStyle(Palette.muted)
                Spacer()
                Button { noteMode.toggle() } label: { Label(noteMode ? "小纸条" : "轻声说", systemImage: noteMode ? "envelope" : "bubble.left").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.rose).padding(.horizontal, 10).frame(height: 32).background(Palette.pink, in: Capsule()) }.accessibilityIdentifier("messageStyle")
            }
            if let reply { HStack { Text("回复：\(reply)").lineLimit(1); Spacer(); Button { self.reply = nil } label: { Image(systemName: "xmark.circle.fill") } }.font(.caption).foregroundStyle(Palette.muted) }
            HStack(spacing: 7) {
                HugChargeButton { level in focused=false;store.sendChargedHug(level:level) }
                Button { focused = false; drawing = true } label: { tool("画画", icon: "pencil.tip", color: Color(hex: 0x9084C5)) }.accessibilityIdentifier("openDrawing")
                Button { focused = false; voice = true } label: { tool("声音", icon: "mic.fill", color: Palette.rose) }.accessibilityIdentifier("openVoice")
                Button { focused = false; inspiration = true } label: { tool("灵感", icon: "pawprint.fill", color: Palette.rose) }.accessibilityIdentifier("openInspiration")
            }.buttonStyle(.plain)
            HStack(alignment: .bottom, spacing: 9) {
                PhotosPicker(selection: $photoItem, matching: .images) { Image(systemName: "plus").font(.title3).foregroundStyle(Palette.muted).frame(width: 41, height: 44).background(.white, in: Circle()) }.accessibilityLabel("添加照片")
                TextField("把小事说给TA听…", text: $draft, axis: .vertical).lineLimit(1...4).font(.system(size: 15))
                    .padding(.horizontal, 14).padding(.vertical, 12).background(.white, in: Capsule()).focused($focused).accessibilityIdentifier("messageInput")
                Button {
                    let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else { return }
                    store.send(reply.map { "回复「\($0.prefix(50))」\n" + value } ?? value, kind: noteMode ? "note" : "text")
                    if store.creative.animations && !reduceMotion, let keyword = store.play.keywords.first(where: { value.contains($0.word) }) {
                        let token = UUID(); celebrationID = token; celebration = keyword.effect
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { if celebrationID == token { celebration = nil } }
                    }
                    draft = ""; reply = nil; focused = false
                } label: { Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(.white).frame(width: 45, height: 45).background(Palette.rose, in: Circle()) }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1).accessibilityIdentifier("sendMessage")
            }
        }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8).background(Palette.cream)
    }
    func tool(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) { Image(systemName: icon).foregroundStyle(color); Text(text).foregroundStyle(Palette.ink) }
            .font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity).frame(minHeight: 41)
            .background(.white, in: Capsule()).overlay(Capsule().stroke(Palette.border.opacity(0.7), lineWidth: 1))
    }
}

