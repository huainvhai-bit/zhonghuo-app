#!/bin/bash

# Xcode 构建诊断脚本
# 用于检查为什么 Xcode 不自动安装到模拟器

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔍 Xcode 构建诊断..."
echo ""

# 1. 检查项目文件
echo "1️⃣ 检查项目文件:"
if [ -f "终活.xcodeproj/project.pbxproj" ]; then
    echo "   ✅ 终活.xcodeproj 存在"
else
    echo "   ❌ 终活.xcodeproj 不存在"
fi

if [ -d "zhonghuo/zhonghuo.xcodeproj" ]; then
    echo "   ⚠️  警告：发现重复的 zhonghuo/zhonghuo.xcodeproj"
else
    echo "   ✅ 没有重复的项目文件"
fi
echo ""

# 2. 检查 Scheme
echo "2️⃣ 检查 Scheme:"
if [ -f "终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme" ]; then
    echo "   ✅ Scheme 文件存在"
    if grep -q "LaunchAction" "终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme"; then
        echo "   ✅ LaunchAction 配置存在"
    fi
else
    echo "   ❌ Scheme 文件不存在"
fi
echo ""

# 3. 检查 Build Phases
echo "3️⃣ 检查 Build Phases:"
if grep -q "PBXFrameworksBuildPhase" "终活.xcodeproj/project.pbxproj"; then
    echo "   ✅ Frameworks BuildPhase 存在"
else
    echo "   ❌ Frameworks BuildPhase 缺失"
fi

if grep -q "Embed Frameworks" "终活.xcodeproj/project.pbxproj"; then
    echo "   ✅ Embed Frameworks BuildPhase 存在"
else
    echo "   ❌ Embed Frameworks BuildPhase 缺失"
fi
echo ""

# 4. 检查模拟器状态
echo "4️⃣ 检查模拟器状态:"
xcrun simctl list devices available | grep "iPhone 17 Pro" | head -3
echo ""

# 5. 检查 DerivedData
echo "5️⃣ 检查 DerivedData:"
DERIVED_DATA=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-* 2>/dev/null | head -1)
if [ -n "$DERIVED_DATA" ]; then
    echo "   ✅ DerivedData 存在：$DERIVED_DATA"
    if [ -d "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/终活.app" ]; then
        echo "   ✅ 应用已构建：终活.app"
    fi
else
    echo "   ❌ DerivedData 不存在"
fi
echo ""

# 6. 尝试手动安装
echo "6️⃣ 尝试手动安装到模拟器:"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/终活.app"
if [ -d "$APP_PATH" ]; then
    xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null
    if xcrun simctl install "iPhone 17 Pro" "$APP_PATH" 2>/dev/null; then
        echo "   ✅ 应用安装成功"
        
        # 尝试启动
        echo "7️⃣ 尝试启动应用:"
        if xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null; then
            echo "   ✅ 应用启动成功"
        else
            echo "   ❌ 应用启动失败"
        fi
    else
        echo "   ❌ 应用安装失败"
    fi
else
    echo "   ❌ 应用未构建，需要先运行 xcodebuild"
fi
echo ""

echo "📊 诊断完成"
echo ""
echo "💡 建议操作:"
echo "1. 在 Xcode 中打开：open -a Xcode 终活.xcodeproj"
echo "2. 选择 Scheme: 终活"
echo "3. 选择设备：iPhone 17 Pro"
echo "4. 按 Cmd + R 运行"
echo "5. 按 Cmd + Shift + Y 查看控制台"
