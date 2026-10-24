import SwiftUI
import PencilKit

struct GomokuView: View {
    @EnvironmentObject var store: CircleStore
    @State private var reset = false
    var game: GomokuGame { store.play.gomoku }
    var body: some View {
        CreativePage(title: "小窝五子棋", subtitle: "同机轮流落子 · 9×9 · 连成五颗就获胜") {
            HStack { TuantuanSticker(pose: 4).frame(width: 86, height: 90); VStack(alignment: .leading, spacing: 7) {
                Text(game.winner > 0 ? "\(game.winner == 1 ? "黑" : "白")棋赢啦！" : (game.draw ? "这一局平分秋色" : "轮到\(game.turn == 1 ? "黑" : "白")棋" )).font(.title2.bold()).accessibilityIdentifier("gomokuStatus")
                Text("已经落下 \(game.moves.count) 颗小棋子").font(.caption).foregroundStyle(Palette.muted)
            } }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 9), spacing: 0) {
                ForEach(0..<81) { i in Button { store.updatePlay { $0.gomoku.place(i) } } label: {
                    ZStack {
                        Rectangle().fill(Palette.teal.opacity(0.13)).frame(height: 1)
                        Rectangle().fill(Palette.teal.opacity(0.13)).frame(width: 1)
                        if game.board[i] != 0 { Circle().fill(game.board[i] == 1 ? Palette.ink : Color.white).padding(3).shadow(color: .black.opacity(0.12), radius: 2, y: 2).overlay { if game.moves.last == i { Circle().fill(Palette.rose).frame(width: 5, height: 5) } } }
                        else { Color.clear }
                    }.aspectRatio(1, contentMode: .fit).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("cell_\(i)").accessibilityLabel("第\(i / 9 + 1)行第\(i % 9 + 1)列").accessibilityValue(game.board[i] == 0 ? "空位" : (game.board[i] == 1 ? "黑棋" : "白棋")) }
            }.padding(12).background(Color(hex: 0xE7ECDD), in: RoundedRectangle(cornerRadius: 22))
            HStack { Button("悔一手") { store.updatePlay { $0.gomoku.undo() } }.disabled(game.moves.isEmpty).accessibilityIdentifier("undoGomoku"); Spacer(); Button("重新开局") { reset = true }.accessibilityIdentifier("resetGomoku") }.frame(minHeight: 44)
            Text("离开也会保存棋盘。当前两人共用一台手机，联网对弈待接入。").font(.caption).foregroundStyle(Palette.muted)
            if game.winner > 0 || game.draw { PrimaryButton(title: "把这一局留在聊天", symbol: "paperplane") { store.send("小窝五子棋 · \(game.winner == 0 ? "平局" : (game.winner == 1 ? "黑棋胜出" : "白棋胜出"))\n一起下了\(game.moves.count)步。", kind: "quiz"); NotificationCenter.default.post(name: .circleOpenChat, object: nil) } }
        }.confirmationDialog("重新开一局？当前棋盘将被替换。", isPresented: $reset, titleVisibility: .visible) { Button("重新开局", role: .destructive) { store.updatePlay { $0.gomoku = GomokuGame() } } }
    }
}
struct TruthCardsView: View {
    @EnvironmentObject var store: CircleStore
    @State private var index = 0
    @State private var answer = ""
    @State private var sent = false
    private let questions = ["最近哪一个小瞬间，让你觉得被照顾了？", "如果一起开家小店，你想卖什么？", "你小时候最想实现的小愿望是什么？", "这周想和我一起完成的一件小事？", "你心中的完美周末，有哪三样东西？", "有哪一句话，你想再听我说一遍？", "想给未来的我们留一个什么暗号？", "我们一起做过最傻气又开心的事是什么？"]
    var body: some View {
        CreativePage(title: "拆一张真心话", subtitle: "不想答可以换一张，舒服最重要。") {
            TuantuanSticker(pose: 1).frame(height: 180).frame(maxWidth: .infinity)
            PaperCard(color: Palette.lavender) { Text(questions[index]).font(.title2.bold()).lineSpacing(9).padding(.vertical, 18) }
            Button("换一张小纸条") { index = (index + Int.random(in: 1..<questions.count)) % questions.count; answer = ""; sent = false }.frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("nextTruth")
            TextField("写一点你愿意分享的…", text: $answer, axis: .vertical).lineLimit(4...7).padding(20).background(.white, in: RoundedRectangle(cornerRadius: 20)).accessibilityIdentifier("truthAnswer")
                .onChange(of: answer) { _, v in if v.count > 500 { answer = String(v.prefix(500)) }; sent = false }
            PrimaryButton(title: sent ? "小心里话已收好" : "留在聊天里", symbol: "paperplane") { store.send("真心话小纸条\n\(questions[index])\n\(answer)", kind: "quiz"); sent = true }.disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sent).accessibilityIdentifier("sendTruth")
        }
    }
}
struct StoryRelayView: View {
    @EnvironmentObject var store: CircleStore
    @State private var line = ""
    @State private var reset = false
    var body: some View {
        CreativePage(title: "一人一句小故事", subtitle: "没有标准答案，胡思乱想也很可爱。") {
            PaperCard(color: Palette.mint) { HStack { TuantuanSticker(pose: 5).frame(width: 80, height: 92); VStack(alignment: .leading, spacing: 8) { Text("今天的开头").font(.caption.bold()).foregroundStyle(Palette.teal); Text("团团打开门，发现月亮寄来了一封信……").font(.headline).lineSpacing(5) } } }
            ForEach(Array(store.play.story.enumerated()), id: \.offset) { i, text in
                HStack(alignment: .top, spacing: 12) { Text("\(i + 1)").font(.headline).foregroundStyle(Palette.rose).frame(width: 28); Text(text).font(.body).lineSpacing(6); Spacer(minLength: 0) }.padding(18).background(i % 2 == 0 ? .white : Palette.lavender, in: RoundedRectangle(cornerRadius: 18))
            }
            Text("第 \(store.play.story.count + 1) 句 · 轮到 \(store.memberNames[store.play.story.count % store.memberNames.count])").font(.caption.bold()).foregroundStyle(Palette.teal)
            TextField("下一句会发生什么呢…", text: $line, axis: .vertical).lineLimit(2...4).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)).accessibilityIdentifier("storyLine").onChange(of: line) { _, v in if v.count > 200 { line = String(v.prefix(200)) } }
            PrimaryButton(title: "接上这一句", symbol: "pencil") { let value = line.trimmingCharacters(in: .whitespacesAndNewlines); store.updatePlay { $0.story.append(value) }; line = "" }.disabled(line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.play.story.count >= 30).accessibilityIdentifier("addStoryLine")
            if !store.play.story.isEmpty {
                Button { store.send("我们的小故事\n团团打开门，发现月亮寄来了一封信……\n" + String(store.play.story.joined(separator: "\n").prefix(1850)) + (store.play.story.joined().count > 1850 ? "\n完整故事保存在故事接龙里。" : ""), kind: "plan"); NotificationCenter.default.post(name: .circleOpenChat, object: nil) } label: { Label("把故事放进聊天", systemImage: "paperplane").frame(maxWidth: .infinity, minHeight: 44) }.accessibilityIdentifier("shareStory")
                Button("另开一个故事") { reset = true }.frame(maxWidth: .infinity, minHeight: 44)
            }
            ConnectionNote(text: "本机手动接龙 · 最多30句 · 已自动保存。AI续写待接入。")
        }.confirmationDialog("开启新故事会清空当前接龙，请先保存到聊天。", isPresented: $reset, titleVisibility: .visible) { Button("开启新故事", role: .destructive) { store.updatePlay { $0.story = [] } } }
    }
}
struct DrawGuessView: View {
    @EnvironmentObject var store: CircleStore
    @State private var stage = 0
    @State private var index = 0
    @State private var canvas = PKCanvasView()
    @State private var guess = ""
    @State private var shared = false
    @State private var error: String?
    private let words = ["小猫", "奶茶", "月亮", "雨伞", "蛋糕", "热气球", "小房子", "冰淇淋"]
    var body: some View {
        CreativePage(title: "你画我猜", subtitle: "同机轮流试玩 · 一个人画，另一个人猜") {
            if stage == 0 {
                TuantuanSticker(pose: 5).frame(height: 160).frame(maxWidth: .infinity)
                Text("画画的人，悄悄看题目").font(.title3.bold())
                PaperCard { Text(words[index]).font(.system(size: 38, weight: .bold)).frame(maxWidth: .infinity).padding(25) }
                Button("换一个好画的") { index = (index + 1) % words.count }.frame(maxWidth: .infinity, minHeight: 44)
                PrimaryButton(title: "藏好题目，开始画") { stage = 1 }.accessibilityIdentifier("startDrawGuess")
            } else if stage == 1 {
                Text("题目藏好啦，画出你的想法").font(.headline)
                CanvasBridge(canvas: canvas, color: UIColor(Palette.teal), width: 6, erasing: false).frame(height: 340).background(.white, in: RoundedRectangle(cornerRadius: 20)).clipped().accessibilityIdentifier("guessCanvas")
                HStack { Button("撤销") { canvas.undoManager?.undo() }; Spacer(); Button("重画") { canvas.drawing = PKDrawing() } }.frame(minHeight: 44)
                PrimaryButton(title: "画好啦，交给对方猜") { if !canvas.drawing.strokes.isEmpty { stage = 2 } else { error = "先画一点可爱的线条吧。" } }.accessibilityIdentifier("handoverDrawing")
            } else {
                Image(uiImage: canvas.drawing.image(from: CGRect(origin: .zero, size: canvas.bounds.size), scale: 2)).resizable().scaledToFit().frame(height: 300).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 20))
                if stage == 2 {
                    TextField("你猜画的是什么？", text: $guess).padding(18).background(.white, in: Capsule()).accessibilityIdentifier("drawingGuess")
                    PrimaryButton(title: "一起揭晓") { stage = 3 }.disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("revealDrawing")
                } else {
                    PaperCard(color: Palette.lavender) { Text("题目是：\(words[index])\n你猜的是：\(guess)\n\(guess.trimmingCharacters(in: .whitespacesAndNewlines) == words[index] ? "猜中啦，小默契加一！" : "原来是这样呀，也很可爱！")").font(.headline).lineSpacing(9) }
                    PrimaryButton(title: shared ? "画作已保存到聊天" : "收藏这张小画", symbol: "paperplane") { do { try store.saveDrawing(canvas.drawing.image(from: CGRect(origin: .zero, size: canvas.bounds.size), scale: 2)); shared = true } catch { self.error = "图片没有保存成功，请重试。" } }.disabled(shared)
                    Button("再画一张") { canvas.drawing = PKDrawing(); guess = ""; stage = 0; index = (index + 1) % words.count; shared = false }.frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }.alert("小提醒", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了") {} } message: { Text(error ?? "") }
    }
}
struct DecisionWheelView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editing = false
    @State private var optionsText = ""
    @State private var result: String?
    @State private var spinning = false
    @State private var rotation = 0.0
    let colors = [Palette.pink, Palette.mint, Palette.lavender, Color(hex: 0xF4E6CB)]
    var body: some View {
        CreativePage(title: "让小转盘决定", subtitle: "晚饭吃什么，周末去哪，把纠结转成小期待。") {
            ZStack {
                ForEach(Array(store.play.wheelOptions.enumerated()), id: \.offset) { i, option in
                    let count = store.play.wheelOptions.count
                    WheelSlice(start: Double(i) / Double(count) * 360, end: Double(i + 1) / Double(count) * 360).fill(colors[i % colors.count])
                    let angle = (Double(i) + 0.5) / Double(count) * 2 * Double.pi - Double.pi / 2
                    Text(option).font(.system(size: 13, weight: .semibold)).lineLimit(2).frame(width: 74).rotationEffect(.degrees(-rotation)).offset(x: cos(angle) * 94, y: sin(angle) * 94)
                }
                Circle().fill(Palette.cream).frame(width: 66, height: 66).overlay { Image(systemName: "heart.fill").font(.title2).foregroundStyle(Palette.rose) }
            }.rotationEffect(.degrees(rotation)).frame(width: 295, height: 295).frame(maxWidth: .infinity).overlay(alignment: .top) { Image(systemName: "arrowtriangle.down.fill").font(.title).foregroundStyle(Palette.rose).offset(y: -7) }.padding(.vertical, 15)
            if let result { PaperCard { Text("团团抽到了：\(result)").font(.title3.bold()).frame(maxWidth: .infinity) }.accessibilityIdentifier("wheelResult") }
            PrimaryButton(title: spinning ? "转呀转…" : "转一下", symbol: "arrow.clockwise") {
                spinning = true; result = nil
                let index = Int.random(in: 0..<store.play.wheelOptions.count)
                let old = rotation.truncatingRemainder(dividingBy: 360)
                let target = 360 - (Double(index) + 0.5) * 360 / Double(store.play.wheelOptions.count)
                let duration = reduceMotion || !store.creative.animations ? 0.05 : 1.4
                withAnimation(.easeOut(duration: duration)) { rotation += 1080 - old + target }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { result = store.play.wheelOptions[index]; spinning = false }
            }.disabled(spinning).accessibilityIdentifier("spinWheel")
            Button("换成我们自己的选项") { optionsText = store.play.wheelOptions.joined(separator: "，"); editing = true }.disabled(spinning).frame(maxWidth: .infinity, minHeight: 44)
            if let result { Button("把决定留在聊天") { store.send("小转盘的决定：\(result)\n只是一个小建议，我们都愿意再出发。", kind: "plan"); NotificationCenter.default.post(name: .circleOpenChat, object: nil) }.frame(maxWidth: .infinity, minHeight: 44) }
        }.sheet(isPresented: $editing) {
            NavigationStack { Form { TextField("用逗号分开2至8个选项", text: $optionsText, axis: .vertical).lineLimit(4...8); Text("每个选项最多8个字，重复的选项会合并。").font(.caption) }.navigationTitle("我们来定选项").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { editing = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { let values = parsedOptions; store.updatePlay { $0.wheelOptions = values }; result = nil; editing = false }.disabled(!(2...8).contains(parsedOptions.count)) }
            } }
        }
    }
    var parsedOptions: [String] { var seen = Set<String>(); return optionsText.components(separatedBy: CharacterSet(charactersIn: ",，\n")).map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8)) }.filter { !$0.isEmpty && seen.insert($0).inserted } }
}
struct WheelSlice: Shape {
    var start: Double
    var end: Double
    func path(in rect: CGRect) -> Path { var p = Path(); let c = CGPoint(x: rect.midX, y: rect.midY); p.move(to: c); p.addArc(center: c, radius: min(rect.width, rect.height) / 2, startAngle: .degrees(start - 90), endAngle: .degrees(end - 90), clockwise: false); p.closeSubpath(); return p }
}
