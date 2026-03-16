#!/usr/bin/env python3

with open('终活.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    # 在 WitnessView 的 BuildFile 后添加
    if 'A1000030 /* WitnessView.swift in Sources */' in line and 'PBXBuildFile' in line:
        new_lines.append('\t\tA1000031 /* EmergencyContactsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000031 /* EmergencyContactsView.swift */; };\n')
    # 在 WitnessView 的 FileRef 后添加
    if 'A2000030 /* WitnessView.swift */ = {isa = PBXFileReference' in line:
        new_lines.append('\t\tA2000031 /* EmergencyContactsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EmergencyContactsView.swift; sourceTree = SOURCE_ROOT; };\n')
    # 在 WitnessView 的 Sources 编译列表后添加
    if 'A1000030 /* WitnessView.swift in Sources */' in line and 'PBXBuildFile' not in line:
        new_lines.append('\t\t\t\tA1000031 /* EmergencyContactsView.swift in Sources */,\n')

with open('终活.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"✅ EmergencyContactsView 已添加 ({len(new_lines)} 行)")
