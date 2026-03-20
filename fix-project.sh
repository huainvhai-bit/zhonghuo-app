#!/bin/bash

PROJECT_FILE="终活.xcodeproj/project.pbxproj"

# 找到第一个 .swift 文件的 Source 行
FIRST_SWIFT=$(grep "in Sources.*=.*{isa = PBXBuildFile" "$PROJECT_FILE" | head -1)

# 提取 UUID
FIRST_UUID=$(echo "$FIRST_SWIFT" | cut -d' ' -f1)

# 生成新 UUID
NEW_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-')

# 找到 FileRef 行
FILE_REF_LINE=$(grep "AccountValidator.swift.*=.*{isa = PBXFileReference" "$PROJECT_FILE")
FILE_REF_UUID=$(echo "$FILE_REF_LINE" | cut -d' ' -f1)

echo "File Ref UUID: $FILE_REF_UUID"
echo "New Build UUID: $NEW_UUID"

# 在第一个 Source 行之前添加
sed -i.bak "s/${FIRST_UUID}/${NEW_UUID} /* AccountValidator.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${FILE_REF_UUID} /* AccountValidator.swift */; };\n\t\t${FIRST_UUID}/g" "$PROJECT_FILE"

echo "✅ 已添加到 SourcesBuildPhase"
