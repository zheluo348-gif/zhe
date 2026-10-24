#!/bin/zsh
set -euo pipefail
TASK_APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_SIM_ID="${1:-${XXQ_SIMULATOR_UDID:-}}"
if [[ -z "$TASK_SIM_ID" ]]; then
  print -u2 'Usage: zsh XiaoXiaoQuan/Tools/run-preview.sh YOUR_SIMULATOR_UDID'
  print -u2 'List simulators with: xcrun simctl list devices available'
  exit 2
fi
xcrun simctl bootstatus "$TASK_SIM_ID" -b
xcodebuild -project "$TASK_APP_ROOT/XiaoXiaoQuan.xcodeproj" -scheme XiaoXiaoQuan -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$TASK_SIM_ID" -derivedDataPath "$TASK_APP_ROOT/DerivedData" ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
xcrun simctl install "$TASK_SIM_ID" "$TASK_APP_ROOT/DerivedData/Build/Products/Debug-iphonesimulator/XiaoXiaoQuan.app"
xcrun simctl launch "$TASK_SIM_ID" com.xinbei.xiaoxiaoquan.preview
