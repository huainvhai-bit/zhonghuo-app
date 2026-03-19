#!/bin/bash

# 终活 App - Xcode 项目修复脚本
# 添加缺失的 Build Phases

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 开始修复 Xcode 项目..."

PBXPROJ="终活.xcodeproj/project.pbxproj"

# 备份
cp "$PBXPROJ" "$PBXPROJ.backup"
echo "✅ 已备份原文件"

# 1. 添加 Embed Frameworks BuildPhase
# 在 PBXCopyFilesBuildPhase section 前添加新的 section

# 生成新的 UUID
EMBED_PHASE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-')
EMBED_PHASE_UUID="A7${EMBED_PHASE_UUID:0:6}"

echo "📦 添加 Embed Frameworks BuildPhase..."

# 使用 sed 添加 Embed Frameworks 阶段
# 找到 buildPhases 数组，添加新的 phase

# 更简单的方法：使用 Python 脚本
python3 << 'PYTHON_SCRIPT'
import re
import uuid

# 读取文件
with open('终活.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    content = f.read()

# 生成 UUID
def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

# 检查是否已有 Embed Frameworks
if 'Embed Frameworks' in content:
    print("✅ Embed Frameworks 已存在")
else:
    print("📦 添加 Embed Frameworks BuildPhase...")
    
    # 生成新的 UUID
    embed_phase_id = f"A7{generate_uuid()[:6]}"
    
    # 创建新的 Embed Frameworks BuildPhase
    embed_phase = f"""
		{embed_phase_id} /* Embed Frameworks */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 10;
			files = (
			);
			name = "Embed Frameworks";
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
    
    # 在 Begin PBXCopyFilesBuildPhase section 前插入
    if '/* Begin PBXCopyFilesBuildPhase section */' in content:
        content = content.replace(
            '/* Begin PBXCopyFilesBuildPhase section */',
            f'/* Begin PBXCopyFilesBuildPhase section */{embed_phase}'
        )
    else:
        # 如果没有 CopyFiles 阶段，在 Sources 阶段后添加
        content = content.replace(
            '/* End PBXSourcesBuildPhase section */',
            f'/* End PBXSourcesBuildPhase section */\n{embed_phase}'
        )
    
    # 添加 buildPhases 引用
    # 找到 buildPhases = ( ... ); 并添加新的 phase
    build_phases_pattern = r'(buildPhases = \(\s*A7000000 /\* Sources \*/,\s*A7000001 /\* Resources \*/)'
    replacement = f'\\1,\n\t\t\t\t{embed_phase_id} /* Embed Frameworks */'
    content = re.sub(build_phases_pattern, replacement, content)

# 写入文件
with open('终活.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 修复完成")
PYTHON_SCRIPT

echo ""
echo "🗑️  清理 DerivedData..."
rm -rf /Users/lishimin/Library/Developer/Xcode/DerivedData/终活-*

echo "✅ 项目修复完成！"
echo ""
echo "📋 下一步："
echo "1. 在 Xcode 中打开项目"
echo "2. 按 Cmd + B 重新构建"
echo "3. 按 Cmd + R 运行到模拟器"
