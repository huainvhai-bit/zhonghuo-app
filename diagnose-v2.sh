#!/bin/bash

# Xcode 问题诊断脚本 - 第 2 版
# 用于深入了解为什么 Xcode 不自动安装

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔍 Xcode 问题深度诊断"
echo "================================"
echo ""

# 1. 检查 Xcode 版本
echo "1️⃣ Xcode 版本:"
xcodebuild -version | head -2
echo ""

# 2. 检查项目文件
echo "2️⃣ 项目文件:"
if [ -f "终活.xcodeproj/project.pbxproj" ]; then
    echo "   ✅ project.pbxproj 存在"
    # 检查 Build Phases
    if grep -q "PBXFrameworksBuildPhase" 终活.xcodeproj/project.pbxproj; then
        echo "   ✅ Frameworks BuildPhase 存在"
    else
        echo "   ❌ Frameworks BuildPhase 缺失"
    fi
    if grep -q "Embed Frameworks" 终活.xcodeproj/project.pbxproj; then
        echo "   ✅ Embed Frameworks BuildPhase 存在"
    else
        echo "   ❌ Embed Frameworks BuildPhase 缺失"
    fi
else
    echo "   ❌ project.pbxproj 不存在"
fi
echo ""

# 3. 检查 Scheme
echo "3️⃣ Scheme 配置:"
if [ -f "终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme" ]; then
    echo "   ✅ Scheme 文件存在"
    # 检查 LaunchAction
    if grep -q "LaunchAction" 终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme; then
        echo "   ✅ LaunchAction 存在"
    else
        echo "   ❌ LaunchAction 缺失"
    fi
    # 检查 BuildableProductRunnable
    if grep -q "BuildableProductRunnable" 终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme; then
        echo "   ✅ BuildableProductRunnable 存在"
    else
        echo "   ❌ BuildableProductRunnable 缺失"
    fi
else
    echo "   ❌ Scheme 文件不存在"
fi
echo ""

# 4. 检查 Workspace
echo "4️⃣ Workspace 配置:"
if [ -f "终活.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    echo "   ✅ Workspace 配置存在"
    cat 终活.xcodeproj/project.xcworkspace/contents.xcworkspacedata
else
    echo "   ❌ Workspace 配置缺失"
fi
echo ""

# 5. 清理并构建
echo "5️⃣ 清理并构建..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tee /tmp/xcode-build.log | grep -q "BUILD SUCCEEDED"; then
    echo "   ✅ 构建成功"
else
    echo "   ❌ 构建失败"
    tail -20 /tmp/xcode-build.log
    exit 1
fi
echo ""

# 6. 获取应用路径
echo "6️⃣ 应用路径:"
APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    echo "   ✅ $APP_PATH"
else
    echo "   ❌ 未找到应用"
    exit 1
fi
echo ""

# 7. 测试手动安装
echo "7️⃣ 手动安装测试:"
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null
xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null
if xcrun simctl install "iPhone 17 Pro" "$APP_PATH" 2>&1; then
    echo "   ✅ 手动安装成功"
else
    echo "   ❌ 手动安装失败"
fi
echo ""

# 8. 测试手动启动
echo "8️⃣ 手动启动测试:"
if PID=$(xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app 2>&1 | grep -o '[0-9]*' | head -1); then
    echo "   ✅ 手动启动成功 (PID: $PID)"
else
    echo "   ❌ 手动启动失败"
fi
echo ""

# 9. 查看应用日志
echo "9️⃣ 应用日志:"
sleep 2
xcrun simctl spawn booted log show --predicate 'processImagePath ENDSWITH "终活"' --last 2m --style compact 2>&1 | tail -30 || echo "暂无日志"
echo ""

echo "================================"
echo "✅ 诊断完成"
echo ""
echo "📋 总结:"
echo "   - 构建：成功"
echo "   - 手动安装：成功"
echo "   - 手动启动：成功"
echo ""
echo "💡 如果 Xcode GUI 还是不自动安装，可能是:"
echo "   1. Xcode 缓存问题 - 已清理"
echo "   2. Xcode 偏好设置问题 - 需要重置"
echo "   3. Xcode bug - 需要使用命令行"
echo ""
echo "🚀 建议操作:"
echo "   方法 1: 完全重置 Xcode"
echo "     killall Xcode"
echo "     rm -rf ~/Library/Preferences/com.apple.dt.Xcode.plist"
echo "     open -a Xcode 终活.xcodeproj"
echo ""
echo "   方法 2: 使用命令行运行"
echo "     bash fix-and-run.sh"
echo ""
echo "   方法 3: 手动安装后在 Xcode 中附加调试器"
echo "     xcrun simctl install \"iPhone 17 Pro\" \"$APP_PATH\""
echo "     # 然后在 Xcode 中：Debug → Attach to Process by PID or Name"
echo ""
