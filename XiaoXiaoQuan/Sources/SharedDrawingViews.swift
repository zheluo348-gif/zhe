import SwiftUI
import PencilKit

struct SharedDrawingRequest: Identifiable {
    let id: UUID
    let space: String
}

@MainActor enum SharedDrawingArt {
    static let side: CGFloat = 320
    static func image(_ session: SharedDrawingSession) throws -> UIImage {
        var strokes: [PKStroke] = []
        for round in session.rounds where !round.drawing.isEmpty {
            strokes += try PKDrawing(data: round.drawing).strokes
        }
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { context in
            UIColor(Palette.cream).setFill(); context.fill(rect)
            PKDrawing(strokes: strokes).image(from: rect, scale: 2).draw(in: rect)
        }
    }
}

struct SharedDrawingCard: View {
    let session: SharedDrawingSession
    let open: () -> Void
    var body: some View {
        PaperCard(color: .white, tape: false) {
            Label("一起续画", systemImage: "pencil.tip.crop.circle").font(.headline).foregroundStyle(Palette.rose)
            if let image = try? SharedDrawingArt.image(session), !session.rounds.isEmpty {
                Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 14)).accessibilityLabel("双方续画的当前作品")
            } else {
                Image(systemName: "pencil.and.outline").font(.system(size: 40)).foregroundStyle(Palette.teal).frame(maxWidth: .infinity).frame(height: 110).background(Palette.mint, in: RoundedRectangle(cornerRadius: 14))
            }
            Text(session.finished ? "我们一起画好了" : "轮到\(session.currentPlayer)啦").font(.subheadline.bold())
            if let last = session.rounds.last, !last.note.isEmpty { Text("\(last.author)：\(last.note)").font(.caption).lineLimit(3) }
            Text("\(session.rounds.count)轮笔迹 · \(session.players.joined(separator: "、"))").font(.system(size: 10)).foregroundStyle(Palette.muted)
            Button(session.finished ? "查看完整作品" : "接着画") { open() }
                .font(.subheadline.bold()).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 44).background(Palette.rose, in: Capsule()).accessibilityIdentifier("openSharedDrawing")
            Text("本机轮流试玩 · 暂未与其他设备同步").font(.system(size: 10)).foregroundStyle(Palette.muted)
        }.frame(maxWidth: 255)
    }
}

struct SharedDrawingEditor: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    let request: SharedDrawingRequest
    @State private var canvas = PKCanvasView()
    @State private var note = ""
    @State private var width: Double = 5
    @State private var erasing = false
    @State private var revision = 0
    @State private var error: String?
    @State private var leavingDraft = false
    private var session: SharedDrawingSession? {
        guard request.space == store.state.mode else { return nil }
        return store.current.messages.first { $0.id == request.id }?.sharedDrawing
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let session {
                    VStack(alignment: .leading, spacing: 17) {
                        Text(session.finished ? "小小的一幅画，留下我们各自的笔迹。" : (session.rounds.count >= 24 ? "24轮小故事画好了，可以完成作品啦。" : "轮到\(session.currentPlayer)，接着添一点吧。"))
                            .font(.headline).foregroundStyle(Palette.rose)
                        Text("本机轮流试玩，交棒后换下一位；暂未同步给其他设备。")
                            .font(.caption).foregroundStyle(Palette.muted)
                        if let image = try? SharedDrawingArt.image(session) {
                            GeometryReader { geometry in
                                ZStack {
                                    Image(uiImage: image).resizable().frame(width: SharedDrawingArt.side, height: SharedDrawingArt.side)
                                    if !session.finished && session.rounds.count < 24 {
                                        CanvasBridge(canvas: canvas, color: UIColor(revision.isMultiple(of: 2) ? Palette.rose : Palette.teal), width: width, erasing: erasing)
                                            .frame(width: SharedDrawingArt.side, height: SharedDrawingArt.side).accessibilityIdentifier("sharedDrawingCanvas")
                                    }
                                }.frame(width: SharedDrawingArt.side, height: SharedDrawingArt.side)
                                    .scaleEffect(geometry.size.width / SharedDrawingArt.side, anchor: .topLeading)
                            }.aspectRatio(1, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.border, lineWidth: 1))
                            if !session.finished {
                                if session.rounds.count < 24 { drawingControls(session) }
                                else { Text("点击右上角“完成作品”，就能保存到回忆。").font(.caption).foregroundStyle(Palette.teal) }
                            }
                            else {
                                PrimaryButton(title: session.savedMemoryID == nil ? "保存到共同回忆" : "已保存到共同回忆", symbol: "bookmark", color: Palette.teal) {
                                    do { _ = try store.saveSharedDrawingMemory(request.id) }
                                    catch { self.error = "作品没有保存成功，笔迹仍在，请重试。" }
                                }.disabled(session.savedMemoryID != nil).accessibilityIdentifier("saveSharedDrawingMemory")
                            }
                        } else { Text("这张画布暂时无法读取，请返回聊天重试。").foregroundStyle(Palette.rose) }
                        ForEach(Array(session.rounds.enumerated()), id: \.element.id) { index, round in
                            HStack(alignment: .top) {
                                Circle().fill(index.isMultiple(of: 2) ? Palette.rose : Palette.teal).frame(width: 8, height: 8).padding(.top, 5)
                                Text("第\(index + 1)轮 · \(round.author)\(round.note.isEmpty ? "" : "：" + round.note)").font(.caption)
                            }
                        }
                    }.padding(20)
                } else { Text("这张画布已移除，或已切换空间。").padding(24) }
            }.background(Palette.cream).navigationTitle("一起续画").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("返回聊天") {
                    if !canvas.drawing.strokes.isEmpty || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { leavingDraft = true }
                    else { dismiss() }
                }.accessibilityIdentifier("closeSharedDrawing") }
                    ToolbarItem(placement: .confirmationAction) {
                        if let session, !session.finished {
                            Button("完成作品") { finishDrawing() }.disabled(!session.canFinish).accessibilityIdentifier("finishSharedDrawing")
                        }
                    }
                }
                .onAppear { revision = session?.rounds.count ?? 0 }
                .interactiveDismissDisabled()
                .confirmationDialog("这一轮还没交出", isPresented: $leavingDraft, titleVisibility: .visible) {
                    Button("交出本轮并返回") { submitRound() }
                    Button("放弃本轮", role: .destructive) { dismiss() }
                    Button("继续画", role: .cancel) {}
                } message: { Text("之前交出的笔迹已经保存，这一轮尚未保存。") }
                .alert("续画提示", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(error ?? "") }
        }
    }

    @ViewBuilder private func drawingControls(_ session: SharedDrawingSession) -> some View {
        HStack {
            Label("这一轮的画笔", systemImage: "pencil.tip").font(.caption).foregroundStyle(revision.isMultiple(of: 2) ? Palette.rose : Palette.teal)
            Spacer()
            Button { canvas.undoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward").frame(width: 40, height: 44) }.accessibilityLabel("撤销这一轮")
            Button { erasing.toggle() } label: { Image(systemName: "eraser").foregroundStyle(erasing ? Palette.rose : Palette.muted).frame(width: 40, height: 44) }.accessibilityLabel("擦除这一轮的笔迹")
            Button { canvas.drawing = PKDrawing() } label: { Image(systemName: "trash").frame(width: 40, height: 44) }.accessibilityLabel("清空这一轮")
        }
        HStack { Text("笔粗").font(.caption); Slider(value: $width, in: 2...12).tint(Palette.rose) }
        TextField("添一句话，或直接手写在画里…", text: $note).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14)).accessibilityIdentifier("sharedDrawingNote")
            .onChange(of: note) { _, value in if value.count > 80 { note = String(value.prefix(80)) } }
        PrimaryButton(title: "画好这一轮，交给下一位", symbol: "paperplane") {
            submitRound()
        }.disabled(session.rounds.count >= 24).accessibilityIdentifier("submitDrawingRound")
        Text("交出本轮后会保存。橡皮和清空只影响本轮，之前的笔迹会保留。").font(.caption2).foregroundStyle(Palette.muted)
    }

    private func finishDrawing() {
        guard request.space == store.state.mode else { error = "空间已经切换，请返回聊天。"; return }
        guard canvas.drawing.strokes.isEmpty, note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "这一轮还有没交出的内容，请先交给下一位，再完成作品。"; return
        }
        if !store.finishSharedDrawing(request.id, revision: revision) { error = "请让至少两位成员各留下一轮，再完成作品。" }
    }

    private func submitRound() {
        guard request.space == store.state.mode else { error = "空间已经切换，请返回聊天。"; return }
        let drawing = canvas.drawing.strokes.isEmpty ? Data() : canvas.drawing.dataRepresentation()
        guard store.submitDrawingRound(request.id, drawing: drawing, note: note, revision: revision) else {
            error = "请先画一笔或写一句话；每轮最多128KB、共24轮。画布有更新时，请返回聊天重新打开。"; return
        }
        dismiss()
    }
}

@MainActor extension CircleStore {
    func saveSharedDrawingMemory(_ id: UUID) throws -> Bool {
        guard let i = current.messages.firstIndex(where: { $0.id == id }),
              let session = current.messages[i].sharedDrawing, session.finished, session.savedMemoryID == nil else { return false }
        let image = try SharedDrawingArt.image(session)
        guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let attachment = try savePhoto(data)
        let notes = session.rounds.map { "\($0.author)：\($0.note.isEmpty ? "添了一轮笔迹" : $0.note)" }.joined(separator: "\n")
        let memory = MemoryItem(title: "我们一起画的小日常", note: String(notes.prefix(2000)), kind: "照片", attachment: attachment)
        update { $0.memories.insert(memory, at: 0); $0.messages[i].sharedDrawing?.savedMemoryID = memory.id }
        return true
    }
}
