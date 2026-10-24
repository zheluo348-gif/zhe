import SwiftUI

@MainActor extension CircleStore {
    var isAIEnabled: Bool { state.aiEnabled ?? false }
    func setAIEnabled(_ enabled:Bool) { state.aiEnabled=enabled;persist() }
    func generateCreative(prompt:String,mode:String) async throws -> AIReply {
        guard isAIEnabled else { throw CreativeServiceError.disabled }
        let reply=try await CreativeService().generate(prompt:prompt,mode:mode,space:state.mode,userOptedIn:true)
        guard isAIEnabled else { throw CreativeServiceError.disabled }
        return reply
    }
}
struct AIAvailabilityNote:View {
    @EnvironmentObject var store:CircleStore
    var body: some View {
        VStack(alignment:.leading,spacing:9) {
            Label(store.isAIEnabled ? "已选择AI灵感 · 服务尚未连接":"基础玩法 · AI已关闭",systemImage:store.isAIEnabled ? "sparkles":"hand.draw").font(.caption).foregroundStyle(Palette.muted)
            if !store.isAIEnabled { NavigationLink(value:Screen.aiSettings) { Text("需要AI时，再去设置开启").font(.caption.bold()).frame(minHeight:35) } }
        }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(Palette.lavender.opacity(0.4),in:RoundedRectangle(cornerRadius:14))
    }
}
