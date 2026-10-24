import SwiftUI
import PhotosUI

struct CapsulesView: View {
    @EnvironmentObject var store: CircleStore
    @State private var adding = false
    var body: some View {
        CreativePage(title: "寄给未来的我们", subtitle: "有些小心事，留到刚刚好的那一天。") {
            HStack { MiniIllustration(index: 4).frame(width: 110, height: 120); VStack(alignment: .leading, spacing: 8) { Text("把今天，轻轻封存").font(.title3.bold()); Text("写一封信，放一张照片。\n等约好的日子再一起拆开。").font(.subheadline).foregroundStyle(Palette.muted) } }
            PrimaryButton(title: "埋一颗时光胶囊", symbol: "envelope.badge") { adding = true }.accessibilityIdentifier("addCapsule")
            if store.play.capsules.isEmpty { EmptyState(icon: "envelope", title: "未来的信箱还是空的", detail: "可以先写给下个生日，或一个普通的周末。") }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 15) {
                    ForEach(store.play.capsules) { letter in
                        NavigationLink { CapsuleDetailView(id: letter.id) } label: {
                            PaperCard(color: letter.opened ? Palette.mint : Palette.lavender) {
                                HStack { Image(systemName: letter.opened ? "envelope.open" : "lock.heart").font(.title); VStack(alignment: .leading, spacing: 7) { Text(letter.title).font(.headline); Text(letter.opensAt.formatted(date: .abbreviated, time: .shortened)).font(.caption); Text(letter.opened ? "已拆开，随时重读" : (letter.opensAt <= context.date ? "今天可以拆开啦" : "还没有到约好的日子")).font(.caption).foregroundStyle(Palette.teal) }; Spacer(); Image(systemName: "chevron.right") }
                            }
                        }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("capsule_\(letter.title)")
                    }
                }
            }
            Text("开发版按本机时间开启，信件仅保存在此设备。正式版将由服务器校验日期并同步。").font(.caption).foregroundStyle(Palette.muted)
        }.sheet(isPresented: $adding) { CapsuleEditorView() }
    }
}
struct CapsuleEditorView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var date = Date().addingTimeInterval(86400)
    @State private var photo: PhotosPickerItem?
    @State private var data: Data?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("写给未来的一点小心事") {
                    TextField("信封上的标题", text: $title).accessibilityIdentifier("capsuleTitle")
                    TextField("这封信想说…", text: $bodyText, axis: .vertical).lineLimit(6...12).accessibilityIdentifier("capsuleBody")
                }
                Section("约定拆开的时间") { DatePicker("开启时间", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute]) }
                Section {
                    PhotosPicker(selection: $photo, matching: .images) { Label(data == nil ? "放进一张照片" : "更换这张照片", systemImage: "photo") }
                    if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(height: 180); Button("移除照片", role: .destructive) { self.data = nil } }
                    if let error { Text(error).foregroundStyle(.red) }
                }
            }.navigationTitle("写一封未来信").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("封好") {
                    do { let attachment = try data.map { try store.savePhoto($0) }; store.addCapsule(title: title, body: bodyText, opensAt: date, photo: attachment); dismiss() }
                    catch { self.error = "照片没有保存成功，请重试。" }
                }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || date <= Date()).accessibilityIdentifier("sealCapsule") }
            }.onChange(of: photo) { _, item in Task { do { data = try await item?.loadTransferable(type: Data.self) } catch { self.error = "无法读取照片。" } } }
        }
    }
}
struct CapsuleDetailView: View {
    @EnvironmentObject var store: CircleStore
    let id: UUID
    var letter: TimeLetter? { store.play.capsules.first { $0.id == id } }
    var body: some View {
        CreativePage(title: "时光胶囊") {
            if let letter {
                MiniIllustration(index: 4).frame(height: 180).frame(maxWidth: .infinity)
                Text(letter.title).font(.title2.bold()).accessibilityIdentifier("capsuleDetailTitle")
                Text("约好在 \(letter.opensAt.formatted(date: .abbreviated, time: .shortened)) 拆开").font(.subheadline).foregroundStyle(Palette.muted)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if letter.opened && letter.opensAt <= context.date {
                        PaperCard { Text(letter.body).font(.body).lineSpacing(9).textSelection(.enabled).accessibilityIdentifier("openedLetter") }
                        if let name = letter.attachment, let image = store.photo(named: name) { Image(uiImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 20)) }
                    } else if context.date >= letter.opensAt {
                        PrimaryButton(title: "到时间啦，拆开看看", symbol: "envelope.open") { store.openCapsule(id) }.accessibilityIdentifier("openCapsule")
                    } else {
                        PaperCard(color: Palette.lavender) { Label("信已经封好了，让期待慢慢长大。", systemImage: "lock.heart").font(.headline).padding(.vertical, 20) }.accessibilityIdentifier("sealedLetter")
                    }
                }
            }
        }
    }
}
struct CircleCalendarView: View {
    @EnvironmentObject var store: CircleStore
    @State private var selected = Date()
    @State private var adding = false
    @State private var title = ""
    @State private var note = ""
    @State private var eventDate = Date()
    var events: [CircleEvent] { store.play.events.filter { Calendar.current.isDate($0.date, inSameDayAs: selected) }.sorted { $0.date < $1.date } }
    var body: some View {
        CreativePage(title: "把见面写进日历", subtitle: "聚会、纪念日，和普通的小约会。") {
            Surface { DatePicker("选一天", selection: $selected, displayedComponents: .date).datePickerStyle(.graphical) }
            HStack { Text(selected.formatted(.dateTime.month().day())).font(.title3.bold()); Spacer(); Button { eventDate = selected; adding = true } label: { Label("记一件事", systemImage: "plus") }.accessibilityIdentifier("addEvent") }
            if events.isEmpty { EmptyState(icon: "calendar.badge.plus", title: "这一天还没有安排", detail: "给期待留个位置吧。") }
            ForEach(events) { event in PaperCard(color: Palette.mint) {
                HStack { VStack(alignment: .leading, spacing: 8) { Text(event.title).font(.headline); Text(event.date.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(Palette.teal); if !event.note.isEmpty { Text(event.note).font(.subheadline) } }; Spacer(); Image(systemName: "calendar") }
            }.contextMenu { Button("删除这件事", role: .destructive) { store.updatePlay { $0.events.removeAll { $0.id == event.id } } } } }
            Text("本机日历记录；系统提醒和多人同步尚未接入。").font(.caption).foregroundStyle(Palette.muted)
        }.sheet(isPresented: $adding) {
            NavigationStack { Form {
                TextField("比如周末一起去看展", text: $title).accessibilityIdentifier("eventTitle")
                TextField("地点或小备注", text: $note)
                DatePicker("约好的时间", selection: $eventDate)
            }.navigationTitle("留一个小约会").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { adding = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { store.updatePlay { $0.events.append(CircleEvent(title: String(title.prefix(60)), note: String(note.prefix(300)), date: eventDate)) }; title = ""; note = ""; adding = false }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveEvent") }
            } }
        }
    }
}
struct ExpensesView: View {
    @EnvironmentObject var store: CircleStore
    @State private var adding = false
    @State private var title = ""
    @State private var amount = ""
    @State private var members: Set<String> = []
    var cents: Int? { guard let d = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")), d > 0, d <= 1000000 else { return nil }; let n = NSDecimalNumber(decimal: d * 100); guard n == n.rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)) else { return nil }; return n.intValue }
    var body: some View {
        CreativePage(title: "聚会小账本", subtitle: "把份额记清楚，开心的事慢慢聊。") {
            HStack { MiniIllustration(index: 11).frame(width: 100, height: 105); Text("这里只记账\n不收钱、不转账").font(.title3.bold()) }
            PrimaryButton(title: "记一笔聚会花费", symbol: "plus") { members = Set(store.memberNames); adding = true }.accessibilityIdentifier("addExpense")
            ForEach(store.play.expenses) { expense in
                Surface { VStack(alignment: .leading, spacing: 14) {
                    HStack { Text(expense.title).font(.headline); Spacer(); Text(String(format: "¥%.2f", Double(expense.cents) / 100)).font(.title3.bold()).foregroundStyle(Palette.teal) }
                    ForEach(Array(expense.members.enumerated()), id: \.element) { i, name in
                        let share = expense.cents / max(1, expense.members.count) + (i < expense.cents % max(1, expense.members.count) ? 1 : 0)
                        Button { store.updatePlay { p in if let index = p.expenses.firstIndex(where: { $0.id == expense.id }) { if p.expenses[index].paid.contains(name) { p.expenses[index].paid.remove(name) } else { p.expenses[index].paid.insert(name) } } } } label: {
                            HStack { Avatar(name: name, size: 30); Text(name); Spacer(); Text(String(format: "¥%.2f", Double(share) / 100)); Image(systemName: expense.paid.contains(name) ? "checkmark.circle.fill" : "circle").foregroundStyle(Palette.teal) }.font(.subheadline).frame(minHeight: 40)
                        }.buttonStyle(.plain).accessibilityIdentifier("paid_\(name)")
                    }
                    Text("点击仅标记本机已结清，不能证明实际付款。").font(.caption2).foregroundStyle(Palette.muted)
                } }.contextMenu { Button("删除账目", role: .destructive) { store.updatePlay { $0.expenses.removeAll { $0.id == expense.id } } } }
            }
            if store.play.expenses.isEmpty { EmptyState(icon: "pencil.and.list.clipboard", title: "还没有小账目", detail: "饭钱、车费、零食，都可以记下来。") }
        }.sheet(isPresented: $adding) {
            NavigationStack { Form {
                TextField("这笔钱花在哪里", text: $title).accessibilityIdentifier("expenseTitle")
                TextField("金额，最多两位小数", text: $amount).keyboardType(.decimalPad).accessibilityIdentifier("expenseAmount")
                Section("一起分摊的人") { ForEach(store.memberNames, id: \.self) { name in Toggle(name, isOn: Binding(get: { members.contains(name) }, set: { if $0 { members.insert(name) } else { members.remove(name) } })) } }
            }.navigationTitle("记一笔").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { adding = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { guard let cents else { return }; let list = store.memberNames.filter { members.contains($0) }; store.updatePlay { $0.expenses.insert(CircleExpense(title: String(title.prefix(60)), cents: cents, members: list), at: 0) }; title = ""; amount = ""; adding = false }.disabled(cents == nil || members.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveExpense") }
            } }
        }
    }
}
