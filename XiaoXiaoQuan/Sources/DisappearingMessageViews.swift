import SwiftUI

struct DisappearingMessageRequest: Identifiable {
    let id: UUID
    let space: String
}

struct DisappearingMessageCard: View {
    let message: ChatMessage
    var open: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let content = message.disappearing {
                let expired = content.readableBody(at: context.date) == nil
                PaperCard(color: expired ? Palette.cream : Palette.lavender, tape: false) {
                    Label(expired ? "消息已销毁" : "阅后即焚", systemImage: expired ? "flame.fill" : "lock.bubble")
                        .font(.headline)
                    if expired {
                        Text("内容已清除，无法再次查看。")
                            .font(.caption).foregroundStyle(Palette.muted)
                            .accessibilityIdentifier("disappearingExpired")
                    } else {
                        if let deadline = content.expiresAt {
                            Text("剩余 \(max(0, Int(ceil(deadline.timeIntervalSince(context.date))))) 秒")
                                .font(.caption).foregroundStyle(Palette.rose)
                        } else {
                            Text(content.duration.title).font(.caption).foregroundStyle(Palette.muted)
                        }
                        Button("本机点开查看") { open() }
                            .font(.subheadline.bold()).frame(minHeight: 44)
                            .accessibilityIdentifier("openDisappearingMessage")
                        Text("本机体验 · 尚未发送给其他设备").font(.system(size: 10)).foregroundStyle(Palette.muted)
                    }
                }.frame(maxWidth: 245)
            }
        }
    }
}

struct DisappearingMessageReader: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    let request: DisappearingMessageRequest

    private var content: DisappearingContent? {
        let data = request.space == "friends" ? store.state.friends : store.state.couple
        return data.messages.first { $0.id == request.id }?.disappearing
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Label("阅后即焚", systemImage: "flame").font(.title2.bold()).foregroundStyle(Palette.rose)
                        if phase == .active, let content, let text = content.readableBody(at: context.date), let deadline = content.expiresAt {
                            Text("\(max(0, Int(ceil(deadline.timeIntervalSince(context.date))))) 秒后销毁")
                                .font(.headline.monospacedDigit()).accessibilityIdentifier("burnCountdown")
                            Text(text).font(.title3).lineSpacing(8).textSelection(.disabled)
                                .privacySensitive().accessibilityIdentifier("disappearingBody")
                            Text("关闭页面不会暂停计时，到时自动清除内容。")
                                .font(.caption).foregroundStyle(Palette.muted)
                        } else {
                            Text(phase == .active ? "消息已销毁" : "内容已隐藏，计时继续")
                                .font(.headline).accessibilityIdentifier("disappearingHidden")
                        }
                        Text("本机体验，尚未与其他设备同步。").font(.caption).foregroundStyle(Palette.muted)
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                }.background(Palette.cream)
            }
            .navigationTitle("查看消息").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("返回聊天") { dismiss() }.accessibilityIdentifier("closeDisappearingMessage")
            } }
        }
        .onChange(of: content?.body) { _, value in if value == nil { dismiss() } }
    }
}
