import SwiftUI

struct IllustratedRoomView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubble = "有事叫团团～"
    @State private var hearts = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 17) {
                VStack(spacing: 7) {
                    Text(store.spaceName).font(.title3.bold())
                    Text("给彼此留一点安静的位置").font(.caption).foregroundStyle(.white.opacity(0.7))
                }.foregroundStyle(.white)
                ZStack(alignment: .bottom) {
                    Image("MoonRoom").resizable().scaledToFill().frame(height: 420).frame(maxWidth: .infinity).clipped()
                    Text(bubble).font(.subheadline.bold()).foregroundStyle(Palette.ink).padding(.horizontal, 18).padding(.vertical, 11)
                        .background(Palette.cream, in: Capsule()).padding(.bottom, 22)
                    if hearts {
                        HStack(spacing: 35) { ForEach(0..<3) { i in Image(systemName: "heart.fill").font(.system(size: CGFloat(18 + i * 6))).foregroundStyle(Palette.pink).offset(y: CGFloat(i % 2 == 0 ? -180 : -220)) } }
                            .transition(.scale.combined(with: .opacity)).accessibilityHidden(true)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 26))
                HStack(spacing: 20) {
                    meter("饱食值", value: store.current.satiety, color: Palette.teal)
                    meter("心情", value: store.current.mood, color: Palette.rose)
                }.padding(16).background(Palette.cream, in: RoundedRectangle(cornerRadius: 20))
                HStack(spacing: 10) {
                    Button { interact("喂食", text: "小饼干真好吃，谢谢你！") } label: { action("喂一口", symbol: "birthday.cake.fill", color: Color(hex: 0xF0CCD3)) }.accessibilityIdentifier("roomFeed")
                    Button { interact("陪玩", text: "摸摸头，今天也很开心～") } label: { action("摸摸头", symbol: "hand.raised.fill", color: Palette.lavender) }.accessibilityIdentifier("roomPat")
                    NavigationLink(value: Screen.wardrobe) { action("换装", symbol: "tshirt.fill", color: Color(hex: 0xDDEEE6)) }
                    NavigationLink(value: Screen.tuantuan) { action("找团团", symbol: "pawprint.fill", color: Palette.pink) }.accessibilityIdentifier("findTuantuan")
                }.buttonStyle(.plain)
                NavigationLink(value: Screen.pet) { Label("团团日记与照料", systemImage: "book.closed").font(.subheadline).foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 44) }.accessibilityIdentifier("openPet")
                Text("本机陪伴场景 · 未连接其他设备").font(.caption2).foregroundStyle(.white.opacity(0.65))
            }.padding(20)
        }.background(Palette.night.ignoresSafeArea()).navigationTitle("我们的小房间").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar).toolbarBackground(Palette.night, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
    }
    func meter(_ label: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(label); Spacer(); Text("\(value)%").fontWeight(.semibold) }.font(.caption).foregroundStyle(Palette.ink)
            GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Palette.border); Capsule().fill(color).frame(width: geo.size.width * CGFloat(value) / 100) } }.frame(height: 7)
        }.frame(maxWidth: .infinity)
    }
    func action(_ title: String, symbol: String, color: Color) -> some View {
        VStack(spacing: 11) { Image(systemName: symbol).font(.title2).foregroundStyle(Palette.rose); Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.ink) }.frame(maxWidth: .infinity).frame(height: 86).background(color, in: RoundedRectangle(cornerRadius: 20))
    }
    func interact(_ action: String, text: String) {
        store.pet(action); bubble = text
        if store.state.haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        guard store.creative.animations && !reduceMotion else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { hearts = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { hearts = false } }
    }
}

