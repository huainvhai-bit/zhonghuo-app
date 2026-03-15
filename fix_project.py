#!/usr/bin/env python3
import re

with open('终活.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
added_build_files = False
added_sources = False

for i, line in enumerate(lines):
    new_lines.append(line)
    
    # 在 PBXBuildFile 部分添加
    if not added_build_files and 'A1000038 /* AuthView.swift in Sources */' in line:
        new_lines.append('\t\tA1000039 /* WillPreviewView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000035 /* WillPreviewView.swift */; };\n')
        new_lines.append('\t\tA1000040 /* HelpPolicyView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000036 /* HelpPolicyView.swift */; };\n')
        added_build_files = True
        print("✅ 添加 BuildFile")
    
    # 在 Sources 部分添加
    if not added_sources and 'A1000038 /* AuthView.swift in Sources */' in line and 'PBXBuildFile' not in line:
        new_lines.append('\t\t\t\tA1000039 /* WillPreviewView.swift in Sources */,\n')
        new_lines.append('\t\t\t\tA1000040 /* HelpPolicyView.swift in Sources */,\n')
        added_sources = True
        print("✅ 添加 Sources")

with open('终活.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f"✅ 项目文件已修复 ({len(new_lines)} 行)")
