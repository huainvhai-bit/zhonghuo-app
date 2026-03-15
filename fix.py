with open('终活.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    content = f.read()

# 添加 BuildFile（在 NotificationManager 后）
old_build = '\t\tA1000034 /* NotificationManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000034 /* NotificationManager.swift */; };'
new_build = old_build + '\n\t\tA1000035 /* WillPreviewView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000035 /* WillPreviewView.swift */; };\n\t\tA1000036 /* HelpPolicyView.swift in Sources */ = {isa = PBXBuildFile; fileRef = A2000036 /* HelpPolicyView.swift */; };'
content = content.replace(old_build, new_build)

# 添加 Sources（在 NotificationManager 后）
old_sources = '\t\t\t\tA1000034 /* NotificationManager.swift in Sources */,'
new_sources = old_sources + '\n\t\t\t\tA1000035 /* WillPreviewView.swift in Sources */,\n\t\t\t\tA1000036 /* HelpPolicyView.swift in Sources */,'
content = content.replace(old_sources, new_sources)

with open('终活.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 项目文件已修复")
