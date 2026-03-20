#!/usr/bin/env python3
import re
import uuid

project_file = '终活.xcodeproj/project.pbxproj'

with open(project_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. 添加 FileReference
file_ref_uuid = uuid.uuid4().hex.upper()
print(f"FileRef UUID: {file_ref_uuid}")

# 找到 FamilyMember.swift 的 FileRef 行
for i, line in enumerate(lines):
    if 'FamilyMember.swift' in line and 'PBXFileReference' in line:
        # 在它之前插入 AccountValidator.swift
        new_line = f'\t\t{file_ref_uuid} /* AccountValidator.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AccountValidator.swift; sourceTree = "<group>"; }};\n'
        lines.insert(i, new_line)
        print(f"✅ 添加 FileRef 在行 {i}")
        break

# 2. 添加到 PBXBuildFile (Sources)
build_uuid = uuid.uuid4().hex.upper()
print(f"Build UUID: {build_uuid}")

# 找到第一个 .swift in Sources 行
for i, line in enumerate(lines):
    if '.swift in Sources' in line and 'PBXBuildFile' in line:
        new_line = f'\t\t{build_uuid} /* AccountValidator.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* AccountValidator.swift */; }};\n'
        lines.insert(i, new_line)
        print(f"✅ 添加 BuildFile 在行 {i}")
        break

# 保存
with open(project_file, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 项目文件已更新")
