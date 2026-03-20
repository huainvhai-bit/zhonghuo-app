#!/bin/bash
# 添加 AccountValidator.swift 到 Xcode 项目

PROJECT_FILE="终活.xcodeproj/project.pbxproj"
NEW_FILE="AccountValidator.swift"

# 生成新的 UUID
UUID1=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-')
UUID2=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-')

echo "Generated UUIDs: $UUID1, $UUID2"

# 找到 FamilyMember.swift 的行号作为参考
LINE_NUM=$(grep -n "FamilyMember.swift" "$PROJECT_FILE" | head -1 | cut -d: -f1)

# 在 FamilyMember.swift 之前插入 AccountValidator.swift
sed -i.bak "${LINE_NUM}i\\
		${UUID1} /* AccountValidator.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${UUID2} /* AccountValidator.swift */; };\\
" "$PROJECT_FILE"

# 找到 FamilyMember.swift 的 fileRef 行号
LINE_NUM=$(grep -n "FamilyMember.swift.*=.*{isa = PBXFileReference" "$PROJECT_FILE" | head -1 | cut -d: -f1)

# 在之前插入
sed -i.bak2 "${LINE_NUM}i\\
		${UUID2} /* AccountValidator.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AccountValidator.swift; sourceTree = \"<group>\"; };\\
" "$PROJECT_FILE"

echo "✅ AccountValidator.swift 已添加到项目"

# 清理备份
rm -f "$PROJECT_FILE.bak" "$PROJECT_FILE.bak2"
