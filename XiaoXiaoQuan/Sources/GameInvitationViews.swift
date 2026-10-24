import SwiftUI

struct GameInvitationCard: View {
    @EnvironmentObject var store: CircleStore
    let message:ChatMessage
    var play:()->Void
    var body: some View {
        if let invite=message.invitation {
            PaperCard(color:invite.state=="收好小回忆" ? Palette.mint:Palette.lavender,tape:false) {
                HStack(spacing:10) { TuantuanSticker(pose:invite.game == .story ? 5:4).frame(width:64,height:73); VStack(alignment:.leading,spacing:8) { Text(invite.game.title).font(.headline); Text(invite.state).font(.caption.bold()).foregroundStyle(Palette.teal) } }
                if let summary=invite.summary { Text(summary).font(.subheadline).lineSpacing(6) }
                else { Text(store.friends ? "大家各接一点，把今天玩成小故事。":"想和你一起，留一点好玩的日常。").font(.system(size:12)).foregroundStyle(Palette.muted) }
                Button(invite.state=="等你来玩" ? "本机接受并试玩":(invite.state=="一起玩着" ? "继续这一局":"再去看看")) { store.acceptInvitation(message.id);play() }.font(.subheadline.bold()).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:41).background(Palette.rose,in:Capsule()).accessibilityIdentifier("playInvitation")
                Text("本机轮流试玩 · 还未发送给对方").font(.system(size:9)).foregroundStyle(Palette.muted)
            }.frame(maxWidth:257)
        }
    }
}
struct GameInvitationSheet:View {
    @EnvironmentObject var store:CircleStore
    @Environment(\.dismiss) private var dismiss
    let message:ChatMessage
    @State private var confirmClose=false
    var body: some View {
        NavigationStack {
            Group {
                switch message.invitation?.game ?? .story {
                case .quiz: QuizPlayView()
                case .story: StoryRelayView()
                case .gomoku: GomokuView()
                }
            }.safeAreaInset(edge:.bottom) {
                VStack(spacing:7) {
                    Button { store.finishInvitation(message.id);dismiss() } label:{ Label("收好结果，回到聊天",systemImage:"bookmark").font(.system(size:13,weight:.semibold)).frame(maxWidth:.infinity,minHeight:43).foregroundStyle(.white).background(Palette.teal,in:Capsule()) }.disabled(store.invitationSummary(message.id)==nil).opacity(store.invitationSummary(message.id)==nil ? 0.45:1).accessibilityIdentifier("finishInvitation")
                    Text("本机游戏邀请 · 完成后结果留在同一张卡片").font(.system(size:9)).foregroundStyle(Palette.muted)
                }.padding(.horizontal,20).padding(.vertical,9).background(Palette.cream)
            }.onReceive(NotificationCenter.default.publisher(for:.circleOpenChat)) { _ in store.finishInvitation(message.id);dismiss() }.toolbar { ToolbarItem(placement:.cancellationAction) { Button("先回聊天") { dismiss() }.accessibilityIdentifier("closeInvitationGame") } }
        }
    }
}
struct GameInviteStrip:View {
    @EnvironmentObject var store:CircleStore
    var body: some View {
        PaperCard(color:.white,tape:false) {
            Text(store.friends ? "叫大家来玩，结果留在群聊里":"发一张邀请，玩完继续聊").font(.subheadline.bold())
            HStack(spacing:7) { ForEach(InvitationGame.allCases) { game in Button { store.inviteToPlay(game);NotificationCenter.default.post(name:.circleOpenChat,object:nil) } label:{ VStack(spacing:8) { Image(systemName:game.symbol).font(.title3); Text(game.title).font(.system(size:11,weight:.semibold)) }.frame(maxWidth:.infinity,minHeight:66).foregroundStyle(Palette.rose).background(Palette.pink.opacity(0.6),in:RoundedRectangle(cornerRadius:14)) }.buttonStyle(.plain).accessibilityIdentifier("invite_\(game.rawValue)") } }
        }
    }
}
