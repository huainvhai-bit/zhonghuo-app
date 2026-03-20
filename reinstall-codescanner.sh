#!/bin/bash
# 强制重新安装 CodeScanner Package

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 强制重新安装 CodeScanner Package..."
echo ""

# 1. 关闭 Xcode
echo "📱 关闭 Xcode..."
killall Xcode 2>/dev/null || true
sleep 2
echo ""

# 2. 清理所有缓存
echo "🗑️  清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
rm -rf ~/Library/Developer/Xcode/Package.resolved
rm -rf ~/Library/Caches/org.swift.swiftpm/repositories
rm -rf 终活.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
echo "✅ 缓存清理完成"
echo ""

# 3. 备份项目文件
echo "💾 备份项目文件..."
cp 终活.xcodeproj/project.pbxproj 终活.xcodeproj/project.pbxproj.backup
echo ""

# 4. 移除 Package 引用（临时）
echo "📦 移除 Package 引用..."
# 这里需要手动在 Xcode 中操作
echo "⚠️  请在 Xcode 中手动移除 Package："
echo "   1. 打开 终活.xcodeproj"
echo "   2. 左侧 → Package Dependencies"
echo "   3. 右键 CodeScanner → Remove Package"
echo ""

# 5. 重新打开 Xcode
echo "🚀 重新打开 Xcode..."
open 终活.xcodeproj
echo ""

echo "✅ 准备完成！"
echo ""
echo "📝 接下来在 Xcode 中操作："
echo ""
echo "1. 移除旧的 CodeScanner Package（如果存在）"
echo "2. 重新添加 Package："
echo "   - File → Add Package Dependencies..."
echo "   - URL: https://github.com/twostraws/CodeScanner.git"
echo "   - Version: Up to Next Major, 2.0.0"
echo "3. 等待下载完成"
echo "4. Product → Clean Build Folder (Shift+Command+K)"
echo "5. Product → Build (Command+B)"
echo ""
