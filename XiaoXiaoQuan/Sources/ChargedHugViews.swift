import SwiftUI
import UIKit

struct HugPreviewRequest: Identifiable {
    let message: ChatMessage
    var id: UUID { message.id }
}
extension ChatMessage {
    var isHug: Bool { kind == "hug" || kind.hasPrefix("hug:") }
    var hugLevel: Int { min(3,max(1,Int(kind.split(separator:":").last ?? "1") ?? 1)) }
}
struct HugChargeButton: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var sent: (Int) -> Void
    @State private var start: Date?
    @State private var progress = 0.0
    @State private var timer: Timer?
    @State private var lastLevel = 1
    var body: some View {
        HugPressSurface(title:start == nil ? "贴贴" : (progress >= 1 ? "宇宙抱抱" : (progress >= (0.7/1.5) ? "星星抱抱":"软软抱抱")),pressed:start != nil,onDown:begin,onRelease:release,onCancel:cancel)
            .frame(maxWidth:.infinity).frame(height:41)
            .overlay(alignment:.bottom) { if start != nil { GeometryReader { g in Capsule().fill(Palette.rose).frame(width:g.size.width*progress,height:3) }.frame(height:3).padding(.horizontal,11).offset(y:-3).allowsHitTesting(false) } }
            .overlay(alignment:.top) { if start != nil { Text(progress>=1 ? "蓄满啦，松手送出宇宙抱抱":"抱紧一点…松手就送出").font(.system(size:11,weight:.semibold)).foregroundStyle(Palette.rose).fixedSize().padding(.horizontal,12).padding(.vertical,8).background(Palette.pink,in:Capsule()).offset(x:55,y:-39).allowsHitTesting(false) } }
            .onDisappear { cancel() }
            .onReceive(NotificationCenter.default.publisher(for:UIApplication.willResignActiveNotification)) { _ in cancel() }
    }
    func begin() {
        guard start == nil else { return }
        start=Date();progress=0;lastLevel=1
        if store.state.haptics { UIImpactFeedbackGenerator(style:.soft).impactOccurred() }
        timer=Timer.scheduledTimer(withTimeInterval:0.04,repeats:true) { _ in Task { @MainActor in
            guard let start else { return }; progress=min(1,Date().timeIntervalSince(start)/1.5)
            let level=progress>=1 ? 3:(progress>=(0.7/1.5) ? 2:1)
            if level != lastLevel { lastLevel=level; if store.state.haptics { UIImpactFeedbackGenerator(style:.light).impactOccurred() } }
        } }
    }
    func release() { guard let start else { return }; let duration=Date().timeIntervalSince(start); let level=duration>=1.5 ? 3:(duration>=0.7 ? 2:1); cancel(); sent(level) }
    func cancel() { timer?.invalidate();timer=nil;start=nil;progress=0 }
}
final class HugAccessibleButton: UIButton {
    override func accessibilityActivate() -> Bool { sendActions(for:.touchDown);sendActions(for:.touchUpInside);return true }
}
struct HugPressSurface: UIViewRepresentable {
    var title: String
    var pressed: Bool
    var onDown: () -> Void
    var onRelease: () -> Void
    var onCancel: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context:Context) -> UIButton {
        let b=HugAccessibleButton(type:.custom);b.layer.cornerRadius=20;b.titleLabel?.font=UIFont.systemFont(ofSize:12,weight:.medium);b.titleLabel?.adjustsFontSizeToFitWidth=true;b.titleLabel?.minimumScaleFactor=0.75
        b.setImage(UIImage(systemName:"heart.fill"),for:.normal);b.tintColor=UIColor(Palette.rose)
        b.addTarget(context.coordinator,action:#selector(Coordinator.down),for:.touchDown)
        b.addTarget(context.coordinator,action:#selector(Coordinator.up),for:.touchUpInside)
        b.addTarget(context.coordinator,action:#selector(Coordinator.cancel),for:[.touchUpOutside,.touchCancel,.touchDragExit])
        b.accessibilityIdentifier="sendHug";b.accessibilityHint="轻点送软软抱抱，长按蓄力后松手送出，移出按钮取消"
        return b
    }
    func updateUIView(_ b:UIButton,context:Context) { context.coordinator.parent=self;b.setTitle(" "+title,for:.normal);b.setTitleColor(UIColor(Palette.ink),for:.normal);b.backgroundColor=UIColor(pressed ? Palette.pink:.white);b.layer.borderColor=UIColor(Palette.border.opacity(0.7)).cgColor;b.layer.borderWidth=1;b.accessibilityLabel=title }
    @MainActor final class Coordinator:NSObject {
        var parent:HugPressSurface
        init(_ parent:HugPressSurface) { self.parent=parent }
        @objc func down() { parent.onDown() }
        @objc func up() { parent.onRelease() }
        @objc func cancel() { parent.onCancel() }
    }
}
struct HugMessageCard: View {
    @EnvironmentObject var store: CircleStore
    let message: ChatMessage
    var show: () -> Void
    var accepted: Bool { store.creative.acceptedHugs.contains(message.id.uuidString) }
    private var title: String { ["软软抱抱","星星抱抱","宇宙抱抱"][message.hugLevel-1] }
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack(spacing:10) {
                TuantuanSticker(pose:0).frame(width:75,height:96)
                VStack(alignment:.leading,spacing:9) {
                    Text(accepted ? "抱抱接住啦 ♡":title).font(.headline)
                    Text(["留一点温柔给你","抱抱里装了小星星","跨过星河，也要抱住你"][message.hugLevel-1]).font(.system(size:11)).foregroundStyle(Palette.muted)
                    if message.mine {
                        Button("看看TA收到时") { show() }.font(.system(size:12,weight:.semibold)).foregroundStyle(Palette.rose).accessibilityIdentifier("previewHug")
                    } else {
                        Button { store.acceptHug(message.id);show() } label: { Text(accepted ? "再看一次":"接住抱抱").font(.system(size:13,weight:.semibold)).foregroundStyle(.white).padding(.horizontal,18).padding(.vertical,10).background(Palette.rose,in:Capsule()) }.accessibilityIdentifier("acceptHug")
                    }
                }
            }
            HStack(spacing:4) { ForEach(0..<message.hugLevel,id:\.self) { _ in Image(systemName:"heart.fill").font(.system(size:10)) }; Spacer();Text(message.mine ? "本机保存 · 接收效果可预览":"历史示例 · 点击试玩").font(.system(size:9)) }.foregroundStyle(Palette.rose.opacity(0.8))
        }.padding(15).frame(width:248).background(message.hugLevel==3 ? Palette.lavender:Palette.pink,in:RoundedRectangle(cornerRadius:23))
    }
}
struct HugReceiverPreview: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: ChatMessage
    @State private var burst = UUID()
    var level:Int { message.hugLevel }
    var accepted:Bool { store.creative.acceptedHugs.contains(message.id.uuidString) }
    var body: some View {
        ZStack {
            LinearGradient(colors:level==3 ? [Color(hex:0x2C294C),Color(hex:0x614A76),Color(hex:0xAC7397)] : (level==2 ? [Color(hex:0xE7DDF3),Color(hex:0xF5DEEA),Palette.cream]:[Palette.cream,Palette.pink]),startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea()
            if store.creative.animations && !reduceMotion { HugBurst(level:level).id(burst).allowsHitTesting(false) }
            VStack(spacing:20) {
                HStack { Label("接收效果预览 · 本机模拟",systemImage:"eye").font(.system(size:11,weight:.semibold)); Spacer(); Button { dismiss() } label: { Image(systemName:"xmark").font(.headline).frame(width:40,height:40).background(.white.opacity(0.15),in:Circle()) }.accessibilityIdentifier("closeHugPreview") }
                Spacer()
                Text(message.mine ? "阿哲收到的画面":"你收到的抱抱").font(.subheadline).opacity(0.8)
                Text(["软软地，抱住你","星星都向你靠近","整个宇宙，都在抱你"][level-1]).font(.system(size:29,weight:.bold)).multilineTextAlignment(.center).lineSpacing(9).accessibilityIdentifier("hugEffectTitle")
                ZStack {
                    ForEach(0..<(level+1),id:\.self) { i in Circle().stroke(.white.opacity(0.15+Double(i)*0.08),lineWidth:1.2).frame(width:CGFloat(180+i*38),height:CGFloat(180+i*38)) }
                    TuantuanSticker(pose:0).frame(width:220,height:245)
                }.frame(height:310)
                Text("\(message.mine ? store.myName:message.sender) 送来一记\(["软软抱抱","星星抱抱","宇宙抱抱"][level-1])").font(.headline)
                PrimaryButton(title:accepted ? "本机试玩已接住 ♡":"本机模拟接住",symbol:"heart.fill",color:level==3 ? Color(hex:0xA36995):Palette.rose) { store.acceptHug(message.id);burst=UUID();if store.state.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) } }.disabled(accepted).accessibilityIdentifier("receivePreviewHug")
                Button("再看一次效果") { burst=UUID() }.font(.subheadline).frame(minHeight:44).accessibilityIdentifier("replayHugEffect")
                Spacer()
                Text("这是接收端视觉预览，尚未发送到对方手机。\n真实两台设备连接后，才会同步触发此效果。").font(.system(size:11)).multilineTextAlignment(.center).lineSpacing(5).opacity(0.7)
            }.padding(24).foregroundStyle(level==3 ? .white:Palette.ink)
        }.accessibilityElement(children:.contain).accessibilityIdentifier("hugReceiverPreview")
    }
}
struct HugBurst: View {
    let level:Int
    @State private var move=false
    var body: some View {
        GeometryReader { g in
            ZStack {
                ForEach(0..<(8+level*6),id:\.self) { i in
                    let x=CGFloat((i*37+11)%97)/100,y=CGFloat((i*23+7)%91)/100
                    Image(systemName:i%3==0 && level>1 ? "sparkle":"heart.fill").font(.system(size:CGFloat(11+(i%4)*8))).foregroundStyle(level==3 ? Color(hex:0xF3D0E3):Palette.rose.opacity(0.45)).rotationEffect(.degrees(Double(i*27))).position(x:g.size.width*x,y:move ? g.size.height*(y-0.14):g.size.height*(y+0.16)).opacity(move ? 0.2:0.85)
                }
                if level==3 { Ellipse().stroke(Color(hex:0xD7B9F2).opacity(0.5),lineWidth:2).frame(width:g.size.width*1.15,height:170).rotationEffect(.degrees(-25)).position(x:g.size.width*0.5,y:g.size.height*0.48).scaleEffect(move ? 1.18:0.65) }
            }
        }.onAppear { withAnimation(.easeOut(duration:2.8)) { move=true } }.accessibilityHidden(true)
    }
}
