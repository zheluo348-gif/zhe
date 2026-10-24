import SwiftUI
import UIKit

enum Palette {
    static let cream = Color(hex: 0xFAF6F1)
    static let rose = Color(hex: 0xBE426B)
    static let pink = Color(hex: 0xF4E2E8)
    static let teal = Color(hex: 0x2C7C78)
    static let mint = Color(hex: 0xF2F8F5)
    static let ink = Color(hex: 0x292320)
    static let muted = Color(hex: 0x827B76)
    static let border = Color(hex: 0xEAE1D9)
    static let night = Color(hex: 0x252640)
    static let lavender = Color(hex: 0xE9E5F2)
}
extension Color {
    init(hex: UInt32) { self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255) }
}
struct Surface<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.border.opacity(0.8), lineWidth: 1))
    }
}
struct Avatar: View {
    var name: String
    var color: Color = Palette.pink
    var size: CGFloat = 42
    var body: some View {
        Group {
            if let image = PortraitAssets.image(for: name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(String(name.prefix(1))).font(.system(size: size * 0.36, weight: .bold)).foregroundStyle(Palette.ink)
            }
        }.frame(width: size, height: size).background(color, in: Circle()).clipShape(Circle()).accessibilityLabel(name)
    }
}
enum PortraitAssets {
    static let portraits: [UIImage] = {
        guard let image = UIImage(named: "ChatSofa"), let cg = image.cgImage else { return [] }
        return [CGRect(x: 0.25, y: 0.06, width: 0.18, height: 0.56), CGRect(x: 0.43, y: 0.19, width: 0.18, height: 0.56)].compactMap { r in
            let rect = CGRect(x: r.minX * CGFloat(cg.width), y: r.minY * CGFloat(cg.height), width: r.width * CGFloat(cg.width), height: r.height * CGFloat(cg.height))
            return cg.cropping(to: rect).map { UIImage(cgImage: $0) }
        }
    }()
    static func image(for name: String) -> UIImage? {
        guard portraits.count == 2 else { return nil }
        if ["哲", "阿哲"].contains(name) { return portraits[0] }
        if ["小糖"].contains(name) { return portraits[1] }
        return nil
    }
}
struct PrimaryButton: View {
    var title: String
    var symbol: String = ""
    var color: Color = Palette.rose
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) { if !symbol.isEmpty { Image(systemName: symbol) }; Text(title).fontWeight(.semibold) }
                .frame(maxWidth: .infinity).padding(.vertical, 15).foregroundStyle(.white).background(color, in: Capsule())
        }.buttonStyle(.plain)
    }
}
struct Pill: View {
    var text: String
    var color: Color = Palette.rose
    var body: some View { Text(text).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6).foregroundStyle(color).background(color.opacity(0.09), in: Capsule()) }
}
struct IconTile: View {
    var icon: String
    var title: String
    var subtitle: String = ""
    var color: Color = Palette.rose
    var body: some View { HStack(spacing: 10) {
        Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 40, height: 40).background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        VStack(alignment: .leading, spacing: 4) { Text(title).font(.subheadline.weight(.semibold)); if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(Palette.muted) } }
        Spacer(minLength: 2)
        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.muted)
    }.foregroundStyle(Palette.ink) }
}
struct SunsetArt: View {
    var theme: String = "sunset"
    var body: some View {
        GeometryReader { g in
            ZStack {
                if theme == "sunset" {
                    LinearGradient(colors: [Color(hex: 0xD8A2AE), Color(hex: 0xF3BB85), Color(hex: 0xFBE0B1)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xFFF1BE)).frame(width: g.size.width * 0.15).position(x: g.size.width * 0.7, y: g.size.height * 0.45)
                    Ellipse().fill(Color(hex: 0x73949A)).frame(width: g.size.width * 1.6, height: g.size.height * 0.8).position(x: g.size.width * 0.35, y: g.size.height * 1.02)
                    ForEach(0..<4) { n in Capsule().fill(.white.opacity(0.35)).frame(width: CGFloat(60 - n * 9), height: 2).position(x: g.size.width * 0.7, y: g.size.height * 0.7 + CGFloat(n * 12)) }
                    VStack { Spacer(); HStack(spacing: 3) { Image(systemName: "figure.seated.side"); Image(systemName: "figure.seated.side") }.font(.system(size: min(g.size.height * 0.3, 50))).foregroundStyle(Color(hex: 0x444358)).padding(.bottom, 8) }
                } else {
                    Color(hex: 0xE9DAC6)
                    Circle().fill(.white.opacity(0.3)).frame(width: g.size.width * 0.6).offset(x: -35, y: -20)
                    HStack(spacing: -5) {
                        Image(systemName: "cup.and.saucer.fill").rotationEffect(.degrees(-10))
                        Image(systemName: "cup.and.saucer.fill").rotationEffect(.degrees(10))
                    }.font(.system(size: min(g.size.width * 0.18, g.size.height * 0.38))).foregroundStyle(Color(hex: 0xAD795B))
                    Image(systemName: "heart.fill").font(.system(size: 16)).foregroundStyle(Palette.rose.opacity(0.7)).offset(y: -g.size.height * 0.26)
                }
            }.clipped()
        }.accessibilityLabel(theme == "sunset" ? "两个人一起看海的插画" : "两杯热奶茶的插画")
    }
}
struct EmptyState: View {
    var icon: String
    var title: String
    var detail: String
    var body: some View { VStack(spacing: 14) { Image(systemName: icon).font(.system(size: 42, weight: .light)).foregroundStyle(Palette.rose.opacity(0.6)); Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 56) }
}

struct SpaceSelector: View {
    @EnvironmentObject var store: CircleStore
    var body: some View {
        HStack(spacing: 5) {
            choice("couple", title: "情侣", symbol: "heart.fill", color: Palette.rose)
            choice("friends", title: "闺蜜", symbol: "person.2.fill", color: Palette.teal)
        }
        .padding(5)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(Palette.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("我的空间")
    }
    private func choice(_ mode: String, title: String, symbol: String, color: Color) -> some View {
        let selected = store.state.mode == mode
        return Button { store.selectSpace(mode) } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity).frame(minHeight: 44)
                .foregroundStyle(selected ? .white : Palette.muted)
                .background(selected ? color : .clear, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("space_\(mode)")
        .accessibilityValue(selected ? "已选择" : "未选择")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
