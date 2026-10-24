import SwiftUI

struct StageRoomArt: View {
    let stage: GrowthStage
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(colors: [stage.sky, stage.sky.opacity(0.78), stage.floor], startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    let w = size.width, h = size.height
                    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color, radius: CGFloat = 0) {
                        context.fill(Path(roundedRect: CGRect(x: w*x, y: h*y, width: w*width, height: h*height), cornerRadius: radius), with: .color(color))
                    }
                    func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) {
                        context.fill(Path(ellipseIn: CGRect(x: w*x, y: h*y, width: w*width, height: h*height)), with: .color(color))
                    }
                    func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat = 1) {
                        var p = Path(); if let first = points.first { p.move(to: CGPoint(x: first.x*w, y: first.y*h)) }; for point in points.dropFirst() { p.addLine(to: CGPoint(x: point.x*w, y: point.y*h)) }; context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                    }
                    rect(0, 0.73, 1, 0.27, stage.floor)
                    ellipse(0.18, 0.76, 0.65, 0.19, stage.dark ? .white.opacity(0.08) : .white.opacity(0.38))
                    if stage.kind < 3 {
                        rect(0.39, 0.12, 0.43, 0.44, .white.opacity(0.62), radius: 34)
                        rect(0.42, 0.15, 0.37, 0.38, stage.kind == 1 ? Color(hex: 0xBADED0) : Color(hex: 0xE7CBDB), radius: 29)
                        line([CGPoint(x:0.60,y:0.15),CGPoint(x:0.60,y:0.53)], .white.opacity(0.85), 3)
                        line([CGPoint(x:0.42,y:0.34),CGPoint(x:0.79,y:0.34)], .white.opacity(0.85), 3)
                        ellipse(0.63,0.20,0.11,0.14,Color(hex:0xF7D19D))
                        rect(0.24,0.61,0.50,0.15,stage.kind == 1 ? Color(hex:0x8FBAA4) : Color(hex:0xDCA3B6),radius:16)
                        rect(0.20,0.62,0.10,0.18,stage.kind == 1 ? Color(hex:0xA9CDBB) : Color(hex:0xE9B7C6),radius:12)
                        rect(0.69,0.62,0.10,0.18,stage.kind == 1 ? Color(hex:0xA9CDBB) : Color(hex:0xE9B7C6),radius:12)
                        if stage.kind == 1 {
                            for i in 0..<5 { let x=0.08+CGFloat(i%2)*0.07, y=0.20+CGFloat(i)*0.09; ellipse(x,y,0.10,0.055,Color(hex:0x81AF91).opacity(0.8)) }
                            line([CGPoint(x:0.13,y:0.24),CGPoint(x:0.16,y:0.69)],Color(hex:0x638B74),2)
                        }
                        if stage.kind == 2 {
                            for i in 0..<4 { rect(0.06+CGFloat(i%2)*0.09,0.13+CGFloat(i/2)*0.13,0.075,0.10,[Color(hex:0xD5B1D4),Color(hex:0xA4B9CF),Color(hex:0xEFC7A2),Color(hex:0xE1B6C3)][i],radius:6) }
                        }
                    } else if stage.kind == 3 {
                        ellipse(0.54,0.12,0.38,0.48,Color(hex:0xFBE1B1))
                        for i in 0..<3 { ellipse(0.06+CGFloat(i)*0.34,0.32+CGFloat(i%2)*0.10,0.34,0.12,.white.opacity(0.32)) }
                        rect(0.02,0.59,0.96,0.025,Color(hex:0xB27C8F),radius:3)
                        for i in 0..<10 { rect(CGFloat(i)*0.11,0.61,0.012,0.19,Color(hex:0xB27C8F)) }
                        ellipse(0.26,0.70,0.49,0.21,Color(hex:0xF1C4C4))
                    } else if stage.kind == 4 {
                        let window=Path(roundedRect:CGRect(x:w*0.11,y:h*0.08,width:w*0.78,height:h*0.56),cornerRadius:50)
                        context.fill(window,with:.color(Color(hex:0x182742)))
                        context.stroke(window,with:.color(stage.accent.opacity(0.75)),lineWidth:4)
                        for i in 0..<3 { context.stroke(Path(ellipseIn:CGRect(x:w*(0.40+CGFloat(i)*0.025),y:h*(0.13+CGFloat(i)*0.02),width:w*0.39,height:h*(0.40-CGFloat(i)*0.04))),with:.color(stage.accent.opacity(0.20)),lineWidth:1) }
                        ellipse(0.56,0.21,0.20,0.25,Color(hex:0xD8ADC9)); line([CGPoint(x:0.48,y:0.37),CGPoint(x:0.79,y:0.25)],stage.accent,3)
                        rect(0.16,0.65,0.69,0.09,Color(hex:0x62718F),radius:10)
                        for i in 0..<5 { ellipse(0.23+CGFloat(i)*0.10,0.68,0.026,0.025,[stage.accent,Color(hex:0xE0A9BB)][i%2]) }
                    } else if stage.kind == 5 {
                        let dome=Path(roundedRect:CGRect(x:w*0.11,y:h*0.08,width:w*0.78,height:h*0.66),cornerRadius:w*0.38)
                        context.fill(dome,with:.color(.white.opacity(0.05))); context.stroke(dome,with:.color(stage.accent.opacity(0.50)),lineWidth:2)
                        ellipse(0.54,0.16,0.25,0.31,Color(hex:0xF8D99A)); ellipse(0.61,0.12,0.22,0.28,stage.sky)
                        rect(0.37,0.66,0.40,0.09,Color(hex:0x9A829A),radius:16)
                        ellipse(0.10,0.45,0.14,0.08,Color(hex:0xF2CF99)); rect(0.166,0.51,0.012,0.23,stage.accent)
                    } else if stage.kind == 6 {
                        for i in 0..<5 { ellipse(CGFloat(i)*0.23-0.08,0.10+CGFloat(i%2)*0.20,0.34,0.12,.white.opacity(0.62)) }
                        ellipse(0.12,0.68,0.77,0.24,Color(hex:0x8DC6AB)); ellipse(0.15,0.66,0.71,0.16,Color(hex:0xBCE1BE))
                        for i in 0..<6 { let x=0.13+CGFloat(i)*0.13; line([CGPoint(x:x,y:0.75),CGPoint(x:x+0.015,y:0.58)],Color(hex:0x72AB8B),2); ellipse(x-0.02,0.56,0.07,0.06,[Color(hex:0xF1B8C7),Color(hex:0xEBD49E)][i%2]) }
                    } else if stage.kind == 7 {
                        for i in 0..<4 { let inset=CGFloat(i)*0.025; let portal=Path(ellipseIn:CGRect(x:w*(0.27+inset),y:h*(0.08+inset),width:w*(0.48-inset*2),height:h*(0.62-inset*2))); context.stroke(portal,with:.color(stage.accent.opacity(0.2+Double(i)*0.16)),lineWidth:i==3 ? 4:2) }
                        ellipse(0.30,0.67,0.40,0.11,stage.accent.opacity(0.24)); line([CGPoint(x:0.51,y:0.12),CGPoint(x:0.51,y:0.66)],.white.opacity(0.1),1)
                    } else if stage.kind == 8 {
                        for i in 0..<3 { var p=Path(); p.move(to:CGPoint(x:w*(-0.2+Double(i)*0.2),y:0)); p.addCurve(to:CGPoint(x:w*(0.5+Double(i)*0.22),y:h*0.57),control1:CGPoint(x:w*0.3,y:h*0.6),control2:CGPoint(x:w*0.35,y:h*(-0.1))); context.stroke(p,with:.linearGradient(Gradient(colors:[stage.accent.opacity(0.7),Color(hex:0xBCA7E0).opacity(0.1)]),startPoint:.zero,endPoint:CGPoint(x:w,y:h)),style:StrokeStyle(lineWidth:24,lineCap:.round)) }
                        ellipse(0.25,0.70,0.55,0.14,Color(hex:0xACCFCB).opacity(0.3))
                    } else if stage.kind == 9 {
                        ellipse(0.44,0.12,0.31,0.39,Color(hex:0xE8C38E)); ellipse(0.50,0.19,0.08,0.08,Color(hex:0xD3AC79).opacity(0.7))
                        let orbit=Path(ellipseIn:CGRect(x:w*0.32,y:h*0.25,width:w*0.54,height:h*0.13)); context.stroke(orbit,with:.color(stage.accent),lineWidth:3)
                        line([CGPoint(x:0.08,y:0.29),CGPoint(x:0.22,y:0.17),CGPoint(x:0.31,y:0.36),CGPoint(x:0.18,y:0.45)],stage.accent.opacity(0.6),1)
                        for p in [CGPoint(x:0.08,y:0.29),CGPoint(x:0.22,y:0.17),CGPoint(x:0.31,y:0.36),CGPoint(x:0.18,y:0.45)] { ellipse(p.x-0.007,p.y-0.009,0.014,0.018,stage.accent) }
                    } else if stage.kind == 10 {
                        let window=Path(ellipseIn:CGRect(x:w*0.27,y:h*0.11,width:w*0.51,height:h*0.53));context.fill(window,with:.color(Color(hex:0x287D95)));context.stroke(window,with:.color(stage.accent.opacity(0.7)),lineWidth:7)
                        for i in 0..<5 { let x=0.40+CGFloat(i%3)*0.10,y=0.27+CGFloat(i%2)*0.15;ellipse(x,y,0.055,0.025,Color(hex:0xEDCA9F));line([CGPoint(x:x,y:y+0.01),CGPoint(x:x-0.018,y:y-0.01),CGPoint(x:x-0.018,y:y+0.03)],Color(hex:0xEDCA9F),2) }
                        for i in 0..<6 { let x=0.14+CGFloat(i)*0.13;line([CGPoint(x:x,y:0.79),CGPoint(x:x+0.03,y:0.55)],stage.accent.opacity(0.5),3) }
                    } else if stage.kind == 11 {
                        rect(0.30,0.13,0.58,0.41,.white.opacity(0.8),radius:19);rect(0.33,0.16,0.52,0.35,Color(hex:0xD5E6DA),radius:14)
                        for i in 0..<4 { ellipse(0.34+CGFloat(i)*0.15,0.24+CGFloat(i%2)*0.08,0.19,0.17,Color(hex:0xECC3D1)) }
                        line([CGPoint(x:0.59,y:0.15),CGPoint(x:0.59,y:0.52)],.white,4)
                        rect(0.26,0.61,0.55,0.16,Color(hex:0xC3A1BD),radius:17);rect(0.24,0.47,0.12,0.30,Color(hex:0xA88AA8),radius:10)
                        for i in 0..<3 { line([CGPoint(x:0.40+CGFloat(i)*0.14,y:0.04),CGPoint(x:0.40+CGFloat(i)*0.14,y:0.10)],stage.accent,2) }
                    } else if stage.kind == 12 {
                        rect(0.33,0.14,0.51,0.42,Color(hex:0x182B43),radius:8);rect(0.30,0.10,0.57,0.065,Color(hex:0xE6ABBF),radius:7)
                        for i in 0..<15 { let x=0.36+CGFloat(i%5)*0.10,y=0.21+CGFloat(i/5)*0.10;line([CGPoint(x:x,y:y),CGPoint(x:x-0.012,y:y+0.05)],stage.accent.opacity(0.4),1) }
                        rect(0.29,0.61,0.56,0.09,Color(hex:0x8E7D90),radius:8);ellipse(0.63,0.36,0.11,0.09,Color(hex:0xF0D19C).opacity(0.8))
                    } else if stage.kind == 13 {
                        for i in 0..<4 { let x=0.30+CGFloat(i)*0.18;rect(x,0.05,0.035,0.65,Color(hex:0x405F4F));ellipse(x-0.10,0.06+CGFloat(i%2)*0.08,0.28,0.32,Color(hex:0x355D4C)) }
                        for i in 0..<13 { ellipse(0.12+CGFloat((i*17)%77)/100,0.20+CGFloat((i*23)%40)/100,0.012,0.015,Color(hex:0xEFDF9E).opacity(0.8)) }
                        rect(0.22,0.67,0.60,0.07,Color(hex:0x7E9E76),radius:12)
                    } else if stage.kind == 14 {
                        for i in 0..<3 { let x=0.34+CGFloat(i)*0.18;ellipse(x,0.15+CGFloat(i%2)*0.12,0.18,0.15,[Color(hex:0xE7B4CC),Color(hex:0xBBDBD4),Color(hex:0xDFC5A1)][i]);line([CGPoint(x:x+0.09,y:0.30+CGFloat(i%2)*0.12),CGPoint(x:x+0.09,y:0.57)],stage.accent.opacity(0.4),2) }
                        ellipse(0.25,0.61,0.57,0.13,Color(hex:0xDAC3E1));ellipse(0.57,0.41,0.15,0.06,.white.opacity(0.5))
                    } else if stage.kind == 15 {
                        rect(0.37,0.17,0.42,0.40,Color(hex:0xC4D5DB),radius:5)
                        for i in 0..<15 { ellipse(0.40+CGFloat((i*13)%34)/100,0.20+CGFloat((i*17)%29)/100,0.009,0.011,.white.opacity(0.9)) }
                        rect(0.31,0.56,0.52,0.15,Color(hex:0x9E8174),radius:8);rect(0.35,0.57,0.44,0.08,Color(hex:0x664E49),radius:5)
                        ellipse(0.47,0.59,0.13,0.10,Color(hex:0xF2BB86));ellipse(0.51,0.58,0.06,0.11,Color(hex:0xF8DEA4))
                    } else if stage.kind == 16 {
                        rect(0.32,0.12,0.54,0.43,.white.opacity(0.65),radius:30);rect(0.35,0.15,0.48,0.37,Color(hex:0xAFD5DA),radius:25)
                        for i in 0..<4 { line([CGPoint(x:0.36,y:0.32+CGFloat(i)*0.045),CGPoint(x:0.81,y:0.32+CGFloat(i)*0.045)],.white.opacity(0.45),1) }
                        for i in 0..<3 { let x=0.40+CGFloat(i)*0.14;line([CGPoint(x:x,y:0.02),CGPoint(x:x,y:0.14+CGFloat(i%2)*0.03)],stage.accent.opacity(0.5),1);ellipse(x-0.018,0.13+CGFloat(i%2)*0.03,0.036,0.05,stage.accent.opacity(0.55)) }
                    }
                    if stage.variation>0 {
                        for i in 0..<5 { let x=0.12+CGFloat((i*19+stage.variation*13)%76)/100,y=0.11+CGFloat((i*17+stage.variation*7)%42)/100;context.stroke(Path(ellipseIn:CGRect(x:w*x,y:h*y,width:14+CGFloat(stage.variation%5)*4,height:14+CGFloat(stage.variation%5)*4)),with:.color(stage.accent.opacity(0.25)),lineWidth:1) }
                        line([CGPoint(x:0.09,y:0.58),CGPoint(x:0.90,y:0.58+Double(stage.variation%3)*0.025)],stage.accent.opacity(0.2),2)
                    }
                    if stage.dark {
                        for i in 0..<24 { let x=CGFloat((i*37+13)%97)/100, y=CGFloat((i*19+7)%59)/100; ellipse(x,y,0.006+(i%4==0 ? 0.006:0),0.009,.white.opacity(i%3==0 ? 0.8:0.3)) }
                    }
                    line([CGPoint(x:0,y:0.73),CGPoint(x:1,y:0.73)],stage.accent.opacity(0.25),1)
                }
                Image(systemName: stage.kind >= 4 ? "sparkle" : "heart").font(.system(size: 19)).foregroundStyle(stage.accent.opacity(0.8)).position(x:w*0.89,y:h*0.17)
            }
        }.accessibilityHidden(true)
    }
}
struct GrowingRoomCard: View {
    @EnvironmentObject var store: CircleStore
    var previewStage: GrowthStage?
    var showcaseUnlocked=false
    var open: ((Screen) -> Void)?
    @State private var bubble: String?
    var stage: GrowthStage { previewStage ?? store.stage }
    var wallTitle: String? { store.current.memories.first { $0.id == store.growth.wallMemoryID }?.title }
    var wallPhoto: UIImage? { guard let id=store.growth.wallMemoryID, let memory=store.current.memories.first(where:{$0.id==id}), let name=memory.attachment else { return nil }; return store.photo(named:name) }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment:.leading,spacing:5) { Text(stage.title).font(.system(size:22,weight:.bold)); Text(previewStage == nil ? "小窝第\(store.growthDays)天 · 本机成长" : (showcaseUnlocked ? "第\(stage.day)天 · 新场景已点亮":"第\(stage.day)天的场景预览")).font(.system(size:11)).opacity(0.72) }
                Spacer(); Image(systemName:stage.dark ? "sparkles":"house.lodge.fill").font(.title2)
            }.padding(.horizontal,19).padding(.top,17).foregroundStyle(stage.dark ? .white : Palette.ink)
            GeometryReader { geo in
                let w=geo.size.width,h=geo.size.height
                ZStack {
                    Button { guard previewStage == nil else { return }; store.pet("喂食"); bubble="\(store.petName)吃饱啦，今天也喜欢你～"; if store.state.haptics { UIImpactFeedbackGenerator(style:.soft).impactOccurred() }; DispatchQueue.main.asyncAfter(deadline:.now()+2) { bubble=nil } } label: {
                        DressedTuantuan(outfit:store.play.outfit).frame(width:112,height:125)
                    }.buttonStyle(.plain).position(x:w*0.51,y:h*0.67).accessibilityLabel("给\(store.petName)喂一口").accessibilityIdentifier("sceneFeed")
                    Button { open?(.memoryGallery) } label: {
                        VStack(spacing:4) {
                            Group { if let wallPhoto { Image(uiImage:wallPhoto).resizable().scaledToFill() } else if let wallTitle { Text(wallTitle).font(.system(size:10,weight:.semibold)).multilineTextAlignment(.center).foregroundStyle(Palette.ink).padding(3) } else { MiniIllustration(index:8) } }.frame(width:57,height:56).clipped().padding(5).background(.white.opacity(0.9),in:RoundedRectangle(cornerRadius:8)).rotationEffect(.degrees(-6))
                            Text("照片墙").font(.system(size:10,weight:.semibold))
                        }
                    }.buttonStyle(.plain).foregroundStyle(stage.dark ? .white:Palette.ink).position(x:w*0.18,y:h*0.34).accessibilityIdentifier("sceneMemories")
                    Button { open?(.capsules) } label: { VStack(spacing:2) { MiniIllustration(index:1).frame(width:60,height:59); Text("未来信箱").font(.system(size:10,weight:.semibold)) } }.buttonStyle(.plain).foregroundStyle(stage.dark ? .white:Palette.ink).position(x:w*0.84,y:h*0.70).accessibilityIdentifier("sceneMailbox")
                    if store.current.wishes.contains(where:{$0.done}) { Image(systemName:"gift.fill").font(.system(size:21)).foregroundStyle(stage.accent).position(x:w*0.25,y:h*0.81).accessibilityLabel("完成愿望获得的小礼物") }
                    if let bubble { Text(bubble).font(.system(size:11,weight:.medium)).foregroundStyle(Palette.ink).padding(10).background(Palette.cream,in:Capsule()).position(x:w*0.5,y:h*0.12).accessibilityIdentifier("sceneFeedback") }
                }
            }.frame(height:190).allowsHitTesting(previewStage == nil)
            Text(stage.line).font(.system(size:11)).foregroundStyle(stage.dark ? .white.opacity(0.8):Palette.ink.opacity(0.7)).padding(.horizontal,15).padding(.bottom,15)
        }.background { StageRoomArt(stage:stage) }.clipShape(RoundedRectangle(cornerRadius:26)).overlay(RoundedRectangle(cornerRadius:26).stroke(stage.accent.opacity(0.20),lineWidth:1))
    }
}
struct GrowthJourneyView: View {
    @EnvironmentObject var store: CircleStore
    @State private var selected: GrowthStage?
    var body: some View {
        CreativePage(title:"小窝的成长旅行",subtitle:"每一次回来，都给小窝添一点新颜色。") {
            GrowingRoomCard(previewStage:selected ?? store.stage)
            HStack { Pill(text:selected == nil || selected==store.stage ? "当前使用壁纸":"壁纸预览",color:store.stage.onPaperAccent); Spacer(); Text("累计来访 \(store.growthDays) 天").font(.caption).foregroundStyle(Palette.muted) }
            if let next=store.growthStage.next { Text("再点亮 \(max(0,next.day-store.growthDays)) 天，解锁“\(next.title)”和\(next.gift)。").font(.subheadline).lineSpacing(6) }
            Button("自动跟随最新壁纸") { store.followNewestWallpaper() }.font(.subheadline).frame(minHeight:44).accessibilityIdentifier("followNewestWallpaper")
            Text("30天以后，每累计30天再解锁一张。已经解锁的壁纸可以一直保留、随时换回来。").font(.subheadline).foregroundStyle(Palette.muted)
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:13) {
                ForEach(GrowthStage.catalog(through:store.growthDays)) { stage in Button { selected=stage } label: {
                    VStack(alignment:.leading,spacing:8) {
                        ZStack { StageRoomArt(stage:stage); TuantuanSticker(pose:stage.kind%6).frame(width:56,height:64).offset(y:13) }.frame(height:94).clipShape(RoundedRectangle(cornerRadius:13))
                        Text("第\(stage.day)天 · \(stage.title)").font(.system(size:13,weight:.semibold))
                        HStack { Text(stage.day==store.stage.day ? "正在使用":(stage.day<=store.growthDays ? "已解锁 · 可换回":"点击预览")); Spacer(); Image(systemName:stage.day<=store.growthDays ? "checkmark.seal.fill":"lock") }.font(.system(size:10)).foregroundStyle(stage.onPaperAccent)
                    }.padding(10).background(.white,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(selected==stage ? stage.accent:.clear,lineWidth:2))
                }.buttonStyle(.plain).foregroundStyle(Palette.ink).accessibilityIdentifier("stage_\(stage.day)") }
            }
            Text("以实际打开当前小窝的自然日累计，同一天只记一次，中断不清零。未来阶段可预览，预览不会增加天数或解锁；恋爱纪念日期单独计算。当前为本机记录，双方共同成长同步待联网接入。").font(.caption).foregroundStyle(Palette.muted).lineSpacing(5)
        }.sheet(item:$selected) { stage in
            NavigationStack { ScrollView { VStack(alignment:.leading,spacing:20) {
                GrowingRoomCard(previewStage:stage)
                Label(stage.day<=store.growthDays ? "这个阶段已经点亮":"未来场景预览 · 第\(stage.day)天解锁",systemImage:stage.day<=store.growthDays ? "checkmark.seal":"lock").font(.subheadline.bold()).foregroundStyle(stage.onPaperAccent)
                Text("阶段礼物：\(stage.gift)").font(.headline)
                if stage.day<=store.growthDays {
                    PrimaryButton(title:stage.day==store.stage.day ? "正在使用这张壁纸":"换上这张已解锁壁纸",symbol:"photo") { store.useWallpaper(stage.day);selected=nil }.accessibilityIdentifier("useWallpaper")
                } else { Label("还差\(stage.day-store.growthDays)天解锁，到时可换上",systemImage:"lock").font(.caption).foregroundStyle(Palette.muted) }
                Text("预览不会改变成长天数，也不会提前获得解锁记录。每个阶段都有自己的构图、背景和小物件。").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(7)
            }.padding(20) }.background(Palette.cream).navigationTitle("第\(stage.day)天 · \(stage.title)").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button("收好预览") { selected=nil }.accessibilityIdentifier("closeStagePreview") } } }
        }
    }
}
struct ChatStageBackdrop: View {
    let stage: GrowthStage
    var body: some View {
        ZStack(alignment:.topTrailing) {
            LinearGradient(colors:[stage.sky.opacity(stage.dark ? 0.12:0.42),Palette.cream,stage.floor.opacity(0.20)],startPoint:.topLeading,endPoint:.bottomTrailing)
            Image(systemName:stage.kind>=4 ? "moon.stars":"leaf").font(.system(size:135,weight:.ultraLight)).foregroundStyle(stage.accent.opacity(0.08)).rotationEffect(.degrees(-15)).padding(.top,45).offset(x:25)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

struct StageUnlockView: View {
    @EnvironmentObject var store:CircleStore
    @Environment(\.dismiss) private var dismiss
    let stage:GrowthStage
    var body: some View {
        NavigationStack { ScrollView {
            VStack(alignment:.leading,spacing:21) {
                HStack { MiniIllustration(index:10).frame(width:65,height:67); VStack(alignment:.leading,spacing:7) { Text("小窝升级啦！").font(.title.bold()); Text("第\(store.growthDays)次在不同日子回来").font(.caption).foregroundStyle(Palette.muted) } }
                GrowingRoomCard(previewStage:stage,showcaseUnlocked:true)
                Label("解锁：\(stage.gift)",systemImage:"gift.fill").font(.title3.bold()).foregroundStyle(stage.onPaperAccent)
                Text("不是因为每天都完美，\n是因为我们还愿意，一次次回来。").font(.headline).lineSpacing(8)
                PrimaryButton(title:"收好这次升级，留进回忆",symbol:"bookmark") {
                    store.useWallpaper(stage.day)
                    store.addMemory("第\(stage.day)天 · \(stage.title)",note:"点亮了\(stage.gift)。\n\(stage.line)",kind:"小窝升级");dismiss()
                }.accessibilityIdentifier("claimStageGift")
                Button("换上新壁纸回家") { store.useWallpaper(stage.day);dismiss() }.frame(maxWidth:.infinity,minHeight:44)
                Text("忙几天也没关系，已经点亮的阶段不会消失。").font(.caption).foregroundStyle(Palette.muted)
            }.padding(22)
        }.background(Palette.cream).navigationTitle("一点成长的小惊喜").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button("关闭") { dismiss() } } } }
    }
}
