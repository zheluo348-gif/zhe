import SwiftUI
import PhotosUI

struct MyAvatar: View {
    @EnvironmentObject var store: CircleStore
    var size: CGFloat = 42
    var body: some View {
        Group { if let name=store.state.profile?.avatarPhoto,let image=store.photo(named:name) { Image(uiImage:image).resizable().scaledToFill().frame(width:size,height:size).clipShape(Circle()) } else { Avatar(name:"小糖",size:size) } }.accessibilityLabel(store.myName)
    }
}
struct ProfileEditorView: View {
    @EnvironmentObject var store: CircleStore
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var space = ""
    @State private var pet = ""
    @State private var photo: String?
    @State private var item: PhotosPickerItem?
    @State private var favorites: [String] = []
    @State private var error: String?
    private let modules=[("habits","打卡"),("agreements","小约定"),("pet","团团"),("games","今天玩什么"),("capsules","时光胶囊"),("modules","更多玩法")]
    var valid: Bool { let n=nickname.trimmingCharacters(in:.whitespacesAndNewlines); return !n.isEmpty && n.count<=8 && !["阿哲","柚柚","桃桃","糖糖","栗栗","朵朵"].contains(n) }
    var body: some View {
        Form {
            Section("自己的小模样") {
                HStack { Group { if let photo,let image=store.photo(named:photo) { Image(uiImage:image).resizable().scaledToFill() } else { Image(uiImage:PortraitAssets.image(for:"小糖") ?? UIImage()) .resizable().scaledToFill() } }.frame(width:62,height:62).clipShape(Circle()); PhotosPicker("选择自己的头像",selection:$item,matching:.images); Spacer() }.padding(.vertical,9)
                TextField("我的昵称（最多8字）",text:$nickname).accessibilityIdentifier("profileNickname").onChange(of:nickname) { _,v in if v.count>8 { nickname=String(v.prefix(8)) } }
                Text("昵称不能和本机示例成员重名。历史文字保持原样，新消息使用新昵称。").font(.caption).foregroundStyle(Palette.muted)
            }
            Section("给当前小窝起名字") {
                TextField("空间名，留空用默认名字",text:$space).accessibilityIdentifier("profileSpaceName").onChange(of:space) { _,v in if v.count>16 { space=String(v.prefix(16)) } }
                TextField("团团的小名",text:$pet).accessibilityIdentifier("profilePetName").onChange(of:pet) { _,v in if v.count>8 { pet=String(v.prefix(8)) } }
                Text("头像和昵称跟随自己；小窝名、宠物小名和入口排序只影响当前空间。").font(.caption).foregroundStyle(Palette.muted)
            }
            Section("首页优先显示 · 最多选3个") {
                ForEach(modules,id:\.0) { key,name in Button { if favorites.contains(key) { favorites.removeAll{$0==key} } else if favorites.count<3 { favorites.append(key) } } label: { HStack { Text(name).foregroundStyle(Palette.ink); Spacer(); if let i=favorites.firstIndex(of:key) { Text("\(i+1)").font(.caption.bold()).foregroundStyle(.white).frame(width:25,height:25).background(Palette.rose,in:Circle()) } else { Image(systemName:"circle").foregroundStyle(Palette.muted.opacity(0.5)) } } }.accessibilityIdentifier("favorite_\(key)") }
                Text("按勾选顺序排到前面，其余入口继续保留。").font(.caption).foregroundStyle(Palette.muted)
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }.navigationTitle("这是我的小小圈").navigationBarTitleDisplayMode(.inline).tint(Palette.rose)
            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("保存") { store.setProfile(nickname,photo:photo,space:space,pet:pet,favorites:favorites); dismiss() }.disabled(!valid).accessibilityIdentifier("saveProfile") } }
            .onAppear { nickname=store.myName;space=store.growth.spaceName;pet=store.petName;photo=store.state.profile?.avatarPhoto;favorites=store.growth.favoriteModules }
            .onChange(of:item) { _,value in Task { do { if let data=try await value?.loadTransferable(type:Data.self) { photo=try store.savePhoto(data) } } catch { self.error="头像暂时没有读取成功，请重试。" }; item=nil } }
    }
}
