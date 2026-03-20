# 📦 CodeScanner 正确仓库地址

**问题**: `https://github.com/CameraKit/CodeScanner.git` 不存在

**正确的仓库地址**:

## ✅ 方案 1：使用 twostraws/CodeScanner（推荐）

这是原作者 Simon Ng 的官方版本：

```
https://github.com/twostraws/CodeScanner.git
```

**版本**: 2.0.0 或更高

---

## ✅ 方案 2：使用 CameraKit/CodeScanner（组织版本）

如果组织版本存在：

```
https://github.com/CameraKit/CodeScanner.git
```

---

## 🚀 在 Xcode 中添加

### 步骤：

1. **打开 Xcode 项目**
   ```bash
   open /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
   ```

2. **添加 Package**
   - 菜单：**File → Add Package Dependencies...**
   
3. **输入正确的仓库地址**
   ```
   https://github.com/twostraws/CodeScanner.git
   ```
   
4. **版本设置**
   - **Dependency Rule**: Up to Next Major Version
   - **Minimum Version**: 2.0.0
   
5. **确保勾选**
   - ✅ **终活**（Add to target）
   
6. **点击 "Add Package"**

7. **等待下载完成**

---

## 🔍 验证

在 Xcode 中：
- 左侧项目导航 → **Package Dependencies**
- 应该看到 **CodeScanner**（蓝色）
- 展开可以看到源文件

---

## ⚠️ 如果仍然失败

### 检查网络
```bash
ping github.com
```

### 使用代理
```bash
export https_proxy=http://127.0.0.1:7890
```

### 清理 Package 缓存
```bash
rm -rf ~/Library/Developer/Xcode/Package.resolved
rm -rf ~/Library/Caches/org.swift.swiftpm/repositories
```

### 重新打开 Xcode
```bash
killall Xcode
open /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
```

---

*更新时间：2026-03-20 18:20*
