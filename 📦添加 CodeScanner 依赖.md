# 📦 添加 CodeScanner 依赖

**必需**: BindFamilyView.swift 和 FamilyGuardView.swift 需要 CodeScanner 来扫描二维码

---

## ✅ 方法 1：在 Xcode 中添加（推荐）

1. **打开 Xcode 项目**
   ```bash
   open /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
   ```

2. **添加 Swift Package**
   - 点击菜单栏：**File → Add Package Dependencies...**
   
3. **输入仓库地址**
   ```
   https://github.com/CameraKit/CodeScanner.git
   ```
   
4. **选择版本**
   - 选择 **Up to Next Major Version**
   - 版本：**2.0.0**
   
5. **添加到目标**
   - 确保勾选 **终活**
   
6. **点击 "Add Package"**

7. **等待下载完成**

---

## ✅ 方法 2：手动编辑 project.pbxproj

如果 Xcode 无法添加，可以手动编辑：

1. **打开项目文件**
   ```bash
   cd /Users/lishimin/Documents/zhonghuo-app
   code 终活.xcodeproj/project.pbxproj
   ```

2. **添加 Package 引用**
   
   在文件末尾找到 `/* End PBXProject section */`，在它之前添加：
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
   ```

3. **添加 Package 产品**
   
   找到 `products = (`，添加：
   ```objc
   ABCDEF1234567890 /* CodeScanner */,
   ```

4. **保存并重新打开 Xcode**

---

## 🔍 验证是否成功

在 Xcode 中查看：
- 左侧项目导航 → **Package Dependencies**
- 应该能看到 **CodeScanner**

或者编译项目：
```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

如果没有 `missing module 'CodeScanner'` 错误，说明成功。

---

## 📋 CodeScanner 信息

- **仓库**: https://github.com/CameraKit/CodeScanner.git
- **版本**: 2.0.0+
- **用途**: 扫描二维码
- **功能**: 
  - 邀请码扫码绑定
  - 二维码识别

---

## ⚠️ 常见问题

### Q1: 下载失败？
**A**: 检查网络连接，或者使用代理：
```bash
# 设置代理（如果需要）
export https_proxy=http://127.0.0.1:7890
```

### Q2: 版本冲突？
**A**: 尝试其他版本：
```
https://github.com/CameraKit/CodeScanner.git
版本：3.0.0
```

### Q3: 编译时仍然报错？
**A**: 
1. 清理 DerivedData
2. 重新添加 Package
3. 重启 Xcode

---

*更新时间：2026-03-20 17:45*
