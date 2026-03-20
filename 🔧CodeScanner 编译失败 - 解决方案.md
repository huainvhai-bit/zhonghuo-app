# 🔧 CodeScanner 编译失败 - 临时解决方案

**错误**: `Unable to find module dependency: 'CodeScanner'`

**原因**: CodeScanner 包未正确添加到项目

---

## ✅ 方案 1：在 Xcode 中重新添加 Package（推荐）

### 步骤：

1. **打开 Xcode 项目**
   ```bash
   open /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
   ```

2. **查看 Package Dependencies**
   - 在左侧项目导航中，找到 **Package Dependencies**
   - 如果看到 **CodeScanner**（红色），右键 → **Delete Package**

3. **重新添加 Package**
   - 菜单：**File → Add Package Dependencies...**
   - 输入：`https://github.com/CameraKit/CodeScanner.git`
   - 版本：**Up to Next Major Version**
   - 最低版本：**2.0.0**
   - 确保勾选 **终活**
   - 点击 **"Add Package"**

4. **等待下载完成**
   - 查看左下角进度条
   - 确保 CodeScanner 显示为蓝色（不是红色）

5. **清理并重新编译**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
   xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   ```

---

## ✅ 方案 2：临时注释 CodeScanner（快速通过编译）

如果 Package 一直添加失败，可以暂时注释掉扫码功能：

### 修改 BindFamilyView.swift

打开文件，找到：
```swift
import CodeScanner
```

改为：
```swift
// import CodeScanner  // 暂时注释
```

找到扫码按钮部分，临时改为：
```swift
// 暂时禁用扫码功能
Text("扫码功能暂未启用")
    .foregroundColor(.gray)
```

### 修改 FamilyGuardView.swift

同样注释掉：
```swift
// import CodeScanner  // 暂时注释
```

### 重新编译

```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

---

## ✅ 方案 3：手动编辑 project.pbxproj（高级）

### 步骤：

1. **关闭 Xcode**
   ```bash
   killall Xcode
   ```

2. **编辑项目文件**
   ```bash
   cd /Users/lishimin/Documents/zhonghuo-app
   code 终活.xcodeproj/project.pbxproj
   ```

3. **添加 Package 引用**
   
   在文件末尾 `/* End PBXProject section */` 之前添加：
   ```objc
   /* Begin XCRemoteSwiftPackageReference section */
   1234567890ABCDEF /* CodeScanner */ = {
      isa = XCRemoteSwiftPackageReference;
      repositoryURL = "https://github.com/CameraKit/CodeScanner.git";
      requirement = {
         kind = upToNextMajorVersion;
         minimumVersion = 2.0.0;
      };
   };
   /* End XCRemoteSwiftPackageReference section */
   
   /* Begin XCSwiftPackageProductDependency section */
   ABCDEF1234567890 /* CodeScanner */ = {
      isa = XCSwiftPackageProductDependency;
      package = 1234567890ABCDEF /* CodeScanner */;
      productName = CodeScanner;
   };
   /* End XCSwiftPackageProductDependency section */
   ```

4. **添加到 target 依赖**
   
   找到 `target = 终活` 的部分，在 `dependencies` 中添加：
   ```objc
   ABCDEF1234567890 /* CodeScanner */,
   ```

5. **保存并重新打开 Xcode**

6. **清理并编译**

---

## 🔍 验证 Package 是否成功

在 Xcode 中：
- 左侧项目导航 → **Package Dependencies**
- 应该能看到 **CodeScanner**（蓝色，不是红色）
- 展开可以看到 CodeScanner 的源码文件

---

## ⚠️ 常见问题

### Q1: Package 一直显示红色？
**A**: 
1. 检查网络连接
2. 使用代理：
   ```bash
   export https_proxy=http://127.0.0.1:7890
   ```
3. 删除 Package 重新添加

### Q2: 下载超时？
**A**: 
```bash
# 清理 Package 缓存
rm -rf ~/Library/Developer/Xcode/Package.resolved
# 重新打开 Xcode
```

### Q3: 仍然失败？
**A**: 使用方案 2，先注释掉，让编译通过，稍后再处理扫码功能。

---

*更新时间：2026-03-20 18:00*
