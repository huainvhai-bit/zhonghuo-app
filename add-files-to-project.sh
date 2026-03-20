#!/bin/bash
# 自动添加新文件到 Xcode 项目

set -e

PROJECT_DIR="/Users/lishimin/Documents/zhonghuo-app"
PROJECT_FILE="$PROJECT_DIR/终活.xcodeproj/project.pbxproj"

echo "🔧 正在添加新文件到 Xcode 项目..."

cd "$PROJECT_DIR"

# 需要添加的文件
FILES=(
  "DeviceMonitor.swift"
  "FamilyMember.swift"
  "FamilyGuardView.swift"
  "InviteCodeView.swift"
  "BindFamilyView.swift"
  "FamilyMemberDetailView.swift"
)

# 使用 pbxproj 工具添加文件（如果有的话）
if command -v pbxproj &> /dev/null; then
  for file in "${FILES[@]}"; do
    echo "  添加 $file"
    pbxproj file add "$file" --project "$PROJECT_FILE"
  done
  echo "✅ 文件添加完成"
else
  echo "⚠️  pbxproj 工具未安装"
  echo ""
  echo "📝 请手动在 Xcode 中添加文件："
  echo ""
  echo "1. 打开 Xcode 项目"
  echo "2. 右键点击 '终活/' 文件夹"
  echo "3. 选择 'Add Files to 终活...'"
  echo "4. 添加以下 6 个文件："
  for file in "${FILES[@]}"; do
    echo "   - $file"
  done
  echo "5. 确保勾选 'Copy items if needed' 和 'Add to targets: 终活'"
  echo "6. 点击 'Add'"
  echo ""
  echo "或者使用以下命令安装 pbxproj："
  echo "  pip3 install pbxproj"
  echo ""
fi
