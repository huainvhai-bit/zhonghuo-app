# 🔄 CodeScanner 依赖问题 - 彻底解决

**错误**: `Unable to find module dependency: 'CodeScanner'`

**原因**: Package 缓存或 Xcode 项目状态问题

---

## ✅ 解决方案（按顺序执行）

### 步骤 1：关闭 Xcode
```bash
killall Xcode
```

### 步骤 2：清理所有缓存
```bash
cd /Users/lishimin/Documents/zhonghuo-app

# 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*

# 清理 Package 缓存
rm -rf ~/Library/Developer/Xcode/Package.resolved
rm -rf ~/Library/Caches/org.swift.swiftpm/repositories

# 清理项目 Package 配置
rm -rf 终活.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

### 步骤 3：重新打开 Xcode
```bash
open 终活.xcodeproj
```

### 步骤 4：重新添加 Package

**在 Xcode 中操作**:

1. **移除旧的 Package（如果有）**
   - 左侧项目导航 → **Package Dependencies**
   - 如果有 **CodeScanner**，右键 → **Remove Package**

2. **重新添加 Package**
   - 菜单：**File → Add Package Dependencies...**
   - 输入：`https://github.com/twostraws/CodeScanner.git`
   - 版本：**Up to Next Major Version**
   - 最低版本：**2.0.0**
   - 确保勾选 **终活**
   - 点击 **"Add Package"**

3. **等待下载完成**
   - 查看左下角进度条
   - 确保 **CodeScanner** 显示为蓝色（不是红色）

### 步骤 5：清理并重新编译

**在 Xcode 中**:
1. 菜单：**Product → Clean Build Folder** (Shift+Command+K)
2. 菜单：**Product → Build** (Command+B)

**或使用命令行**:
```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## 🔍 验证 Package 是否成功

### 检查 1：Package Dependencies
- 左侧项目导航 → **Package Dependencies**
- 应该看到 **CodeScanner**（蓝色）
- 展开可以看到源文件

### 检查 2：project.pbxproj
```bash
grep "CodeScanner" /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj/project.pbxproj
```

应该看到：
- `XCRemoteSwiftPackageReference "CodeScanner"`
- `XCSwiftPackageProductDependency`
- `CodeScanner in Frameworks`

### 检查 3：编译
```bash
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep "BUILD"
```

应该显示：
```
** BUILD SUCCEEDED **
```

---

## ⚠️ 仍然失败？

### 方案 A：手动编辑 project.pbxproj

1. **关闭 Xcode**
   ```bash
   killall Xcode
   ```

2. **编辑项目文件**
   ```bash
   cd /Users/lishimin/Documents/zhonghuo-app
   code 终活.xcodeproj/project.pbxproj
   ```

3. **检查以下部分是否存在**:

   **Package 引用**（在 `/* Begin XCRemoteSwiftPackageReference section */`）:
   ```objc
   33DE7DE82F6D51BF00F8677E /* XCRemoteSwiftPackageReference "CodeScanner" */ = {
      isa = XCRemoteSwiftPackageReference;
      repositoryURL = "https://github.com/twostraws/CodeScanner.git";
      requirement = {
         kind = upToNextMajorVersion;
         minimumVersion = 2.0.0;
      };
   };
   ```

   **Package 产品**（在 `/* Begin XCSwiftPackageProductDependency section */`）:
   ```objc
   33DE7DE92F6D51BF00F8677E /* CodeScanner */ = {
      isa = XCSwiftPackageProductDependency;
      package = 33DE7DE82F6D51BF00F8677E /* XCRemoteSwiftPackageReference "CodeScanner" */;
      productName = CodeScanner;
   };
   ```

   **Build File**（在 `/* Begin PBXBuildFile section */`）:
   ```objc
   33DE7DEA2F6D51BF00F8677E /* CodeScanner in Frameworks */ = {
      isa = PBXBuildFile;
      productRef = 33DE7DE92F6D51BF00F8677E /* CodeScanner */;
   };
   ```

4. **保存并重新打开 Xcode**

### 方案 B：使用 Xcode 菜单重置

1. 在 Xcode 中
2. 菜单：**File → Packages → Reset Package Caches**
3. 菜单：**File → Packages → Update to Latest Package Versions**
4. 重新编译

### 方案 C：重建项目（最后手段）

如果以上都不行，创建新的 Xcode 项目并迁移代码。

---

## 📝 常见原因

1. **Package 下载中断** - 网络问题导致下载不完整
2. **Xcode 缓存损坏** - DerivedData 或 Package 缓存问题
3. **项目文件不同步** - project.pbxproj 和实际 Package 状态不一致
4. **Xcode 版本问题** - 需要更新 Xcode

---

*更新时间：2026-03-20 18:25*
