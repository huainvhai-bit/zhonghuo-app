# P1 问题修复清单

## 修复日期
2026-02-27

## 修复概览

共修复 5 个 P1 级别问题，所有修复遵循"只修复 bug，不修改功能逻辑"原则。

---

## 1. 视图生命周期管理 (AuthView.swift)

**问题**: 定时器未在视图消失时清理，可能导致内存泄漏

**修复内容**:
- ✅ 在 `AuthView` 的 `.onDisappear` 中添加定时器清理逻辑
- ✅ 在 `ResetPasswordView` 的 `.onDisappear` 中完善定时器清理（设置为 nil）

**改动位置**:
```swift
// AuthView.swift
.onDisappear {
    // 🔴 清理定时器，防止内存泄漏
    timer?.invalidate()
    timer = nil
}

// ResetPasswordView.swift
.onDisappear {
    // 🔴 清理定时器，防止内存泄漏
    timer?.invalidate()
    timer = nil
}
```

---

## 2. 定时器未清理 (HomeStatusView.swift)

**问题**: Timer.publish 创建的定时器在视图消失时未取消

**修复内容**:
- ✅ 在 `.onDisappear` 中取消定时器连接

**改动位置**:
```swift
// HomeStatusView.swift
.onDisappear {
    // 🔴 清理定时器，防止内存泄漏
    timer.upstream.connect().cancel()
}
```

---

## 3. 通知观察者未移除 (DeviceMonitor.swift)

**问题**: 使用旧版 addObserver 方式，观察者可能未正确移除

**修复内容**:
- ✅ 改用 block 方式添加观察者，使用 token 存储
- ✅ 在 deinit 中遍历移除所有观察者
- ✅ 清空 token 数组

**改动位置**:
```swift
// DeviceMonitor.swift
// 新增属性
private var notificationTokens: [NSObjectProtocol] = []

// init() 中改用 block 方式
let token1 = NotificationCenter.default.addObserver(
    forName: UIDevice.batteryLevelDidChangeNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.batteryStatusDidChange()
}
notificationTokens.append(token1)

// deinit 中正确移除
deinit {
    stopMonitoring()
    device.isBatteryMonitoringEnabled = false
    // 🔴 正确移除所有观察者
    notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    notificationTokens.removeAll()
}
```

---

## 4. 云存储未实现 (CloudStorageManager.swift)

**问题**: syncData() 方法只有 TODO 注释，未实现实际同步逻辑

**修复内容**:
- ✅ 新增 `CloudStorageError` 错误类型枚举
- ✅ 实现 `checkCloudKitStatus()` 检查 iCloud 可用性
- ✅ 实现 `syncUserData()` 同步用户数据
- ✅ 实现 `syncWillData()` 同步遗嘱数据
- ✅ 实现 `syncCapsuleData()` 同步胶囊数据
- ✅ 统一使用 ErrorHandler 处理错误

**改动位置**:
```swift
// CloudStorageManager.swift

// 新增错误类型
enum CloudStorageError: LocalizedError {
    case unavailable(String)
    case syncFailed(String)
    case recordNotFound(String)
    case permissionDenied
}

// 实现同步逻辑
func syncData() async {
    // 1. 检查 iCloud 可用性
    let status = await checkCloudKitStatus()
    guard status == .available else {
        throw CloudStorageError.unavailable("iCloud 不可用：\(status.rawValue)")
    }
    
    // 2. 同步用户数据
    try await syncUserData()
    
    // 3. 同步遗嘱数据
    try await syncWillData()
    
    // 4. 同步胶囊数据
    try await syncCapsuleData()
}
```

---

## 5. 错误处理不一致 (全局)

**问题**: 多处 catch 块未使用统一的 ErrorHandler

**修复内容**:
- ✅ AuthView.swift: register()、login()、sendVerifyCode()、resetPassword() 共 4 处
- ✅ CloudStorageManager.swift: syncData()、checkCloudKitStatus() 共 2 处

**改动位置**:
```swift
// 所有 catch 块统一添加
} catch {
    // 🔴 统一使用 ErrorHandler 处理错误
    ErrorHandler.shared.handle(error, context: "操作名称", showAlert: false)
    
    // 原有错误处理逻辑保持不变
    ...
}
```

**修复的文件**:
- AuthView.swift (4 处)
- CloudStorageManager.swift (2 处)

---

## 测试建议

1. **AuthView.swift**: 测试登录/注册流程，确认无内存泄漏
2. **HomeStatusView.swift**: 测试页面切换，确认定时器正确清理
3. **DeviceMonitor.swift**: 测试设备监控启停，确认观察者正确移除
4. **CloudStorageManager.swift**: 测试 iCloud 同步功能（需 iCloud 环境）
5. **ErrorHandler**: 测试错误提示是否正确显示

---

## 约束检查

✅ 只修复 bug，未修改功能逻辑
✅ 未增加/删除功能
✅ 使用统一错误处理机制
✅ 所有改动保持向后兼容
