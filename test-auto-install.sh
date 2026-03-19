#!/bin/bash

# 测试 Xcode 是否能自动安装

cd /Users/lishimin/Documents/zhonghuo-app

echo "🧪 测试 Xcode 自动安装功能"
echo "================================"
echo ""

# 1. 清理
echo "1️⃣ 清理..."
killall Xcode 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
xcrun simctl shutdown "iPhone 17 Pro" 2>/dev/null || true
sleep 2
xcrun simctl boot "iPhone 17 Pro"
echo "   ✅"
echo ""

# 2. 使用 xcodebuild 构建并运行
echo "2️⃣ 使用 xcodebuild build + run..."
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' run 2>&1 | tee /tmp/xcode-run.log | grep -E "(BUILD|Launching|installed)" | tail -10; then
    echo ""
    echo "✅ xcodebuild run 完成"
else
    echo ""
    echo "❌ xcodebuild run 失败"
fi
echo ""

# 3. 检查应用是否运行
echo "3️⃣ 检查应用状态..."
if xcrun simctl list apps booted | grep -q "com.zhonghuo.app"; then
    echo "   ✅ 应用已安装"
    if xcrun simctl list apps booted | grep "com.zhonghuo.app" | grep -q "running"; then
        echo "   ✅ 应用正在运行"
    else
        echo "   ⚠️  应用已安装但未运行"
    fi
else
    echo "   ❌ 应用未安装"
fi
echo ""

# 4. 查看日志
echo "4️⃣ 查看应用日志..."
sleep 3
xcrun simctl spawn booted log show --predicate 'processImagePath ENDSWITH "终活"' --last 2m --style compact 2>&1 | tail -20 || echo "暂无日志"
echo ""

echo "================================"
echo "📊 测试结果:"
echo ""
echo "如果应用已安装并运行，说明项目配置已修复！"
echo "在 Xcode 中按 Cmd+R 应该也能正常工作了。"
echo ""
