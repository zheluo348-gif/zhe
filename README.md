# 小小圈

面向情侣和最多8人的好友小圈子的 iPhone 原生 App 原型，使用 SwiftUI。当前版本 **0.4.1（6）**，最低支持 iOS 17，不依赖第三方 Swift 包。

当前为本机体验版：页面、互动、记录与小游戏在当前设备运行和保存。真实账号、邀请、跨设备消息、推送、AI生成和支付尚未接入。初始人物、消息和插画为演示内容，本机操作不会发送给其他用户。

## 已实现的体验

- 情侣和好友空间在同一App中；创建、加入与管理入口位于“我的 → 我的空间”，首页只展示当前空间。
- 文字、照片、绘图、语音便签、手动贴纸、小纸条聊天、三档蓄力抱抱与明确标注的接收端本机效果预览。
- 回忆、照片墙、愿望、打卡、小约定、奖励券、时间胶囊、日历、记账、团团养成、衣橱与每日贴纸。
- 默契问答、五子棋、接龙、画猜、真心话、决策转盘，以及聊天里的游戏邀请与结果卡。
- 昵称、头像、空间名、宠物小名与首页入口排序。
- 按累计来访日成长，第1、2、3、7、10天保留早期惊喜；第30天起每30天解锁一个壁纸主题。首年12个主题，之后按季提供配色与装饰变体；已解锁壁纸可重新使用。中断来访不清零，恋爱纪念日另行计算。
- 个人AI开关默认关闭，选择在本机保存。关闭时可继续基础玩法；目前仅预留受开关保护的请求边界，尚无真实AI生成服务。

状态分享页目前是主动填写的本机设置，未获取远程成员的实时电量或天气。小游戏、多人回答和抱抱预览也不能视作已完成双机联动。

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
xcrun swiftc -parse-as-library tmp/PlaygroundLogicChecks.swift -o tmp/PlaygroundLogicChecks
./tmp/PlaygroundLogicChecks
```

前者直接编译并运行成长、月度壁纸、AI选择和邀请规则；后者生成Swift校验程序，再由后两行编译运行。两者采用内存存储适配器，不能替代界面或真实网络测试。0.4.1已通过206项成长/AI/邀请规则和31项既有玩法规则检查；本次定向UI验证覆盖8个不同流程，最终补验4/4通过。

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
