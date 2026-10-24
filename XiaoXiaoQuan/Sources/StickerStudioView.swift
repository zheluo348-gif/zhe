import SwiftUI
import PhotosUI

struct StickerStudioView: View {
    @EnvironmentObject var store: CircleStore
    @State private var stage = 0
    @State private var prompt = ""
    @State private var caption = "才没有很想你"
    @State private var emotion = "嘴硬"
    @State private var pose = 1
    @State private var saved = false
    @State private var sent = false
    @State private var confirmAI = false
    @State private var photoItem: PhotosPickerItem?
    @State private var errorText = ""
    @Environment(\.dismiss) private var dismiss
    private let captions = ["给你一个抱抱", "才没有很想你", "一起喝杯咖啡", "晚安，梦里见", "陪我玩一会", "画一张小纸条"]
    var body: some View {
        CreativePage(title: stage == 2 ? "选一张发给TA" : stage == 1 ? "这次没画出来" : "心情表情包") {
            if stage == 2 { editor }
            else if stage == 1 { failure }
            else { input }
        }
        .onAppear { prompt = store.creative.moodDraft; caption = store.creative.captionDraft.isEmpty ? "才没有很想你" : store.creative.captionDraft; pose = store.creative.selectedPose }
        .onChange(of: prompt) { _, value in store.updateCreative { $0.moodDraft = String(value.prefix(60)) } }
        .onChange(of: caption) { _, value in store.updateCreative { $0.captionDraft = String(value.prefix(30)) } }
        .alert("确认本次内容", isPresented: $confirmAI) {
            Button("取消", role: .cancel) {}
            Button("尝试生成") { Task { await generate() } }
        } message: { Text("本次文字：\(prompt)\n当前 AI 服务尚未接入，若无法生成，你仍可使用现成贴纸。") }
        .alert("贴纸已保存到聊天", isPresented: $sent) { Button("继续创作") {}; Button("查看聊天") { NotificationCenter.default.post(name: .circleOpenChat, object: nil) } } message: { Text("本机保存，可在聊天中查看；尚未同步给对方。") }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let name = try? store.savePhoto(data) { store.updateCreative { $0.stickerPhoto = name } }
                photoItem = nil
            }
        }
    }
    var input: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack {
                PaperCard { Text("把心情变成\n团团的表情包吧").font(.title3.bold()).lineSpacing(8) }
                TuantuanSticker(pose: 0).frame(width: 105, height: 125)
            }
            Surface { VStack(alignment: .leading, spacing: 13) {
                Text("想对TA说的话").font(.headline)
                TextField("例如：想抱抱，但嘴硬", text: $prompt, axis: .vertical)
                    .lineLimit(3...4).padding(13).background(Palette.cream, in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityIdentifier("stickerPrompt")
                Text("\(prompt.count)/60").font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity, alignment: .trailing)
                Text("选择主角").font(.subheadline.bold())
                HStack {
                    ChoiceChip(title: "团团", selected: store.creative.stickerPhoto == nil) { store.updateCreative { $0.stickerPhoto = nil } }
                    PhotosPicker(selection: $photoItem, matching: .images) { Label("选照片", systemImage: "photo").font(.subheadline).padding(12).background(Palette.cream, in: Capsule()) }
                    if let name = store.creative.stickerPhoto, let image = store.photo(named: name) { Image(uiImage: image).resizable().scaledToFill().frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 9)) }
                }
                Text("选择情绪").font(.subheadline.bold())
                HStack { ForEach(["撒娇", "嘴硬", "搞怪"], id: \.self) { word in ChoiceChip(title: word, selected: emotion == word) { emotion = word } } }
            } }
            if store.isAIEnabled {
            PrimaryButton(title: "生成 2 张", symbol: "sparkles") { confirmAI = true }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1).accessibilityIdentifier("generateSticker")
            }
            Button { stage = 2 } label: { Label(store.isAIEnabled ? "先用现成贴纸体验":"自己制作一张贴纸", systemImage: "pawprint").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(12) }.accessibilityIdentifier("useReadyStickers")
            AIAvailabilityNote()
            if !store.creative.stickers.isEmpty {
                Text("我的收藏 · \(store.creative.stickers.count)").font(.headline)
                ScrollView(.horizontal) { HStack(spacing: 12) { ForEach(store.creative.stickers) { item in Button { pose = item.pose; caption = item.caption; stage = 2 } label: { VStack { TuantuanSticker(pose: item.pose).frame(width: 95, height: 90); Text(item.caption).font(.caption).lineLimit(1) }.frame(width: 110).padding(8).background(.white, in: RoundedRectangle(cornerRadius: 16)) } } } }
            }
        }
    }
    var editor: some View {
        VStack(alignment: .leading, spacing: 19) {
            Pill(text: "现成贴纸 · 可编辑", color: Palette.teal)
            PaperCard(color: Palette.pink.opacity(0.5), tape: false) { VStack(spacing: 2) {
                if let name = store.creative.stickerPhoto, let image = store.photo(named: name) {
                    Image(uiImage: image).resizable().scaledToFill().frame(height: 120).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 15))
                }
                TuantuanSticker(pose: pose).frame(height: 210).frame(maxWidth: .infinity)
                Text(caption.isEmpty ? " " : caption).font(.system(size: 24, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(Palette.ink).frame(maxWidth: .infinity)
            } }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(0..<6) { i in Button {
                pose = i; saved = false; store.updateCreative { $0.selectedPose = i }; caption = captions[i]
            } label: { TuantuanSticker(pose: i).frame(width: 63, height: 65).padding(5).background(pose == i ? Palette.pink : .white, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(pose == i ? Palette.rose : Palette.border, lineWidth: pose == i ? 2 : 1)) }.accessibilityIdentifier("stickerPose_\(i)") } } }
            Text("编辑文字").font(.headline)
            TextField("加一句话…", text: $caption).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 15)).accessibilityIdentifier("stickerCaption")
            HStack {
                Button { store.collectSticker(pose: pose, caption: caption); saved = true } label: { Label(saved ? "已收藏" : "收藏", systemImage: saved ? "heart.fill" : "heart").frame(minWidth: 90, minHeight: 50).background(.white, in: Capsule()) }.accessibilityIdentifier("collectSticker")
                PrimaryButton(title: store.friends ? "发到群聊" : "发给阿哲", symbol: "paperplane") { send() }.accessibilityIdentifier("sendSticker")
            }
        }
    }
    var failure: some View {
        VStack(spacing: 22) {
            TuantuanSticker(pose: 5).frame(height: 210).frame(maxWidth: .infinity)
            Text("这次没画出来").font(.title.bold())
            Text(errorText).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center).accessibilityIdentifier("aiFailureReason")
            PaperCard(color: Palette.lavender) { Text(prompt).font(.headline); Text("你的想法已保留").font(.caption).foregroundStyle(Palette.muted) }
            PrimaryButton(title: "重新生成", symbol: "arrow.clockwise") { confirmAI = true }
            Button { stage = 2 } label: { Text("先用现成贴纸").font(.headline).frame(maxWidth: .infinity).padding(16).background(.white, in: Capsule()) }.accessibilityIdentifier("fallbackStickers")
            Button("修改想法") { stage = 0 }
        }
    }
    func generate() async {
        do { _ = try await store.generateCreative(prompt: prompt, mode: "sticker") }
        catch { errorText = error.localizedDescription; stage = 1 }
    }
    func send() {
        let card = StickerComposition(pose: pose, caption: caption, photo: store.creative.stickerPhoto.flatMap { store.photo(named: $0) })
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        if let image = renderer.uiImage, let data = image.pngData() { try? store.sendPhoto(data) }
        else { store.sendSticker(pose: pose, caption: caption) }
        sent = true
    }
}
struct StickerComposition: View {
    var pose: Int
    var caption: String
    var photo: UIImage?
    var body: some View {
        VStack(spacing: 8) {
            if let photo { Image(uiImage: photo).resizable().scaledToFill().frame(width: 280, height: 150).clipped().clipShape(RoundedRectangle(cornerRadius: 18)) }
            TuantuanSticker(pose: pose).frame(width: 260, height: 250)
            Text(caption).font(.system(size: 25, weight: .bold)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
        }.padding(22).frame(width: 330).background(Palette.cream)
    }
}

