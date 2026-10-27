import SwiftUI

struct HomeCoverView: View {
    @EnvironmentObject var store: CircleStore
    let open: (Screen) -> Void
    @State private var feedback: String?
    private var wallTitle: String? { store.current.memories.first { $0.id == store.growth.wallMemoryID }?.title }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                Group {
                    if store.growth.selectedWallpaperDay == nil {
                        Image("HomeCover").resizable().scaledToFill()
                    } else { StageRoomArt(stage: store.stage) }
                }.frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }
            VStack {
                HStack {
                    Button { open(.memoryGallery) } label: { Label(wallTitle ?? "照片墙", systemImage: "photo").lineLimit(1) }
                        .accessibilityIdentifier("sceneMemories")
                    Spacer()
                    Button { open(.capsules) } label: { Image(systemName: "envelope") }.accessibilityLabel("未来信箱").accessibilityIdentifier("sceneMailbox")
                }.font(.caption.bold()).buttonStyle(.plain).foregroundStyle(Palette.ink)
                    .padding(10).background(Palette.cream.opacity(0.93), in: Capsule())
                Spacer(minLength: 4)
                if let feedback { Text(feedback).font(.caption.bold()).padding(9).background(Palette.cream, in: Capsule()).accessibilityIdentifier("sceneFeedback") }
                HStack(alignment: .bottom) {
                    Button { open(.growth) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.stage.title).font(.subheadline.bold())
                            Text("小窝第\(store.growthDays)天 · 本机成长").font(.system(size: 10))
                        }.padding(9).background(Palette.cream.opacity(0.94), in: RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).accessibilityIdentifier("openGrowth")
                    Spacer()
                    Button {
                        store.pet("喂食")
                        feedback = "\(store.petName)吃饱啦，今天也喜欢你～"
                    } label: { Label("喂\(store.petName)", systemImage: "pawprint.fill").font(.caption.bold()).padding(11).background(Palette.cream, in: Capsule()) }
                        .buttonStyle(.plain).accessibilityIdentifier("sceneFeed")
                }.foregroundStyle(Palette.ink)
            }.padding(12)
        }.frame(height: 185).clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.border, lineWidth: 1))
            .task(id: feedback) {
                guard feedback != nil else { return }
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                feedback = nil
            }
    }
}

struct HomePartnerMomentCard: View {
    @EnvironmentObject var store: CircleStore
    let open: (Screen) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(store.friends ? "小圈的此刻" : "阿哲的此刻").font(.headline)
                Spacer()
                Button { open(.sharing) } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("状态分享设置")
            }
            HStack(spacing: 12) {
                Avatar(name: store.friends ? "柚柚" : "阿哲", size: 48)
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.friends ? "等大家分享一点小日常" : "等TA分享今天的小心情").font(.subheadline.weight(.medium))
                    Text("暂未连接对方").font(.caption).foregroundStyle(Palette.muted)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 7) { statusChips }
                VStack(alignment: .leading, spacing: 7) { statusChips }
            }
            Text("由本人主动分享，当前还没有对方的状态。").font(.caption2).foregroundStyle(Palette.muted)
            HStack(spacing: 10) {
                Button { store.sendChargedHug(level: 1); open(.chat) } label: {
                    Label(store.friends ? "抱抱大家" : "抱抱TA", systemImage: "heart.fill").frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(.white).background(Palette.rose, in: Capsule())
                }.accessibilityIdentifier("homeHug")
                Button { open(.chat) } label: {
                    Label("留张纸条", systemImage: "paperplane").frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(Palette.rose).overlay(Capsule().stroke(Palette.rose, lineWidth: 1))
                }.accessibilityIdentifier("homeNote")
            }.font(.subheadline.bold()).buttonStyle(.plain)
        }.padding(17).background(Color(hex: 0xFFF9FA), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.pink, lineWidth: 1))
            .accessibilityIdentifier("partnerMomentCard")
    }

    @ViewBuilder private var statusChips: some View {
        chip("心情 · 待分享", symbol: "face.smiling", color: Color(hex: 0x6B7CB3))
        chip("精力 · 待分享", symbol: "bolt", color: Palette.rose)
        chip("电量 · 未连接", symbol: "battery.75percent", color: Palette.teal)
    }
    private func chip(_ text: String, symbol: String, color: Color) -> some View {
        Label(text, systemImage: symbol).font(.system(size: 10, weight: .medium)).padding(.horizontal, 8).padding(.vertical, 9)
            .foregroundStyle(color).background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
    }
}

struct HomeMyMomentCard: View {
    @EnvironmentObject var store: CircleStore
    let open: (Screen) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的此刻").font(.headline)
            HStack(spacing: 10) {
                MyAvatar(size: 43)
                Text(store.current.status.isEmpty ? "今天想被怎样关心？" : store.current.status)
                    .font(.subheadline).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("myMomentText")
                Button { open(.status) } label: { Label("更新状态", systemImage: "pencil").font(.caption.bold()).padding(.horizontal, 12).frame(minHeight: 44).foregroundStyle(Palette.teal).overlay(Capsule().stroke(Palette.teal.opacity(0.5), lineWidth: 1)) }
                    .accessibilityIdentifier("updateMyMoment")
            }
            Text("只保存在此设备，暂未同步给对方。").font(.caption2).foregroundStyle(Palette.muted)
        }.padding(17).background(Palette.mint, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.teal.opacity(0.12), lineWidth: 1))
    }
}
