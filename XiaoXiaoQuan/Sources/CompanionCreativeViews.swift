import SwiftUI

struct TuantuanPlayView: View {
    @EnvironmentObject var store: CircleStore
    @State private var prompt = ""
    @State private var showPlans = false
    @State private var selected = 0
    @State private var error: String?
    @State private var sent = false
    private let titles = ["家里电影夜", "公园散散步", "一起做顿饭"]
    private let icons = ["popcorn.fill", "tree.fill", "fork.knife"]
    var body: some View {
        CreativePage(title: showPlans ? "周末小盲盒" : "找团团玩") {
            if showPlans { plans } else {
                Text("有事叫团团，一起想点小主意。").font(.subheadline).foregroundStyle(Palette.muted)
                PaperCard { VStack(spacing: 0) {
                    TuantuanSticker(pose: 0).frame(height: 190).frame(maxWidth: .infinity)
                    Text("今天想一起做点什么？").font(.title3.bold()).frame(maxWidth: .infinity)
                } }
                ForEach(0..<3) { i in
                    if i == 1 {
                        NavigationLink(value: Screen.story) { activity(i) }.buttonStyle(.plain).accessibilityIdentifier("tuantuanActivity_\(i)")
                    } else if i == 2 {
                        NavigationLink(value: Screen.games) { activity(i) }.buttonStyle(.plain).accessibilityIdentifier("tuantuanActivity_\(i)")
                    } else {
                        Button {
                            if i == 0 { showPlans = true } else { error = "讲故事需要接入 AI 服务。你可以先体验周末灵感卡或默契问答。" }
                        } label: { activity(i) }.buttonStyle(.plain).accessibilityIdentifier("tuantuanActivity_\(i)")
                    }
                }
                if store.isAIEnabled {
                TextField("我们周末想轻松一点…", text: $prompt, axis: .vertical).lineLimit(1...3).padding(17).background(.white, in: RoundedRectangle(cornerRadius: 20))
                PrimaryButton(title: "交给团团想一想", symbol: "sparkles") {
                    error = CreativeServiceError.notConnected.localizedDescription
                }.disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                AIAvailabilityNote()
            }
        }.alert("团团的小提醒", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(error ?? "") }
            .alert("灵感卡已保存到聊天", isPresented: $sent) { Button("继续逛逛") {}; Button("查看聊天") { NotificationCenter.default.post(name: .circleOpenChat, object: nil) } } message: { Text("目前为本机保存，尚未发送给其他设备。") }
    }
    func activity(_ i: Int) -> some View {
        PaperCard(color: [Palette.pink, Palette.lavender, Color(hex: 0xDDEEE6)][i], tape: false) {
            HStack {
                TuantuanSticker(pose: [2, 3, 4][i]).frame(width: 66, height: 66)
                VStack(alignment: .leading, spacing: 5) {
                    Text(["安排周末", "讲个小故事", "出一道题"][i]).font(.headline)
                    Text(["拆开一个轻松的小计划", "让日常多一点想象", "看看大家的小默契"][i]).font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer(); Image(systemName: "chevron.right").font(.caption)
            }
        }.foregroundStyle(Palette.ink)
    }
    var plans: some View {
        VStack(alignment: .leading, spacing: 22) {
            Pill(text: "预置灵感卡 · 本机体验", color: Palette.teal)
            TuantuanSticker(pose: 2).frame(height: 130).frame(maxWidth: .infinity)
            VStack(spacing: 12) {
                ForEach(0..<3) { i in Button { selected = i } label: {
                    HStack(spacing: 16) {
                        Image(systemName: icons[i]).font(.system(size: 28)).foregroundStyle([Palette.rose, Palette.teal, Color.brown][i]).frame(width: 55)
                        VStack(alignment: .leading, spacing: 5) { Text(titles[i]).font(.headline); Text(["选一部片，准备喜欢的零食", "留一段不赶时间的散步", "买点食材，一起慢慢做饭"][i]).font(.caption).foregroundStyle(Palette.muted) }
                        Spacer(); Image(systemName: selected == i ? "checkmark.circle.fill" : "circle").foregroundStyle(Palette.rose)
                    }.padding(17).background(selected == i ? Palette.pink : .white, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain) }
            }
            PaperCard { VStack(alignment: .leading, spacing: 13) {
                Text("已选：\(titles[selected])").font(.headline)
                Text([ "① 选一部片\n② 准备零食\n③ 留一张合照", "① 选条喜欢的小路\n② 带好水和纸巾\n③ 看看路边的小花", "① 一起选菜\n② 分工做饭\n③ 拍下出锅的瞬间"][selected]).font(.subheadline).lineSpacing(10)
            } }
            PrimaryButton(title: "发到聊天", symbol: "paperplane") { store.send("周末灵感：\(titles[selected])\n一起留一点不赶时间的日常。", kind: "plan"); sent = true }.accessibilityIdentifier("sendWeekendPlan")
            Button("返回团团") { showPlans = false }.frame(maxWidth: .infinity).frame(minHeight: 44)
        }
    }
}
extension Notification.Name {
    static let circleOpenChat = Notification.Name("circleOpenChat")
    static let circleOpenHome = Notification.Name("circleOpenHome")
}

struct ExpressionView: View {
    @EnvironmentObject var store: CircleStore
    @State private var original = ""
    @State private var suggestion = ""
    @State private var tone = "温柔一点"
    @State private var showError = false
    var body: some View {
        CreativePage(title: "帮我表达", subtitle: "保留你的意思，找到更舒服的说法。") {
            PaperCard {
                TextField("写下你想说的话…", text: $original, axis: .vertical).lineLimit(3...5).font(.title3)
                    .accessibilityIdentifier("expressionOriginal")
                Text("\(original.count)/200").font(.caption).foregroundStyle(Palette.muted).frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack { ForEach(["温柔一点", "俏皮一点", "说清楚"], id: \.self) { name in ChoiceChip(title: name, selected: tone == name) { tone = name } } }
            if store.isAIEnabled { PrimaryButton(title: "让 AI 帮我想想", symbol: "sparkles") { showError = true }.disabled(original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            Button("试用本机表达模板") {
                suggestion = tone == "温柔一点" ? "有件小事想和你聊聊：\(original)\n也想听听你的想法。"
                    : tone == "俏皮一点" ? "叮～有一句小心里话想送达：\(original) ♡"
                    : "我想表达的是：\(original)\n我们可以一起商量一下吗？"
            }.frame(maxWidth: .infinity).frame(minHeight: 44).disabled(original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if !suggestion.isEmpty {
                PaperCard(color: Palette.lavender) { VStack(alignment: .leading, spacing: 12) {
                    Pill(text: "本机模板 · 可修改", color: Palette.teal)
                    TextField("修改后再使用", text: $suggestion, axis: .vertical).lineLimit(4...7).accessibilityIdentifier("expressionSuggestion")
                } }
                PrimaryButton(title: "放回输入框", symbol: "arrow.uturn.backward") {
                    store.update { $0.draft = suggestion }
                    NotificationCenter.default.post(name: .circleOpenChat, object: nil)
                }.accessibilityIdentifier("returnExpressionDraft")
                Text("回到聊天后，由你修改并点击发送。").font(.caption).foregroundStyle(Palette.muted)
            }
            AIAvailabilityNote()
        }.onAppear { original = store.creative.expressionDraft }
            .onChange(of: original) { _, v in
                if v.count > 200 { original = String(v.prefix(200)) }
                store.updateCreative { $0.expressionDraft = String(v.prefix(200)) }
            }
            .alert("AI 服务尚未连接", isPresented: $showError) { Button("知道了", role: .cancel) {} } message: { Text("原句已保留。你可以先试用本机表达模板，正式 AI 结果将在服务接通后提供。") }
    }
}
struct GameHubView: View {
    @EnvironmentObject var store: CircleStore
    @State private var playing = false
    var body: some View {
        CreativePage(title: "今晚玩什么", subtitle: "和喜欢的人，一起做点有趣的小事。") {
            HStack { Text("没话题？来玩一下").font(.system(size: 27, weight: .bold)); Spacer(); TuantuanSticker(pose: 4).frame(width: 110, height: 120) }
            GameInviteStrip()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                Button { if store.creative.quiz == nil || store.creative.quiz?.finished == true { store.startQuiz() }; playing = true } label: { ArtFeatureCard(title: "默契猜猜", detail: "本机轮流试玩 · 3题", pose: 0, color: Palette.pink) }.accessibilityIdentifier("startQuiz")
                NavigationLink(value: Screen.story) { ArtFeatureCard(title: "故事接龙", detail: "一人一句，天马行空", pose: 5, color: Color(hex: 0xDDEEE6)) }.accessibilityIdentifier("game_story")
                NavigationLink(value: Screen.drawGuess) { ArtFeatureCard(title: "你画我猜", detail: "藏好题目，再一起揭晓", pose: 5, color: Palette.lavender) }.accessibilityIdentifier("game_drawGuess")
                NavigationLink(value: Screen.gomoku) { ArtFeatureCard(title: "小窝五子棋", detail: "轮流落子，连成五颗", pose: 4, color: Color(hex: 0xF9ECD2)) }.accessibilityIdentifier("game_gomoku")
                NavigationLink(value: Screen.truth) { ArtFeatureCard(title: "真心话纸条", detail: "不想答，就换一张", pose: 1, color: Palette.pink) }.accessibilityIdentifier("game_truth")
                NavigationLink(value: Screen.wheel) { ArtFeatureCard(title: "决定小转盘", detail: "把纠结变成小期待", pose: 2, color: Palette.mint) }.accessibilityIdentifier("game_wheel")
            }.buttonStyle(.plain)
            ConnectionNote(text: "当前题目来自本机样例题库。联网开局和 AI 出题待接入。")
        }.navigationDestination(isPresented: $playing) { QuizPlayView() }
    }
}
struct QuizPlayView: View {
    @EnvironmentObject var store: CircleStore
    @State private var selection: Int?
    @State private var betweenPlayers = false
    @State private var shared = false
    private let questions = ["突然多一天假，我们最想去哪里？", "今晚一起做点什么最开心？", "送团团一件小礼物，你选什么？"]
    private let options = [["海边", "山里", "宅家", "逛吃"], ["看电影", "散散步", "做顿饭", "玩游戏"], ["小围巾", "小饼干", "小枕头", "小画笔"]]
    private let symbols = [["sun.horizon.fill", "mountain.2.fill", "house.fill", "fork.knife"], ["film.fill", "figure.walk", "carrot.fill", "gamecontroller.fill"], ["tshirt.fill", "birthday.cake.fill", "bed.double.fill", "paintbrush.pointed.fill"]]
    var quiz: QuizSession { store.creative.quiz ?? QuizSession(players: ["小糖", "阿哲"]) }
    var body: some View {
        CreativePage(title: quiz.revealed ? "揭晓啦" : "默契猜猜") {
            ConnectionNote(text: "同机轮流试玩 · 题库样例 · 尚未联网")
            if quiz.finished {
                TuantuanSticker(pose: 0).frame(height: 230).frame(maxWidth: .infinity)
                Text("今天的小默契，收好啦").font(.title2.bold())
                PrimaryButton(title: "再玩一局") { store.startQuiz(); selection = nil; betweenPlayers = false }
            } else if quiz.revealed { reveal }
            else if betweenPlayers { handover }
            else { question }
        }
    }
    var question: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Pill(text: "\(quiz.round + 1) / 3"); Spacer(); Text("轮到 \(quiz.players[min(quiz.player, quiz.players.count - 1)])").font(.subheadline.bold()) }
            PaperCard(color: Palette.pink) { Text(questions[quiz.round]).font(.system(size: 25, weight: .bold)).lineSpacing(8) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                ForEach(0..<4) { i in Button { selection = i } label: {
                    VStack(spacing: 20) {
                        Image(systemName: symbols[quiz.round][i]).font(.system(size: 39)).foregroundStyle([Palette.teal, Palette.rose, Color.brown, Color(hex: 0x8682BF)][i])
                        Text(options[quiz.round][i]).font(.headline)
                    }.frame(maxWidth: .infinity).frame(height: 145).background(selection == i ? Palette.pink : .white, in: RoundedRectangle(cornerRadius: 21))
                        .overlay(RoundedRectangle(cornerRadius: 21).stroke(selection == i ? Palette.rose : Palette.border, lineWidth: selection == i ? 2 : 1))
                }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("quizChoice_\(i)") }
            }
            Text("每个人选好以后，再一起揭晓。").font(.caption).foregroundStyle(Palette.muted)
            PrimaryButton(title: "提交我的选择", symbol: "checkmark") {
                guard let selection else { return }
                store.submitQuizAnswer(selection); self.selection = nil
                betweenPlayers = !quiz.revealed
            }.disabled(selection == nil).opacity(selection == nil ? 0.5 : 1).accessibilityIdentifier("submitQuiz")
        }
    }
    var handover: some View {
        VStack(spacing: 25) {
            TuantuanSticker(pose: 1).frame(height: 235).frame(maxWidth: .infinity)
            Text("答案先替你收好了").font(.title2.bold())
            Text("把手机交给 \(quiz.players[min(quiz.player, quiz.players.count - 1)])\n独立选好自己的答案。").font(.headline).multilineTextAlignment(.center).lineSpacing(9)
            PrimaryButton(title: "我是\(quiz.players[min(quiz.player, quiz.players.count - 1)])，开始选") { betweenPlayers = false }.accessibilityIdentifier("nextQuizPlayer")
        }
    }
    var reveal: some View {
        VStack(alignment: .leading, spacing: 22) {
            let same = Set(quiz.answers.values).count == 1
            PaperCard { Text(same ? "这题想到一起啦！" : "原来你想的是这个呀！").font(.system(size: 27, weight: .bold)) }
            TuantuanSticker(pose: same ? 0 : 2).frame(height: 185).frame(maxWidth: .infinity)
            ForEach(quiz.players, id: \.self) { name in
                HStack { Avatar(name: name); Text(name).font(.headline); Spacer(); Text(options[quiz.round][quiz.answers[name] ?? 0]).font(.headline).foregroundStyle(Palette.teal) }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 17))
            }
            Text(same ? "把这点小默契，留在今天的聊天里。" : "不一样的选择，也能一起慢慢聊。").font(.subheadline).foregroundStyle(Palette.muted)
            Button { store.send("默契猜猜 · \(questions[quiz.round])\n" + quiz.players.map { "\($0)：\(options[quiz.round][quiz.answers[$0] ?? 0])" }.joined(separator: "\n"), kind: "quiz"); shared = true } label: {
                Label(shared ? "已保存到聊天" : "把这题发到聊天", systemImage: shared ? "checkmark" : "paperplane").frame(maxWidth: .infinity).frame(minHeight: 48)
            }.disabled(shared).accessibilityIdentifier("shareQuiz")
            PrimaryButton(title: quiz.round == 2 ? "完成这局" : "下一题") { store.nextQuizRound(); selection = nil; shared = false; betweenPlayers = false }.accessibilityIdentifier("nextQuizRound")
        }
    }
}

