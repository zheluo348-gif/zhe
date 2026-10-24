import SwiftUI
import PencilKit
import AVFoundation

struct DrawingNoteView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PKCanvasView()
    @State private var color: Color = Palette.rose
    @State private var width: Double = 6
    @State private var erasing = false
    @State private var caption = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                HStack { Text("写几个字，也算一封信 ♡").font(.subheadline).foregroundStyle(Palette.rose); Spacer() }.padding(.horizontal, 22)
                CanvasBridge(canvas: canvas, color: UIColor(color), width: width, erasing: erasing)
                    .frame(maxWidth: .infinity).frame(maxHeight: .infinity).background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.border, lineWidth: 1))
                    .padding(.horizontal, 20).accessibilityIdentifier("drawingCanvas")
                HStack(spacing: 12) {
                    ForEach([Palette.rose, Palette.teal, Color(hex: 0x9286C5), Palette.ink], id: \.self) { c in
                        Button { color = c; erasing = false } label: { Circle().fill(c).frame(width: 30, height: 30).padding(4).overlay(Circle().stroke(color == c && !erasing ? Palette.rose : .clear, lineWidth: 2)) }.accessibilityLabel("选择画笔颜色")
                    }
                    Spacer()
                    Button { canvas.undoManager?.undo() } label: { Image(systemName: "arrow.uturn.backward").frame(width: 38, height: 44) }.accessibilityLabel("撤销")
                    Button { erasing.toggle() } label: { Image(systemName: "eraser").foregroundStyle(erasing ? Palette.rose : Palette.muted).frame(width: 38, height: 44) }.accessibilityLabel("橡皮擦")
                    Button { canvas.drawing = PKDrawing() } label: { Image(systemName: "trash").frame(width: 38, height: 44) }.accessibilityLabel("清空画布")
                }.padding(.horizontal, 20)
                HStack { Text("笔粗").font(.caption); Slider(value: $width, in: 2...16).tint(color) }.padding(.horizontal, 25)
                TextField("加一句话…", text: $caption).padding(15).background(.white, in: Capsule()).padding(.horizontal, 20)
                    .onChange(of: caption) { _, v in if v.count > 80 { caption = String(v.prefix(80)) } }
                PrimaryButton(title: "发送小纸条", symbol: "paperplane") { send() }.padding(.horizontal, 20).padding(.bottom, 15).accessibilityIdentifier("sendDrawing")
            }.background(Palette.cream).navigationTitle("画给TA").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
                .alert("纸条未发送", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(error ?? "") }
        }
    }
    func send() {
        guard !canvas.drawing.strokes.isEmpty || !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = "先画一笔，或者留一句话吧。"; return }
        let rect = CGRect(origin: .zero, size: canvas.bounds.size)
        guard rect.width > 0, rect.height > 0 else { return }
        let drawing = canvas.drawing.image(from: rect, scale: 2)
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        let image = UIGraphicsImageRenderer(size: CGSize(width: rect.width, height: rect.height + 65), format: format).image { ctx in
            UIColor(Palette.cream).setFill(); ctx.fill(CGRect(x: 0, y: 0, width: rect.width, height: rect.height + 65))
            drawing.draw(in: rect)
            (caption as NSString).draw(in: CGRect(x: 18, y: rect.height + 16, width: rect.width - 36, height: 42), withAttributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor(Palette.rose)])
        }
        do { try store.saveDrawing(image); dismiss() } catch { self.error = "保存失败，画布仍在，请重试。" }
    }
}
struct CanvasBridge: UIViewRepresentable {
    var canvas: PKCanvasView
    var color: UIColor
    var width: CGFloat
    var erasing: Bool
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput; canvas.backgroundColor = .clear; canvas.isOpaque = false
        canvas.isScrollEnabled = false
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = erasing ? PKEraserTool(.bitmap) : PKInkingTool(.pen, color: color, width: width)
    }
}
@MainActor final class VoiceRecorder: NSObject, ObservableObject {
    @Published var recording = false
    @Published var duration: TimeInterval = 0
    @Published var error: String?
    @Published var file: URL?
    @Published var playing = false
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    func begin() {
        AVAudioApplication.requestRecordPermission { [weak self] allowed in
            Task { @MainActor in
                guard let self else { return }
                guard allowed else { self.error = "麦克风未授权。可在系统设置中允许录音。"; return }
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try AVAudioSession.sharedInstance().setActive(true)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
                    self.recorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
                    self.recorder?.record(forDuration: 60); self.recording = true; self.duration = 0; self.file = url
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                        Task { @MainActor in
                            guard let self else { return }
                            self.duration = self.recorder?.currentTime ?? self.duration
                            if self.duration >= 59.9 || self.recorder?.isRecording == false { self.stop() }
                        }
                    }
                } catch { self.error = "暂时无法开始录音，请再试一次。" }
            }
        }
    }
    func stop() { duration = recorder?.currentTime ?? duration; recorder?.stop(); recording = false; timer?.invalidate() }
    func preview() {
        guard let file else { return }
        if playing { player?.stop(); playing = false; return }
        do {
            player = try AVAudioPlayer(contentsOf: file); player?.play(); playing = true
            let length = player?.duration ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + length) { [weak self] in self?.playing = false }
        } catch { self.error = "录音无法试听，请重新录制。" }
    }
    func cleanUp() {
        stop(); player?.stop()
        if let file { try? FileManager.default.removeItem(at: file) }
        self.file = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
struct VoiceNoteView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audio = VoiceRecorder()
    @State private var caption = ""
    var body: some View {
        NavigationStack {
            CreativePage(title: "留一句声音", subtitle: "先录下来、听一遍，再送到聊天里。") {
                TuantuanSticker(pose: 3).frame(height: 150).frame(maxWidth: .infinity)
                PaperCard(color: Palette.lavender) {
                    VStack(spacing: 24) {
                        Text(audio.recording ? "正在录音…" : audio.file == nil ? "留一句，只有你们懂的晚安" : "录好啦，先听一遍").font(.title3.bold())
                        HStack(spacing: 4) { ForEach(0..<25) { i in Capsule().fill(Palette.rose.opacity(0.65)).frame(width: 4, height: CGFloat([10, 20, 32, 17, 40, 27, 15][i % 7])) } }
                        Text(String(format: "00:%02d", Int(audio.duration))).font(.title3.monospacedDigit())
                    }.frame(maxWidth: .infinity)
                }
                TextField("加一句文字（可选）", text: $caption).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16))
                Button {
                    if audio.recording { audio.stop() } else { audio.begin() }
                } label: {
                    Image(systemName: audio.recording ? "stop.fill" : "mic.fill").font(.system(size: 33)).foregroundStyle(.white)
                        .frame(width: 86, height: 86).background(Palette.rose, in: Circle()).padding(10)
                        .background(Palette.pink, in: Circle())
                }.frame(maxWidth: .infinity).accessibilityLabel(audio.recording ? "结束录音" : "开始录音")
                Text("轻点录音，最长60秒。当前仅支持原声。").font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
                if audio.file != nil && !audio.recording {
                    Button(audio.playing ? "停止试听" : "试听原声") { audio.preview() }.frame(maxWidth: .infinity).frame(minHeight: 44)
                    PrimaryButton(title: "发送语音便签", symbol: "paperplane") {
                        guard let file = audio.file, audio.duration > 0.3 else { audio.error = "录音太短，再说一句吧。"; return }
                        do { try store.saveVoice(file, duration: audio.duration, caption: caption); dismiss() }
                        catch { audio.error = "语音未保存，请重试。" }
                    }
                }
            }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
                .alert("录音提示", isPresented: Binding(get: { audio.error != nil }, set: { if !$0 { audio.error = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(audio.error ?? "") }
        }.onDisappear { audio.cleanUp() }
    }
}
@MainActor extension CircleStore {
    var audioDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(ProcessInfo.processInfo.arguments.contains("--uitesting") ? "TestAudio" : "Audio", isDirectory: true)
    }
    func saveVoice(_ url: URL, duration: TimeInterval, caption: String) throws {
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        let filename = UUID().uuidString + ".m4a"
        try FileManager.default.copyItem(at: url, to: audioDirectory.appendingPathComponent(filename))
        let sender = myName
        update { $0.messages.append(ChatMessage(text: caption, sender: sender, mine: true, kind: "voice:\(Int(duration))", attachment: filename)) }
    }
    func voiceURL(_ name: String) -> URL? {
        guard !name.contains("/"), !name.contains(".."), name.hasSuffix(".m4a") else { return nil }
        return audioDirectory.appendingPathComponent(name)
    }
}
struct VoiceMessageCard: View {
    @EnvironmentObject var store: CircleStore
    var message: ChatMessage
    @State private var player: AVAudioPlayer?
    @State private var playing = false
    var body: some View {
        Button {
            if playing { player?.stop(); playing = false }
            else if let name = message.attachment, let url = store.voiceURL(name) {
                do { player = try AVAudioPlayer(contentsOf: url); player?.play(); playing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + (player?.duration ?? 1)) { playing = false }
                } catch { playing = false }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) { Image(systemName: playing ? "stop.circle.fill" : "play.circle.fill").font(.title); Image(systemName: "waveform").font(.title2); Text((message.kind.split(separator: ":").last.map(String.init) ?? "0") + "秒").font(.caption) }
                if !message.text.isEmpty { Text(message.text).font(.subheadline).lineLimit(3) }
            }.padding(17).foregroundStyle(Palette.rose).background(Palette.lavender, in: RoundedRectangle(cornerRadius: 19))
        }.buttonStyle(.plain).onDisappear { player?.stop(); playing = false }
    }
}

