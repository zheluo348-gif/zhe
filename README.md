# 小小圈

面向情侣和最多8人的好友小圈子的 iPhone 原生 App 原型，使用 SwiftUI。当前源码版本 **0.4.3（8）**，最低支持 iOS 17，不依赖第三方 Swift 包。

当前为本机体验版：页面、互动、记录与小游戏在当前设备运行和保存。真实账号、邀请、跨设备消息、推送、AI生成和支付尚未接入。初始人物、消息和插画为演示内容，本机操作不会发送给其他用户。

## 已实现的体验

- 情侣和好友空间在同一App中；创建、加入与管理入口位于“我的 → 我的空间”，首页只展示当前空间。
- 文字、照片、绘图、语音便签、手动贴纸、小纸条聊天、三档蓄力抱抱与明确标注的接收端本机效果预览。
- 可选的文字阅后即焚：发送前选择查看后5、10、30或60秒销毁，仅作用于下一条文字；普通消息默认保留。
- 按互动草图重排的首页：双头像、小窝横幅、“TA此刻”与“我的此刻”、常用玩法。自己的文字状态可编辑，对方未连接的数据明确留空。
- 聊天内一起续画：轮流添加笔迹或一句话，保留每轮署名；至少两位成员参与后可完成作品，并保存到本机共同回忆。
- 回忆、照片墙、愿望、打卡、小约定、奖励券、时间胶囊、日历、记账、团团养成、衣橱与每日贴纸。
- 默契问答、五子棋、接龙、画猜、真心话、决策转盘，以及聊天里的游戏邀请与结果卡。
- 昵称、头像、空间名、宠物小名与首页入口排序。
- 按累计来访日成长，第1、2、3、7、10天保留早期惊喜；第30天起每30天解锁一个壁纸主题。首年12个主题，之后按季提供配色与装饰变体；已解锁壁纸可重新使用。中断来访不清零，恋爱纪念日另行计算。
- 个人AI开关默认关闭，选择在本机保存。关闭时可继续基础玩法；目前仅预留受开关保护的请求边界，尚无真实AI生成服务。

状态分享页目前是主动填写的本机设置，未获取远程成员的实时电量或天气。小游戏、多人回答和抱抱预览也不能视作已完成双机联动。

## 阅后即焚

聊天输入区的“普通消息”菜单可以选择销毁时长。发送后自动回到普通消息模式；照片、画画、语音和贴贴不受该选项影响。

阅后即焚内容在列表中显示为封好的卡片，只有点开查看才开始倒计时。关闭后在剩余时间内可以再次查看，计时不会重置。到期后清除内容，只保留“消息已销毁”的提示。进入后台继续按原期限计算，关闭App后会在下次启动时清除过期内容。普通消息和未查看的消息保留。

阅后即焚消息没有复制、引用回复或保存回忆入口，也不包含在文字导出中。开启此模式后，输入中的草稿不持久保存。

当前为本机体验：点击“本机点开查看”模拟阅读，不代表远端用户已经收到或阅读。真实接收、已读时间与多设备销毁同步仍需联网版实现。0.4.2尚需在Mac上完成Xcode编译、模拟器UI测试与真机验证。

## 首页与一起续画

首页按 [互动草图](docs/interaction-concepts.md) 的整页顺序实现：空间双头像和名称、小窝横幅、对方状态大卡片、自己的状态卡片，以及常用玩法。日历和分享设置位于顶栏；“抱抱TA”和“留张纸条”进入本机聊天。“我的此刻”显示现有的本人状态，可直接编辑。对方的心情、精力、电量显示“待分享／未连接”，没有使用草图的示例数字。

默认横幅使用新的暖色小窝插画；手动选择的成长壁纸仍会展示。成长、喂团团、照片墙、未来信箱和原有玩法入口保留。

聊天输入区点击“一起画”发起一张续画卡片，每轮可画画、手写或添一句话，交出后换下一位。之前交出的笔迹作为底图保留，橡皮和清空只影响本轮。关闭页面时会提示处理未交出的内容；交出的轮次会持久保存，重新打开可继续。至少两位成员参与后可点“完成作品”，再保存到共同回忆。每轮最多128KB、80字，最多24轮，使用轮次版本防止重复提交覆盖。

这些操作当前均为本机体验，不是跨手机实时协作。0.4.3新增的`HomeAndSharedDrawingTests`仍需在Mac上执行；本云环境无法完成iOS编译、界面截图或真机更新。

## 用 Xcode 运行

1. 在安装了Xcode的Mac上获取本仓库，打开 `XiaoXiaoQuan/XiaoXiaoQuan.xcodeproj`。
2. 选择 **XiaoXiaoQuan** scheme 和一个 iPhone 模拟器，点击运行。
3. 真机运行时，在 **Signing & Capabilities** 中选择你自己的开发团队和已配对的 iPhone；根据自己的账号设置可用的 Bundle Identifier。仓库不包含证书、描述文件或账号凭据。

本版本曾使用Xcode 26.6、iOS 26.5模拟器编译和验证，并完成iPhone真机安装与正常启动核验。其他工具链与设备需自行验证。

从仓库根目录进行不签名的模拟器编译：

```sh
xcodebuild \
  -project XiaoXiaoQuan/XiaoXiaoQuan.xcodeproj \
  -scheme XiaoXiaoQuan \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath XiaoXiaoQuan/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

如需脚本安装到指定模拟器，先运行 `xcrun simctl list devices available` 找到模拟器编号，再执行：

```sh
zsh XiaoXiaoQuan/Tools/run-preview.sh YOUR_SIMULATOR_UDID
```

脚本也接受 `XXQ_SIMULATOR_UDID` 环境变量，不包含开发者本机设备编号。请使用专用测试模拟器。

## 验证

界面自动化位于 `XiaoXiaoQuan/Tests`，使用独立测试存储。`--uitesting --reset` 只清理测试存储域；普通运行不传这些参数。成长天数样本只在测试模式和重置参数同时存在时生效。

从仓库根目录运行规则检查：

```sh
python3 XiaoXiaoQuan/Tools/check_growth_rules.py
python3 XiaoXiaoQuan/Tools/check_playground_logic.py
python3 XiaoXiaoQuan/Tools/check_disappearing_messages.py
```

三条命令都会生成、编译并执行对应的Swift规则检查，编译或断言失败会返回非零状态。分别覆盖263项成长/AI/邀请/续画、31项既有玩法和113项阅后即焚规则，采用内存存储适配器，不能替代界面或真实网络测试。0.4.3的407项规则检查在Linux云环境通过。0.4.1此前定向UI验证覆盖8个不同流程，最终补验4/4通过；新增的`DisappearingMessageTests`和`HomeAndSharedDrawingTests`需在Mac上执行。

macOS使用Xcode的`xcrun swiftc`；Linux优先使用本机`swiftc`，未安装时使用本机Docker中的Swift 6.2.1镜像。镜像按`XiaoXiaoQuan/Tools/swift_rules.py`中的SHA-256摘要固定，首次运行时自动下载，需要本机Docker服务已启动。检查容器禁用网络，只挂载`tmp/`中的生成文件，并以当前用户运行。同一检出目录的Docker检查通过文件锁串行执行，避免VFS存储重复复制工具链耗尽磁盘。Linux上的规则检查通过不代表iOS界面或真机测试通过。

在Xcode的Test菜单运行界面测试；或指定专用模拟器：

```sh
xcodebuild \
  -project XiaoXiaoQuan/XiaoXiaoQuan.xcodeproj \
  -scheme XiaoXiaoQuan \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -derivedDataPath XiaoXiaoQuan/DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

## AI接入状态

App只应向自己的HTTPS后端发请求，由后端管理模型平台密钥。现有 `CreativeService` 预留 `/v1/creative/generate`，需要后续实现登录、空间权限、用户授权、服务端额度、频率限制和成功结果处理。当前没有配置服务地址或访问令牌，启用开关不会购买、订阅或扣费。照片上传给AI、AI图片结果展示和正式付费尚未实现。

## 仓库结构

- `XiaoXiaoQuan/Sources/`：SwiftUI页面、互动和本机状态模型。
- `XiaoXiaoQuan/Resources/`：图标、插画与素材目录。
- `XiaoXiaoQuan/Tests/`：UI自动化测试。
- `XiaoXiaoQuan/Tools/`：项目生成、规则检查和模拟器启动脚本。
- `XiaoXiaoQuan/XiaoXiaoQuan.xcodeproj/`：Xcode项目及共享scheme。

`output/`、`tmp/`、`DerivedData*`、测试结果、手机备份、签名文件和密钥不提交。项目文件可通过 `python3 XiaoXiaoQuan/Tools/generate_project.py` 重新生成；本地签名设置不应写入共享生成脚本。
