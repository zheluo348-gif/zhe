import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in p.move(to: CGPoint(x: rect.minX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.midX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)); p.closeSubpath() }
    }
}
struct CatArt: View {
    var happy = false
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xD8C0A3).opacity(0.6)).frame(width: 165, height: 23).offset(y: 85)
            HStack(spacing: 82) { Triangle().fill(.white).overlay(Triangle().stroke(Palette.ink, lineWidth: 3)); Triangle().fill(.white).overlay(Triangle().stroke(Palette.ink, lineWidth: 3)) }.frame(width: 158, height: 68).offset(y: -63)
            HStack(spacing: 103) { Triangle().fill(Palette.pink); Triangle().fill(Palette.pink) }.frame(width: 135, height: 30).offset(y: -67)
            Circle().fill(.white).overlay(Circle().stroke(Palette.ink, lineWidth: 3)).frame(width: 180, height: 177)
            HStack(spacing: 41) { Eye(); Eye() }.offset(y: -12)
            HStack(spacing: 78) { Ellipse().fill(Color(hex: 0xF2B1C3)); Ellipse().fill(Color(hex: 0xF2B1C3)) }.frame(width: 122, height: 15).offset(y: 14)
            Image(systemName: happy ? "heart.fill" : "chevron.down").font(.system(size: happy ? 20 : 17, weight: .bold)).foregroundStyle(happy ? Palette.rose : Palette.ink).offset(y: 27)
            HStack(spacing: 14) { Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2)); Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2)) }.frame(width: 57, height: 22).offset(y: 79)
        }.frame(width: 220, height: 225).accessibilityLabel("可爱的白色小猫团团")
    }
}
struct Eye: View {
    var body: some View { Capsule().trim(from: 0.03, to: 0.47).stroke(Palette.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 18, height: 16).rotationEffect(.degrees(180)) }
}
struct LittlePerson: View {
    var girl = false
    var color = Palette.rose
    var body: some View {
        ZStack {
            if girl { Circle().fill(Color(hex: 0x493028)).frame(width: 32, height: 32).offset(y: -78) }
            RoundedRectangle(cornerRadius: 22).fill(color).frame(width: 74, height: 82).offset(y: 43)
            Circle().fill(Color(hex: 0x493028)).frame(width: 90, height: 95).offset(y: -25)
            Ellipse().fill(Color(hex: 0xFFE1C4)).frame(width: 88, height: 78).offset(y: -10)
            Capsule().fill(Color(hex: 0x493028)).frame(width: 72, height: 25).rotationEffect(.degrees(girl ? -18 : 10)).offset(y: -48)
            HStack(spacing: 28) { Circle().fill(Palette.ink); Circle().fill(Palette.ink) }.frame(width: 39, height: 6).offset(y: -10)
            HStack(spacing: 42) { Ellipse().fill(Color(hex: 0xF19AB1)); Ellipse().fill(Color(hex: 0xF19AB1)) }.frame(width: 65, height: 10).offset(y: 5)
            Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).offset(y: 13)
        }.frame(width: 110, height: 180)
    }
}
struct RoomScene: View {
    var touching = false
    var action: String
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Color(hex: 0x1D1E35)).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(hex: 0x53577C), lineWidth: 6)).frame(width: w * 0.35, height: 113).position(x: w * 0.24, y: 73)
                Rectangle().fill(Color(hex: 0x53577C)).frame(width: 4, height: 110).position(x: w * 0.24, y: 73)
                Image(systemName: "moon.fill").font(.system(size: 27)).foregroundStyle(Color(hex: 0xF4D866)).position(x: w * 0.32, y: 48)
                Circle().fill(.white.opacity(0.8)).frame(width: 3).position(x: w * 0.13, y: 57)
                Circle().fill(.white.opacity(0.8)).frame(width: 3).position(x: w * 0.31, y: 97)
                Ellipse().fill(Color(hex: 0xE8DDA2).opacity(0.06)).frame(width: 145, height: 175).position(x: w * 0.84, y: 112)
                Rectangle().fill(Color(hex: 0x8C82A4)).frame(width: 5, height: 120).position(x: w * 0.85, y: 142)
                Triangle().fill(Color(hex: 0xEAD56C)).frame(width: 57, height: 52).rotationEffect(.degrees(180)).position(x: w * 0.85, y: 57)
                Ellipse().fill(Color(hex: 0x8C82A4)).frame(width: 60, height: 9).position(x: w * 0.85, y: 205)
                RoundedRectangle(cornerRadius: 26).fill(Palette.rose).frame(width: w * 0.87, height: 125).position(x: w * 0.5, y: 263)
                RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xA3315B)).frame(width: w * 0.91, height: 70).position(x: w * 0.5, y: 292)
                HStack(spacing: touching ? -5 : 22) { LittlePerson(girl: true, color: Palette.pink); LittlePerson(color: Color(hex: 0x44417E)) }.position(x: w * 0.5, y: 214)
                if !action.isEmpty { Text(action).transaction { $0.animation = nil }.font(.subheadline.bold()).foregroundStyle(Palette.ink).padding(.horizontal, 15).padding(.vertical, 10).background(.white, in: Capsule()).position(x: w * 0.51, y: 135) }
                HStack { Text("小糖"); Spacer(); Text("阿哲 · 示例形象") }.font(.caption).foregroundStyle(Color(hex: 0xD7D2EA)).frame(width: w * 0.72).position(x: w * 0.5, y: 352)
            }
        }.frame(height: 380).accessibilityElement(children: .ignore).accessibilityLabel("两个人坐在莓果色沙发上的二维小房间")
    }
}
struct RoomView: View {
    @Environment(\.scenePhase) private var phase
    @State private var action = "陪你坐一会儿"
    @State private var close = false
    private let labels = ["戳一下", "牵手", "靠近", "表情"]
    private let symbols = ["hand.point.up.left", "hands.sparkles", "sofa", "face.smiling"]
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) {
            Text("我们的小房间").font(.title2.bold()).foregroundStyle(.white)
            Label("本机陪伴场景 · 对方形象为示例", systemImage: "circle.fill").font(.caption).foregroundStyle(Color(hex: 0xB5B2CA))
            HStack { Avatar(name: "哲", color: Color(hex: 0xE6DDD5), size: 31); Text(action == "陪你坐一会儿" ? "给日常留一点安静的位置" : action).transaction { $0.animation = nil }.font(.subheadline); Spacer(); Text("此刻").font(.caption).foregroundStyle(Palette.muted) }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 17))
            RoomScene(touching: close, action: action)
            NavigationLink(value: Screen.pet) { Label("去看看团团", systemImage: "pawprint").font(.subheadline.weight(.medium)).foregroundStyle(.white).padding(.horizontal, 22).padding(.vertical, 12).overlay(Capsule().stroke(.white.opacity(0.65), lineWidth: 1)) }.frame(maxWidth: .infinity).accessibilityIdentifier("openPet")
            HStack(spacing: 10) { ForEach(0..<4) { i in Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { close = i == 1 || i == 2; action = ["轻轻戳了戳你", "一起牵牵手", "靠近一点点", "今天也要开心呀 ☀️"][i] }
            } label: { VStack(spacing: 12) { Image(systemName: symbols[i]).font(.title2).foregroundStyle([Color(hex: 0xEAD56C), Color(hex: 0xF19AB1), Color(hex: 0x94D2C8), Color(hex: 0xC3B8E6)][i]); Text(labels[i]).font(.caption.weight(.medium)).foregroundStyle(.white) }.frame(maxWidth: .infinity).frame(height: 86).background(Color(hex: 0x3D3D64), in: RoundedRectangle(cornerRadius: 19)) }.accessibilityIdentifier("roomAction_\(i)") } }
            Text("动作仅在此设备演示，暂未连接对方。").font(.caption).foregroundStyle(Color(hex: 0xAAA7C0)).frame(maxWidth: .infinity).padding(.bottom, 15)
        }.padding(20) }.background(Palette.night.ignoresSafeArea()).toolbarBackground(Palette.night, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar).tint(.white).onChange(of: phase) { _, p in if p != .active { close = false; action = "陪你坐一会儿" } }
    }
}
struct PetView: View {
    @EnvironmentObject var store: CircleStore
    @State private var happy = false
    @State private var bubble = "今天也要好好吃饭哦"
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 19) {
            HStack(alignment: .firstTextBaseline) { Text("团团").font(.title.bold()); Text("Lv.1").font(.headline).foregroundStyle(store.accent) }
            Text("\(store.spaceName)一起照顾的小伙伴").font(.subheadline).foregroundStyle(Palette.muted)
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(Color(hex: 0xF0E1D1))
                VStack(spacing: 1) { Text(bubble).font(.subheadline.weight(.medium)).padding(.horizontal, 19).padding(.vertical, 12).background(.white, in: Capsule()).padding(.top, 25); CatArt(happy: happy).scaleEffect(happy ? 1.05 : 1).padding(.bottom, 18) }
            }.frame(height: 306)
            HStack(spacing: 13) { stat("饱腹", value: store.current.satiety, color: store.accent); stat("心情", value: store.current.mood, color: store.accent); stat("干净", value: store.current.clean, color: Color(hex: 0xAD7950)) }
            HStack(spacing: 12) { ForEach(Array(["喂食", "洗澡", "陪玩"].enumerated()), id: \.offset) { i, title in Button {
                store.pet(title); bubble = ["小饼干真好吃，谢谢你！", "洗得香香的啦", "有你陪着，真开心！"][i]
                withAnimation(.spring()) { happy = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 1) { withAnimation { happy = false } }
            } label: { Surface(padding: 15) { VStack(spacing: 10) { Image(systemName: ["fork.knife", "drop", "tennisball"][i]).font(.title2).foregroundStyle(i == 1 ? Color(hex: 0xAD7950) : store.accent); Text(title).font(.subheadline.weight(.medium)) }.frame(maxWidth: .infinity) } }.buttonStyle(.plain).accessibilityIdentifier("petAction_\(i)") } }
            Surface { VStack(alignment: .leading, spacing: 15) { Text("团团日记").font(.headline); ForEach(Array(store.current.petLog.prefix(4).enumerated()), id: \.offset) { i, log in HStack(alignment: .top, spacing: 10) { Avatar(name: "小糖", size: 26); Text(log).font(.subheadline); Spacer(minLength: 0); if i == 0 { Text("最近").font(.caption2).foregroundStyle(Palette.muted) } } } } }
            Text("忙几天也没关系，团团会等你回来。").font(.caption).foregroundStyle(Color(hex: 0xA47649)).frame(maxWidth: .infinity).padding(.vertical, 10)
        }.padding(20) }.background(store.background).navigationTitle("共养团团").navigationBarTitleDisplayMode(.inline)
    }
    func stat(_ name: String, value: Int, color: Color) -> some View { VStack(alignment: .leading, spacing: 8) { Text("\(name) \(value)%").font(.caption).foregroundStyle(Palette.muted).accessibilityIdentifier("petStat_\(name)"); GeometryReader { g in ZStack(alignment: .leading) { Capsule().fill(Palette.border); Capsule().fill(color).frame(width: g.size.width * Double(value) / 100) } }.frame(height: 7) }.frame(maxWidth: .infinity) }
}
