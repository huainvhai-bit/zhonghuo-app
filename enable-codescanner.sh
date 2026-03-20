#!/bin/bash
# 启用 CodeScanner 扫码功能

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 启用 CodeScanner 扫码功能..."
echo ""

# 1. 恢复 BindFamilyView.swift 中的扫码代码
echo "📝 恢复 BindFamilyView.swift 扫码功能..."

# 恢复 import
sed -i '' 's|^// import CodeScanner|import CodeScanner|g' BindFamilyView.swift

# 恢复扫码按钮
sed -i '' 's|// 扫码按钮 - 待 CodeScanner 依赖配置完成后启用|// 扫码按钮|g' BindFamilyView.swift
sed -i '' 's|/\*||g' BindFamilyView.swift
sed -i '' 's|\*/||g' BindFamilyView.swift

echo "✅ BindFamilyView.swift 已更新"
echo ""

# 2. 恢复 FamilyGuardView.swift
echo "📝 恢复 FamilyGuardView.swift..."
sed -i '' 's|^// CodeScanner 依赖 - 待 Xcode 正确配置后启用||g' FamilyGuardView.swift
sed -i '' 's|^// import CodeScanner|import CodeScanner|g' FamilyGuardView.swift

echo "✅ FamilyGuardView.swift 已更新"
echo ""

echo "✅ CodeScanner 功能已启用！"
echo ""
echo "📝 下一步：在 Xcode 中添加 Package 依赖"
echo "   1. 打开 终活.xcodeproj"
echo "   2. File → Add Package Dependencies..."
echo "   3. 输入：https://github.com/twostraws/CodeScanner.git"
echo "   4. 版本：2.0.0+"
echo "   5. 勾选 终活"
echo ""
