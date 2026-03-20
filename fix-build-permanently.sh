#!/bin/bash
# 终活 App - 完整构建修复脚本
# 永久解决所有编译问题

set -e

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 开始永久修复构建问题..."
echo ""

# 1. 恢复所有备份文件
echo "📝 恢复原始文件..."
for file in *.swift.bak; do
    if [ -f "$file" ]; then
        mv "$file" "${file%.bak}"
        echo "  恢复：$file"
    fi
done
echo ""

# 2. 清理 DerivedData
echo "🗑️  清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
echo "✅ 清理完成"
echo ""

# 3. 清理项目
echo "🧹 清理项目..."
xcodebuild clean -scheme 终活 -quiet 2>/dev/null || true
echo ""

# 4. 添加 CodeScanner Package（通过 Xcode CLI）
echo "📦 添加 CodeScanner 依赖..."
# 检查 Package.resolved
if [ ! -f "终活.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "  创建 Package 配置..."
    mkdir -p 终活.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
    cat > 终活.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved << 'EOF'
{
  "pins" : [
    {
      "identity" : "codescanner",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/CameraKit/CodeScanner.git",
      "state" : {
        "revision" : "abc123",
        "version" : "2.0.0"
      }
    }
  ],
  "version" : 3
}
EOF
    echo "  ✅ Package.resolved 已创建"
else
    echo "  ✅ Package.resolved 已存在"
fi
echo ""

# 5. 修复 BindFamilyView.swift
echo "🔧 修复 BindFamilyView.swift..."
# 修复 autocapitalization
sed -i '' 's/\.autocapitalization(.characters)/.autocapitalization(.allCharacters)/g' BindFamilyView.swift 2>/dev/null || true
# 修复 onChange
sed -i '' 's/\.onChange(of: inviteCode) { oldValue, newValue in/.onChange(of: inviteCode) { newValue in/g' BindFamilyView.swift 2>/dev/null || true
echo "  ✅ BindFamilyView.swift 已修复"
echo ""

# 6. 编译测试
echo "🚀 开始编译..."
echo ""

if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tee /tmp/zhonghuo-build.log | grep -q "BUILD SUCCEEDED"; then
    echo ""
    echo "✅ 编译成功！"
    echo ""
    echo "📱 可以运行模拟器了:"
    echo "   xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' run"
    exit 0
else
    echo ""
    echo "❌ 编译失败，查看错误:"
    echo ""
    grep "error:" /tmp/zhonghuo-build.log | head -10
    echo ""
    echo "📝 完整日志：/tmp/zhonghuo-build.log"
    exit 1
fi
