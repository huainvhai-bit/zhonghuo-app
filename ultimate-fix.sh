#!/bin/bash

# Xcode 终极修复脚本
# 完全重置 Xcode 并修复所有问题

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔨 Xcode 终极修复工具"
echo "================================"
echo ""
echo "⚠️  此脚本将重置所有 Xcode 设置"
echo "   按 Ctrl+C 取消，或等待 5 秒继续..."
sleep 5
echo ""

# 1. 关闭 Xcode
echo "1️⃣ 关闭 Xcode..."
killall Xcode 2>/dev/null || echo "   Xcode 未运行"
sleep 2
echo "   ✅ Xcode 已关闭"
echo ""

# 2. 删除 Xcode 配置
echo "2️⃣ 删除 Xcode 配置..."
rm -rf ~/Library/Preferences/com.apple.dt.Xcode.plist
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/UserData/IDEApplicationData
echo "   ✅ 配置已删除"
echo ""

# 3. 清理 DerivedData
echo "3️⃣ 清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
echo "   ✅ DerivedData 已清理"
echo ""

# 4. 重置模拟器
echo "4️⃣ 重置模拟器..."
xcrun simctl shutdown all 2>/dev/null || true
sleep 2
xcrun simctl boot "iPhone 17 Pro"
echo "   ✅ iPhone 17 Pro 已重启"
echo ""

# 5. 清理项目用户数据
echo "5️⃣ 清理项目用户数据..."
rm -rf 终活.xcodeproj/project.xcworkspace/xcuserdata
rm -rf 终活.xcodeproj/xcuserdata
echo "   ✅ 项目用户数据已清理"
echo ""

# 6. 重新生成 Workspace
echo "6️⃣ 重新生成 Workspace..."
mkdir -p 终活.xcodeproj/project.xcworkspace
cat > 终活.xcodeproj/project.xcworkspace/contents.xcworkspacedata << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0">
   <FileRef location="self:"></FileRef>
</Workspace>
EOF
echo "   ✅ Workspace 已生成"
echo ""

# 7. 构建
echo "7️⃣ 构建项目..."
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tee /tmp/xcode-ultimate.log | grep -q "BUILD SUCCEEDED"; then
    echo "   ✅ 构建成功"
else
    echo "   ❌ 构建失败"
    tail -30 /tmp/xcode-ultimate.log
    exit 1
fi
echo ""

# 8. 安装
echo "8️⃣ 安装到模拟器..."
APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app | head -1)
xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null || true
if xcrun simctl install "iPhone 17 Pro" "$APP_PATH"; then
    echo "   ✅ 安装成功"
else
    echo "   ❌ 安装失败"
    exit 1
fi
echo ""

# 9. 启动
echo "9️⃣ 启动应用..."
PID=$(xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app 2>&1 | grep -o '[0-9]*' | head -1)
if [ -n "$PID" ]; then
    echo "   ✅ 应用已启动 (PID: $PID)"
else
    echo "   ⚠️  应用可能已启动"
fi
echo ""

# 10. 打开 Xcode
echo "🔟 打开 Xcode..."
open -a Xcode /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
echo "   ✅ Xcode 已打开"
echo ""

# 11. 显示日志
echo "1️⃣1️⃣ 显示应用日志..."
sleep 3
echo "--- 最近日志 ---"
xcrun simctl spawn booted log show --predicate 'processImagePath ENDSWITH "终活"' --last 2m --style compact 2>&1 | tail -20 || echo "暂无日志"
echo "--- 日志结束 ---"
echo ""

echo "================================"
echo "🎉 终极修复完成！"
echo ""
echo "📱 应用状态:"
echo "   - 设备：iPhone 17 Pro"
echo "   - 应用：终活 (已安装并启动)"
echo "   - PID: $PID"
echo ""
echo "💻 Xcode 操作:"
echo "   1. Xcode 应该已经打开"
echo "   2. 选择 Scheme: 终活"
echo "   3. 选择设备：iPhone 17 Pro"
echo "   4. 按 Cmd + Shift + Y 打开控制台"
echo "   5. 控制台应该显示日志"
echo ""
echo "🔍 如果还是不行，请提供:"
echo "   - Xcode 版本：$(xcodebuild -version | head -1)"
echo "   - macOS 版本：$(sw_vers -productVersion)"
echo "   - 具体错误信息"
echo ""
