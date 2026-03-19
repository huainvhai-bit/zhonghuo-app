#!/bin/bash

# Xcode 一键修复和运行脚本
# 用于解决 Xcode 不自动安装到模拟器的问题

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 Xcode 一键修复和运行工具"
echo "================================"
echo ""

# 1. 关闭 Xcode
echo "1️⃣ 关闭 Xcode..."
if killall Xcode 2>/dev/null; then
    echo "   ✅ Xcode 已关闭"
    sleep 1
else
    echo "   ℹ️  Xcode 未运行"
fi
echo ""

# 2. 清理缓存
echo "2️⃣ 清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
echo "   ✅ DerivedData 已清理"
echo ""

# 3. 清理模拟器
echo "3️⃣ 重置模拟器..."
xcrun simctl shutdown "iPhone 17 Pro" 2>/dev/null || true
sleep 1
xcrun simctl boot "iPhone 17 Pro"
echo "   ✅ iPhone 17 Pro 已重启"
echo ""

# 4. 构建
echo "4️⃣ 构建项目..."
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tee /tmp/xcode-build.log | grep -q "BUILD SUCCEEDED"; then
    echo "   ✅ 构建成功"
else
    echo "   ❌ 构建失败，请查看日志："
    tail -30 /tmp/xcode-build.log
    exit 1
fi
echo ""

# 5. 获取应用路径
echo "5️⃣ 查找应用..."
APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    echo "   ❌ 未找到应用"
    exit 1
fi
echo "   ✅ 找到应用"
echo "   路径：$APP_PATH"
echo ""

# 6. 安装
echo "6️⃣ 安装到模拟器..."
xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null || true
if xcrun simctl install "iPhone 17 Pro" "$APP_PATH"; then
    echo "   ✅ 安装成功"
else
    echo "   ❌ 安装失败"
    exit 1
fi
echo ""

# 7. 启动
echo "7️⃣ 启动应用..."
PID=$(xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app 2>&1 | grep -o '[0-9]*' | head -1)
if [ -n "$PID" ]; then
    echo "   ✅ 应用已启动 (PID: $PID)"
else
    echo "   ⚠️  应用可能已启动"
fi
echo ""

# 8. 显示日志
echo "8️⃣ 查看应用日志..."
sleep 2
echo "--- 最近日志 ---"
xcrun simctl spawn booted log show --predicate 'processImagePath ENDSWITH "终活"' --last 2m --style compact 2>&1 | tail -20 || echo "暂无日志"
echo "--- 日志结束 ---"
echo ""

# 9. 打开 Xcode
echo "9️⃣ 打开 Xcode..."
open -a Xcode /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
echo "   ✅ Xcode 已打开"
echo ""

echo "🎉 修复和运行完成！"
echo "================================"
echo ""
echo "📱 模拟器状态:"
echo "   - 设备：iPhone 17 Pro"
echo "   - 应用：终活 (已安装并启动)"
echo "   - PID: $PID"
echo ""
echo "💻 Xcode 操作指南:"
echo "   1. Xcode 应该已经打开"
echo "   2. 确认顶部选择：Scheme='终活', Device='iPhone 17 Pro'"
echo "   3. 按 Cmd + Shift + Y 打开控制台"
echo "   4. 控制台应该显示应用日志"
echo ""
echo "🔍 如果 Xcode 控制台没有日志:"
echo "   1. 在 Xcode 顶部菜单：Debug → Activate Console"
echo "   2. 或按 Cmd + Shift + Y"
echo "   3. 确保选择了正确的进程（终活）"
echo ""
echo "📄 详细排查报告:"
echo "   /Users/lishimin/Documents/zhonghuo-app/Xcode 不自动安装问题 - 深度排查报告.md"
echo ""
