#!/bin/bash
# 临时注释 CodeScanner 依赖，让编译通过

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 正在临时注释 CodeScanner 依赖..."

# 备份原始文件
cp BindFamilyView.swift BindFamilyView.swift.bak
cp FamilyGuardView.swift FamilyGuardView.swift.bak

# 注释 BindFamilyView.swift 中的 CodeScanner
sed -i '' 's/^import CodeScanner$/\/\/ import CodeScanner  \/\/ 暂时注释/' BindFamilyView.swift
echo "  ✅ BindFamilyView.swift"

# 注释 FamilyGuardView.swift 中的 CodeScanner
sed -i '' 's/^import CodeScanner$/\/\/ import CodeScanner  \/\/ 暂时注释/' FamilyGuardView.swift
echo "  ✅ FamilyGuardView.swift"

echo ""
echo "✅ CodeScanner 已临时注释"
echo ""
echo "📝 现在可以编译了:"
echo "   xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build"
echo ""
echo "⚠️  注意：扫码功能暂时不可用，恢复方法:"
echo "   git checkout BindFamilyView.swift FamilyGuardView.swift"
echo ""
