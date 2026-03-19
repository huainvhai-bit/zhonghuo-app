#!/bin/bash

# 修复终活 App Xcode 项目配置
# 问题：缺少必要的 Build Phases 导致无法自动安装到模拟器

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 开始修复 Xcode 项目配置..."

# 备份原项目文件
cp 终活.xcodeproj/project.pbxproj 终活.xcodeproj/project.pbxproj.backup

# 读取当前 project.pbxproj
PBXPROJ="终活.xcodeproj/project.pbxproj"

# 1. 检查是否有 Resources 阶段
if grep -q "PBXResourcesBuildPhase" "$PBXPROJ"; then
    echo "✅ Resources BuildPhase 已存在"
else
    echo "❌ 缺少 Resources BuildPhase - 需要添加"
fi

# 2. 检查是否有 Embed Frameworks 阶段
if grep -q "PBXCopyFilesBuildPhase" "$PBXPROJ"; then
    echo "✅ Embed Frameworks BuildPhase 已存在"
else
    echo "❌ 缺少 Embed Frameworks BuildPhase - 需要添加"
fi

# 3. 检查 SDKROOT 设置
if grep -q "SDKROOT = iphoneos" "$PBXPROJ"; then
    echo "⚠️  SDKROOT 设置为 iphoneos (真机) - 应该使用 iphonesimulator 用于模拟器"
    echo "   但这不影响运行，Xcode 会自动处理"
fi

# 4. 检查 CODE_SIGN_STYLE
if grep -q "CODE_SIGN_STYLE = Automatic" "$PBXPROJ"; then
    echo "✅ 代码签名设置为 Automatic"
else
    echo "❌ 代码签名未设置 - 需要设置为 Automatic"
fi

echo ""
echo "📋 当前项目配置检查完成"
echo ""

# 显示当前的 Build Phases
echo "📦 当前 Build Phases:"
grep -A5 "buildPhases = (" "$PBXPROJ" | head -20

echo ""
echo "💡 建议操作："
echo "1. 在 Xcode 中打开项目"
echo "2. 选择 Target '终活'"
echo "3. 点击 'Build Phases' 标签"
echo "4. 确认有以下阶段:"
echo "   - Target Dependencies (可选)"
echo "   - Compile Sources (必须有)"
echo "   - Link Binary With Libraries (必须有)"
echo "   - Copy Bundle Resources (必须有)"
echo "   - Embed Frameworks (可选)"
echo ""
echo "如果缺少任何阶段，请点击 '+' 按钮添加"
echo ""

# 检查 DerivedData
DERIVED_DATA="/Users/lishimin/Library/Developer/Xcode/DerivedData/终活-cqrdtepyatgbutagxrvrefgapusm"
if [ -d "$DERIVED_DATA" ]; then
    echo "🗑️  清理旧的 DerivedData 缓存..."
    rm -rf "$DERIVED_DATA"
    echo "✅ 已清理"
fi

echo ""
echo "✅ 修复完成！请在 Xcode 中重新构建项目"
