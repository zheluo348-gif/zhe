import SwiftUI
import UIKit

enum TuantuanAssets {
    static func sticker(_ pose: Int) -> UIImage? {
        guard let full = UIImage(named: "TuantuanSheet"), let cg = full.cgImage else { return nil }
        let cell = CGSize(width: cg.width / 3, height: cg.height / 2)
        let i = max(0, min(5, pose))
        let rect = CGRect(x: CGFloat(i % 3) * cell.width, y: CGFloat(i / 3) * cell.height, width: cell.width, height: cell.height)
        guard let cropped = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: full.scale, orientation: .up)
    }
}
struct TuantuanSticker: View {
    var pose = 0
    var body: some View {
        Group {
            if let image = TuantuanAssets.sticker(pose) {
                Image(uiImage: image).resizable().scaledToFit()
            } else { CatArt(happy: true).scaleEffect(0.65).frame(width: 150, height: 150) }
        }.accessibilityLabel(["抱着爱心的团团", "嘴硬的团团", "喝咖啡的团团", "晚安团团", "游戏团团", "画画团团"][max(0, min(5, pose))])
    }
}
struct SofaBanner: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("ChatSofa").resizable().scaledToFill()
            Text("给彼此留一点位置 ♡").font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.rose).padding(.horizontal, 12).padding(.vertical, 7)
                .background(Palette.cream.opacity(0.9), in: Capsule()).padding(12)
        }.frame(height: 118).clipped().accessibilityLabel("两个人与团团一起坐在粉色沙发上")
    }
}
struct PaperCard<Content: View>: View {
    var color = Palette.pink
    var tape = true
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .topLeading) {
                if tape { RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.65))
                    .frame(width: 49, height: 15).rotationEffect(.degrees(-15)).offset(x: 12, y: -5).accessibilityHidden(true) }
            }.overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.border.opacity(0.45), lineWidth: 1))
            .shadow(color: Palette.ink.opacity(0.035), radius: 8, y: 4)
    }
}
struct CreativePage<Content: View>: View {
    var title: String
    var subtitle = ""
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(5) }
                content
            }.padding(22).padding(.bottom, 15)
        }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively).background(Palette.cream)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
    }
}
struct ChoiceChip: View {
    var title: String
    var selected = false
    var color = Palette.rose
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 15)
                .frame(minHeight: 44).foregroundStyle(selected ? .white : Palette.ink)
                .background(selected ? color : .white, in: Capsule())
                .overlay(Capsule().stroke(selected ? color : Palette.border, lineWidth: 1))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct ConnectionNote: View {
    var text = "开发体验 · AI 服务尚未接入"
    var body: some View {
        Label(text, systemImage: "sparkle").font(.caption).foregroundStyle(Palette.muted)
            .padding(.vertical, 9).padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.lavender.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
    }
}
struct ArtFeatureCard: View {
    var title: String
    var detail: String
    var pose: Int
    var color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TuantuanSticker(pose: pose).frame(height: 108).frame(maxWidth: .infinity)
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(Palette.muted).lineLimit(2).frame(minHeight: 32, alignment: .top)
            HStack { Spacer(); Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.white).padding(9).background(Palette.rose, in: Circle()) }
        }.padding(15).background(color, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.7), lineWidth: 1))
            .foregroundStyle(Palette.ink)
    }
}

