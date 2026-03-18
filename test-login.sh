#!/bin/bash

echo "======================================"
echo "🧪 终活 App 登录测试"
echo "======================================"
echo ""
echo "📱 模拟器状态："
xcrun simctl list devices | grep "iPhone 17 Pro" | grep "Booted"
echo ""

echo "🚀 打开终活 App..."
xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app
sleep 2
echo "✅ App 已打开"
echo ""

echo "📋 请在模拟器中操作："
echo "1. 输入手机号：13800138006"
echo "2. 输入密码：test123456"
echo "3. 点击登录"
echo ""

echo "📝 查看日志（等待 10 秒后自动显示）："
sleep 10
echo ""
echo "======================================"
find ~/Library/Developer/CoreSimulator/Devices -name "checkin_log.txt" -exec tail -30 {} \; 2>/dev/null
echo "======================================"
echo ""
echo "💡 如果看到 404 错误，请告诉我具体错误信息"
