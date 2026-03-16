#!/usr/bin/env python3
import re

with open('终活.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    content = f.read()

# 生成新 UUID
import uuid
new_file_ref = "A2%06X" % uuid.uuid4().int & 0xFFFFFF
new_build_ref = "A1%06X" % uuid.uuid4().int & 0xFFFFFF

# 找到最后一个 PBXBuildFile
last_build_file = content.rfind('};')
if last_build_file > 0:
    insert_pos = content.find('\n', last_build_file) + 1
    build_entry = f'\t\t{new_build_ref} /* EmergencyContactsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {new_file_ref} /* EmergencyContactsView.swift */; }};\n'
    content = content[:insert_pos] + build_entry + content[insert_pos:]

# 找到 FileRef 部分
last_file_ref = content.rfind('fileRef = A2')
if last_file_ref > 0:
    end_line = content.find('};', last_file_ref) + 2
    end_line = content.find('\n', end_line) + 1
    file_entry = f'\t\t{new_file_ref} /* EmergencyContactsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EmergencyContactsView.swift; sourceTree = "<group>"; }};\n'
    content = content[:end_line] + file_entry + content[end_line:]

# 找到 Sources 编译部分
sources_section = content.find('files = (')
if sources_section > 0:
    end_files = content.find(');', sources_section)
    sources_entry = f'\n\t\t\t\t{new_build_ref} /* EmergencyContactsView.swift in Sources */,'
    content = content[:end_files] + sources_entry + content[end_files:]

with open('终活.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✅ EmergencyContactsView 已添加 ({new_file_ref}, {new_build_ref})")
