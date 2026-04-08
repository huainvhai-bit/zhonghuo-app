#!/bin/bash
# 
# Xcode 项目文件修复脚本
# 
# 问题: 重构后，项目文件引用的 Swift 文件路径过时
# 解决: 使用 Xcode IDE 手动更新项目文件
#

echo "=== Xcode 项目修复指南 ==="
echo ""
echo "问题: 项目文件引用了过时的文件路径"
echo ""

# 列出缺失的文件（在根目录不存在但在模块中）
echo "需要添加到 Xcode 项目的模块目录："
echo "  - Auth/"
echo "  - Capsule/"
echo "  - Family/"
echo "  - Home/"
echo "  - Location/"
echo "  - Models/"
echo "  - Services/"
echo "  - Settings/"
echo "  - User/"
echo ""

echo "提示: 在 Xcode 中操作："
echo "  1. 打开 终活.xcodeproj"
echo "  2. 右键点击项目导航器中的项目图标"
echo "  3. 选择 'Add Files to '终活''"
echo "  4. 选择上述模块目录，勾选 'Create folder references'"
echo "  5. 删除根目录中不存在的旧文件引用"
echo ""

echo "完成后，点击 Product > Build 编译项目"
