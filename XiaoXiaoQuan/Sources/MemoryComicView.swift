import SwiftUI
import PhotosUI

@MainActor struct MemoryComicView: View {
    @EnvironmentObject var store: CircleStore
    @State private var selections: [PhotosPickerItem] = []
    @State private var names: [String] = []
    @State private var note = ""
    @State private var panels = ["", "", ""]
    @State private var stage = 0
    @State private var failure = false
    @State private var saved = false
    @State private var loading = false
    var body: some View {
        CreativePage(title: stage == 0 ? "把今天画下来" : stage == 1 ? "先看看故事" : "今天的小手账") {
            if stage == 0 { materials }
            else if stage == 1 { storyboard }
            else { scrapbook }
        }.onAppear { note = store.creative.storyDraft }
            .onChange(of: note) { _, value in store.updateCreative { $0.storyDraft = String(value.prefix(300)) } }
            .onChange(of: selections) { _, values in
                Task {
                    loading = true
                    var result: [String] = []
                    for item in values.prefix(3) {
                        if let data = try? await item.loadTransferable(type: Data.self), let name = try? store.savePhoto(data) { result.append(name) }
                    }
                    names = result; loading = false
                }
            }
            .alert("AI 绘图尚未连接", isPresented: $failure) {
                Button("继续编辑", role: .cancel) {}
                Button("先做照片手账") { stage = 2 }
            } message: { Text("你的照片与文字保留在本机。可以先用原照片和自己的字幕制作手账；此结果不会标成 AI 漫画。") }
            .alert("已存入本机回忆", isPresented: $saved) { Button("继续编辑", role: .cancel) {} } message: { Text("联网后才能申请双方确认，保存进真正的共同空间。") }
    }
    var materials: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("用照片和文字\n把这一刻留成小故事").font(.title2.bold()).lineSpacing(7); Spacer(); TuantuanSticker(pose: 5).frame(width: 95, height: 125) }
            Text("1  选择你想用的照片（最多3张）").font(.headline)
            let thumbnails = names.compactMap { store.photo(named: $0) }
            PhotosPicker(selection: $selections, maxSelectionCount: 3, matching: .images) {
                if thumbnails.isEmpty {
                    Label("从相册选择", systemImage: "photo.badge.plus").frame(maxWidth: .infinity).frame(height: 118)
                        .background(Palette.pink, in: RoundedRectangle(cornerRadius: 20))
                } else {
                    HStack { ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image).resizable().scaledToFill().frame(width: 95, height: 110).clipShape(RoundedRectangle(cornerRadius: 15))
                    } }
                }
            }
            if loading { ProgressView("正在读取所选照片") }
            Text("2  写下这段回忆").font(.headline)
            TextField("下雨了，我们还是买到了喜欢的咖啡…", text: $note, axis: .vertical).lineLimit(4...6).padding(17).background(.white, in: RoundedRectangle(cornerRadius: 18))
            Pill(text: "三格故事 · 字幕可修改")
            PrimaryButton(title: "先写三格故事", symbol: "pencil") {
                panels = [note.isEmpty ? "故事从这里开始" : note, "想记住的第二个瞬间", "今天的小小结尾"]
                stage = 1
            }.disabled(names.isEmpty || loading).opacity(names.isEmpty ? 0.5 : 1)
            Text("只读取你主动选择的照片。当前素材仅保存本机。").font(.caption).foregroundStyle(Palette.muted)
        }
    }
    var storyboard: some View {
        VStack(alignment: .leading, spacing: 20) {
            ConnectionNote(text: "手动分镜草稿；AI 故事与绘图服务待接入")
            ForEach(0..<3) { i in
                PaperCard(color: [Palette.pink, Color(hex: 0xDDEEE6), Palette.lavender][i]) {
                    HStack(alignment: .top, spacing: 15) {
                        Text("\(i + 1)").font(.title.bold()).foregroundStyle(Palette.rose)
                        if !names.isEmpty, let image = store.photo(named: names[i % names.count]) { Image(uiImage: image).resizable().scaledToFill().frame(width: 70, height: 90).clipShape(RoundedRectangle(cornerRadius: 12)) }
                        TextField("这一格的故事", text: $panels[i], axis: .vertical).lineLimit(3...5).font(.subheadline)
                    }
                }
            }
            if store.isAIEnabled { PrimaryButton(title: "画成漫画（AI）", symbol: "sparkles") { failure = true } }
            AIAvailabilityNote()
            Button("先做原照片手账") { stage = 2 }.frame(maxWidth: .infinity).frame(minHeight: 44)
            Button("返回选照片") { stage = 0 }.font(.subheadline).frame(maxWidth: .infinity).frame(minHeight: 44)
        }
    }
    var scrapbook: some View {
        VStack(alignment: .leading, spacing: 20) {
            Pill(text: "原照片手账 · 本机制作", color: Palette.teal)
            ForEach(0..<3) { i in
                PaperCard(color: [.white, Palette.pink.opacity(0.35), Palette.lavender.opacity(0.35)][i]) { VStack(alignment: .leading, spacing: 12) {
                    if !names.isEmpty, let image = store.photo(named: names[i % names.count]) { Image(uiImage: image).resizable().scaledToFill().frame(height: 180).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 12)) }
                    Text(panels[i]).font(.headline)
                } }
            }
            PrimaryButton(title: "保存到本机回忆", symbol: "bookmark") {
                store.addMemory(String((note.isEmpty ? "今天的小手账" : note).prefix(60)), note: panels.joined(separator: "\n"), kind: "照片", attachment: names.first)
                saved = true
            }
            Button("修改故事") { stage = 1 }.frame(maxWidth: .infinity).frame(minHeight: 44)
        }
    }
}

