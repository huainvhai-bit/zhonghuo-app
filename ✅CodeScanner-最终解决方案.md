# ✅ CodeScanner 依赖 - 最终解决方案

**问题根源**: 手动编辑 project.pbxproj 导致项目文件损坏

**正确方法**: 让 Xcode 自动管理 Package 依赖

---

## 🎯 步骤（在 Xcode 中操作）

### 1️⃣ 打开 Xcode 项目
```bash
open /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
```

### 2️⃣ 移除旧的 Package（如果有）
1. 左侧项目导航 → **Package Dependencies**
2. 如果有 **CodeScanner**，右键 → **Remove Package**
3. 确认移除

### 3️⃣ 重新添加 Package
1. 菜单：**File → Add Package Dependencies...**
2. 输入：`https://github.com/twostraws/CodeScanner.git`
3. 版本设置：
   - **Dependency Rule**: Up to Next Major Version
   - **Minimum Version**: 2.0.0
4. **重要**: 确保勾选 **终活**（Add to target）
5. 点击 **"Add Package"**
6. 等待下载完成（左下角进度条）

### 4️⃣ 验证添加成功
1. 左侧项目导航 → **Package Dependencies**
2. 展开 **CodeScanner**
3. 应该能看到源文件（蓝色图标）

### 5️⃣ 清理并编译
1. 菜单：**Product → Clean Build Folder** (Shift+Command+K)
2. 菜单：**Product → Build** (Command+B)

---

## ✅ 成功标志

```
** BUILD SUCCEEDED **
```

---

## ⚠️ 重要提示

**不要手动编辑 project.pbxproj！**

让 Xcode 自动管理：
- Package 依赖
- Framework 链接
- Build phases

手动编辑很容易破坏项目文件结构。

---

*更新时间：2026-03-20 18:35*
