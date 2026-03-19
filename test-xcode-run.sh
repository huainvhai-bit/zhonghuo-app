#!/bin/bash

# Xcode 运行测试脚本
# 用于验证 Xcode 是否可以正确构建和运行

cd /Users/lishimin/Documents/zhonghuo-app

echo "🚀 开始 Xcode 运行测试..."
echo ""

# 1. 清理
echo "1️⃣ 清理旧构建..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
xcrun simctl shutdown "iPhone 17 Pro" 2>/dev/null
echo "   ✅ 清理完成"
echo ""

# 2. 构建
echo "2️⃣ 构建项目..."
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tee /tmp/xcode-build.log | grep -q "BUILD SUCCEEDED"; then
    echo "   ✅ 构建成功"
else
    echo "   ❌ 构建失败"
    tail -20 /tmp/xcode-build.log
    exit 1
fi
echo ""

# 3. 获取应用路径
echo "3️⃣ 查找应用..."
APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    echo "   ✅ 找到应用：$APP_PATH"
else
    echo "   ❌ 未找到应用"
    exit 1
fi
echo ""

# 4. 安装
echo "4️⃣ 安装到模拟器..."
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null
xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null
if xcrun simctl install "iPhone 17 Pro" "$APP_PATH"; then
    echo "   ✅ 安装成功"
else
    echo "   ❌ 安装失败"
    exit 1
fi
echo ""

# 5. 启动
echo "5️⃣ 启动应用..."
if xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app; then
    echo "   ✅ 启动成功"
else
    echo "   ❌ 启动失败"
    exit 1
fi
echo ""

# 6. 查看日志
echo "6️⃣ 查看应用日志..."
sleep 2
xcrun simctl spawn booted log show --predicate 'processImagePath ENDSWITH "终活"' --last 1m --style compact 2>&1 | tail -20
echo ""

echo "🎉 测试完成！"
echo ""
echo "💡 在 Xcode 中运行:"
echo "1. open -a Xcode 终活.xcodeproj"
echo "2. 按 Cmd + R"
echo "3. 按 Cmd + Shift + Y 查看控制台"
