# Xcode 项目文件更新指南

## 问题
项目文件 (`终活.xcodeproj/project.pbxproj`) 仍然引用根目录的 Swift 文件，但这些文件已被重构到模块目录中。

## 需要移动的文件

| 旧路径 | 新路径 |
|--------|--------|
| AuthView.swift | Auth/LoginView.swift |
| FamilyGuardView.swift | Family/FamilyGuardView.swift |
| SettingsView.swift | Settings/SettingsView.swift |
| TimeCapsuleView.swift | Capsule/CapsuleEditView.swift |
| HomeStatusView.swift | Home/HomeStatusView.swift |

## 解决方案

### 手动修复（推荐）
1. 在 Xcode 中打开 `终活.xcodeproj`
2. 右键点击项目导航器中的项目图标
3. 选择 "Add Files to '终活'"
4. 添加以下模块目录（确保勾选 "Create folder references"）：
   - `Auth/`
   - `Capsule/`
   - `Family/`
   - `Home/`
   - `Settings/`
   - `Location/`
   - `Models/`
   - `Services/`
   - `User/`
5. 删除根目录中不存在的文件引用（如果 Still there）

### 自动修复（需要 Xcode CLI）
```bash
# 使用 xcodeproj gem
gem install xcodeproj
ruby update-project.rb
```

## 编译status
2026-04-08: 编译失败，需要手动更新项目文件
