import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: CircleStore
    @State private var adding = false
    @State private var title = ""
    @State private var goal = 1
    var body: some View {
        CreativePage(title: "今天的小习惯", subtitle: "一点一点就很好，忙几天也没关系。") {
            HStack {
                VStack(alignment: .leading, spacing: 6) { Text(Date().formatted(.dateTime.month().day().weekday(.wide))).font(.headline); Text("给认真生活的你，盖一个小印章").font(.caption).foregroundStyle(Palette.muted) }
                Spacer(); MiniIllustration(index: 0).frame(width: 90, height: 90)
            }
            HStack(spacing: 7) {
                ForEach(0..<7) { n in let day = Calendar.current.date(byAdding: .day, value: n - 6, to: Date())!
                    let key = CircleStore.dayKey(day)
                    let completed = store.play.habits.contains { ($0.counts[key] ?? 0) >= $0.goal }
                    VStack(spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.narrow))).font(.caption)
                        Image(systemName: completed ? "checkmark.seal.fill" : "circle.dotted").font(.title3).foregroundStyle(completed ? Palette.rose : Palette.muted.opacity(0.4))
                    }.frame(maxWidth: .infinity).padding(.vertical, 13).background(completed ? Palette.pink : .white, in: Capsule())
                }
            }
            ForEach(store.play.habits) { habit in
                let count = habit.counts[CircleStore.dayKey()] ?? 0
                Surface { HStack(spacing: 13) {
                    Image(systemName: habit.symbol).font(.title2).foregroundStyle(Palette.teal).frame(width: 47, height: 51).background(Palette.mint, in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(habit.title).font(.headline)
                        Text(count >= habit.goal ? "今天完成啦 · +2朵小红花" : "\(count) / \(habit.goal) 次").font(.caption).foregroundStyle(Palette.muted)
                        ProgressView(value: Double(min(count, habit.goal)), total: Double(habit.goal)).tint(Palette.rose)
                    }
                    Button { store.checkHabit(habit.id) } label: { Image(systemName: count >= habit.goal ? "checkmark" : "plus").font(.headline).foregroundStyle(.white).frame(width: 43, height: 43).background(count >= habit.goal ? Palette.teal : Palette.rose, in: Circle()) }.disabled(count >= habit.goal).accessibilityIdentifier("habit_\(habit.title)")
                } }
            }
            Button { adding = true } label: { Label("添加一个小习惯", systemImage: "plus.circle").frame(maxWidth: .infinity).frame(minHeight: 49) }.accessibilityIdentifier("addHabit")
            NavigationLink { HabitReportView() } label: { Surface { IconTile(icon: "leaf", title: "看看本周的小成长", subtitle: "只统计自己的真实记录", color: Palette.teal) } }.buttonStyle(.plain)
            ConnectionNote(text: "本机记录 · 每项每天完成后奖励一次 · 不清零惩罚")
        }.sheet(isPresented: $adding) {
            NavigationStack { Form {
                Section("小习惯") { TextField("比如：出门走十分钟", text: $title).accessibilityIdentifier("habitTitle"); Stepper("每天 \(goal) 次", value: $goal, in: 1...20) }
                Section { Text("每天达成目标后获得2朵虚拟小红花。分享和系统提醒后续接入。").font(.caption) }
            }.navigationTitle("添加小习惯").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { adding = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { store.addHabit(title, goal: goal); title = ""; goal = 1; adding = false }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveHabit") }
            } }
        }
    }
}
struct HabitReportView: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        CreativePage(title: "本周的小成长", subtitle: "给坚持一点掌声，也给休息一点空间。") {
            MiniIllustration(index: 0).frame(height: 140).frame(maxWidth: .infinity)
            ForEach(store.play.habits) { habit in
                let days = (0..<7).filter { n in let d = Calendar.current.date(byAdding: .day, value: -n, to: Date())!; return (habit.counts[CircleStore.dayKey(d)] ?? 0) >= habit.goal }.count
                Surface { HStack { Text(habit.title).font(.headline); Spacer(); Text("\(days) / 7 天").foregroundStyle(Palette.teal).bold() } }
            }
            PrimaryButton(title: "把本周记录发到聊天", symbol: "paperplane") {
                store.send("本周的小成长\n" + store.play.habits.map { h in
                    let total = (0..<7).reduce(0) { sum, n in sum + (h.counts[CircleStore.dayKey(Calendar.current.date(byAdding: .day, value: -n, to: Date())!)] ?? 0) }
                    return "\(h.title)：\(total)次"
                }.joined(separator: "\n"), kind: "plan")
                NotificationCenter.default.post(name: .circleOpenChat, object: nil)
            }
        }
    }
}
struct AgreementsView: View {
    @EnvironmentObject var store: CircleStore
    @State private var adding = false
    @State private var title = ""
    @State private var note = ""
    @State private var due = Date().addingTimeInterval(86400)
    @State private var flowers = 4
    var body: some View {
        CreativePage(title: "我们的小约定", subtitle: "一起商量，自愿接受，慢慢完成。") {
            HStack { MiniIllustration(index: 1).frame(width: 85, height: 88); Text("把一点期待\n写成一张小纸条").font(.title2.bold()).lineSpacing(7); Spacer() }
            if store.play.agreements.isEmpty { EmptyState(icon: "envelope.open", title: "第一张小纸条，写什么呢？", detail: "散步、早睡，或者一起做一顿饭。") }
            ForEach(store.play.agreements) { item in
                NavigationLink { AgreementDetailView(id: item.id) } label: {
                    PaperCard(color: item.state == "已完成" ? Color(hex: 0xDDEEE6) : Palette.pink) {
                        HStack { Text(item.title).font(.headline); Spacer(); Pill(text: item.state, color: item.state == "已完成" ? Palette.teal : Palette.rose) }
                        Text(item.note.isEmpty ? "留一点时间，做点小事" : item.note).font(.subheadline).foregroundStyle(Palette.muted)
                        HStack { Text(item.due.formatted(.dateTime.month().day())); Spacer(); Label("\(item.flowers)朵小红花", systemImage: "sparkle") }.font(.caption).foregroundStyle(Palette.rose)
                    }
                }.buttonStyle(.plain).foregroundStyle(Palette.ink)
            }
            PrimaryButton(title: "发起一张小约定", symbol: "plus") { adding = true }.accessibilityIdentifier("addAgreement")
            NavigationLink(value: Screen.rewards) { Label("去奖励小铺逛逛", systemImage: "ticket") }
            ConnectionNote(text: "本机轮流试玩 · 真实接受与协商由双方联网确认")
        }.sheet(isPresented: $adding) {
            NavigationStack { Form {
                Section("一起做什么") { TextField("比如：今晚一起散步", text: $title).accessibilityIdentifier("agreementTitle"); TextField("时间、地点或小心愿", text: $note, axis: .vertical).lineLimit(3...5) }
                Section { DatePicker("希望完成的日子", selection: $due, displayedComponents: [.date, .hourAndMinute]); Stepper("完成后 \(flowers) 朵小红花", value: $flowers, in: 1...20) }
            }.navigationTitle("发起小约定").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { adding = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { store.addAgreement(title, note: note, flowers: flowers, due: due); title = ""; note = ""; adding = false }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveAgreement") }
            } }
        }
    }
}
struct AgreementDetailView: View {
    @EnvironmentObject var store: CircleStore
    let id: UUID
    var body: some View {
        CreativePage(title: "一张小约定") {
            if let item = store.play.agreements.first(where: { $0.id == id }) {
                MiniIllustration(index: 1).frame(height: 145).frame(maxWidth: .infinity)
                PaperCard { Text(item.title).font(.title2.bold()); Text(item.note).font(.subheadline).lineSpacing(6); Text(item.due.formatted(.dateTime.month().day().hour().minute())).font(.caption).foregroundStyle(Palette.muted); Pill(text: item.state) }
                if item.state == "待接受" || item.state == "想商量" {
                    PrimaryButton(title: "接受这张小约定", symbol: "heart") { store.setAgreement(id, state: "已接受") }.accessibilityIdentifier("acceptAgreement")
                    if item.state == "待接受" { Button("我想再商量一下") { store.setAgreement(id, state: "想商量") }.frame(maxWidth: .infinity).frame(minHeight: 44) }
                } else if item.state == "已接受" {
                    PrimaryButton(title: "我们完成啦", symbol: "checkmark.seal") { store.setAgreement(id, state: "已完成") }.accessibilityIdentifier("completeAgreement")
                } else { Label("完成记录已保存，收好 \(item.flowers) 朵小红花", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(Palette.teal) }
                ConnectionNote(text: "同机试玩操作 · 不会自动替对方接受约定")
            }
        }
    }
}
struct RewardsView: View {
    @EnvironmentObject var store: CircleStore
    @State private var chosen: Int?
    @State private var message: String?
    let items = [("请你喝奶茶", 6), ("今晚电影你来选", 8), ("一顿你选的饭", 12), ("陪你散步一小时", 10)]
    var body: some View {
        CreativePage(title: "小红花奖励铺", subtitle: "虚拟的小花，换一张温柔的小心意。") {
            PaperCard { HStack { MiniIllustration(index: 7).frame(width: 95, height: 95); VStack(alignment: .leading, spacing: 9) { Text("\(store.play.flowers) 朵").font(.system(size: 34, weight: .bold)); Text("本机虚拟小红花 · 初次赠送12朵").font(.caption).foregroundStyle(Palette.muted) } } }.accessibilityIdentifier("flowerBalance")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                ForEach(0..<items.count, id: \.self) { i in
                    Button { chosen = i } label: {
                        VStack(spacing: 13) { MiniIllustration(index: [7, 9, 11, 6][i]).frame(height: 80); Text(items[i].0).font(.headline); Text("\(items[i].1)朵兑换").font(.caption).foregroundStyle(Palette.rose) }.frame(maxWidth: .infinity).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("reward_\(i)")
                }
            }
            if !store.play.rewards.isEmpty { Text("收进我的小票夹").font(.title3.bold()) }
            ForEach(store.play.rewards) { ticket in
                PaperCard(color: ticket.used ? Palette.lavender : Palette.pink) {
                    HStack { VStack(alignment: .leading, spacing: 7) { Text(ticket.title).font(.headline); Text(ticket.used ? "已标记使用" : "等你安排一个好日子").font(.caption).foregroundStyle(Palette.muted) }; Spacer()
                        Button(ticket.used ? "已使用" : "标记使用") { store.updatePlay { p in if let i = p.rewards.firstIndex(where: { $0.id == ticket.id }) { p.rewards[i].used = true } } }.disabled(ticket.used).font(.caption).accessibilityIdentifier("useReward")
                    }
                }
            }
            Text("只记录小心意，不付款、不自动下单。实际兑现由你们商量。").font(.caption).foregroundStyle(Palette.muted)
        }.alert("兑换这张小心意？", isPresented: Binding(get: { chosen != nil }, set: { if !$0 { chosen = nil } })) {
            Button("取消", role: .cancel) { chosen = nil }
            Button("确认兑换") {
                if let chosen { let item = items[chosen]; message = store.redeemReward(item.0, cost: item.1) ? "兑换成功，已放进小票夹。" : "小红花还不够，先完成一点小习惯吧。" }
                chosen = nil
            }
        } message: { if let chosen { Text("\(items[chosen].0) · 使用\(items[chosen].1)朵虚拟小红花") } }
            .alert("小票夹", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("知道了", role: .cancel) {} } message: { Text(message ?? "") }
    }
}

