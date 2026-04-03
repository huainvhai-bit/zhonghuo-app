# 终活 App 线程安全修复总结

## 修复日期
2026-02-27

## 修复的问题

### 1. DataManager.swift - `downloadAllData()` 方法

**问题：** 在后台 Task 中直接修改 `@Published` 属性（`capsules`、`willModules`），没有使用 `MainActor.run` 包裹。

**修复：** 将整个方法标记为 `@MainActor`，确保所有 `@Published` 属性更新在主线程执行。

```swift
// 修复前
func downloadAllData() async {
    // ...
    await MainActor.run {
        capsules = ...  // 嵌套在 Task 中
    }
}

// 修复后
@MainActor
func downloadAllData() async {
    // ... 所有 @Published 更新自动在主线程执行
    capsules = ...
    willModules = ...
}
```

### 2. DataManager.swift - `batchSyncCapsules()` 方法

**问题：** 方法开始时直接修改 `capsules` 数组（@Published 属性），没有使用 MainActor 包裹。

**修复：** 将整个方法标记为 `@MainActor`，移除了不必要的 `Task { @MainActor in }` 嵌套。

```swift
// 修复前
func batchSyncCapsules() async -> ... {
    // ❌ 直接修改 @Published
    capsules[i].cloudBackupStatus = .uploading
    
    // ... 异步操作 ...
    
    Task { @MainActor in  // 不必要的嵌套
        capsules[i].cloudBackupStatus = .backedUp
    }
}

// 修复后
@MainActor
func batchSyncCapsules() async -> ... {
    // ✅ 安全：在 @MainActor 中执行
    capsules[i].cloudBackupStatus = .uploading
    
    // ... 异步操作 ...
    
    // ✅ 已在 @MainActor 中，无需额外 Task
    capsules[i].cloudBackupStatus = .backedUp
}
```

### 3. HomeStatusView.swift - `updateStatus()` 方法

**问题：** 方法直接修改 `@State` 变量，但没有明确标记为 `@MainActor`。

**修复：** 将方法标记为 `@MainActor`，确保所有状态更新在主线程执行。

```swift
// 修复前
private func updateStatus() {
    isSafe = status.isSafe
    secondsRemaining = status.hoursRemaining * 3600
}

// 修复后
@MainActor
private func updateStatus() {
    isSafe = status.isSafe
    secondsRemaining = status.hoursRemaining * 3600
}
```

### 4. HomeStatusView.swift - `handleAutoCheckIn()` 方法

**问题：** 方法修改 `@State` 变量（通过 dataManager），但没有明确标记为 `@MainActor`。

**修复：** 将方法标记为 `@MainActor`。

```swift
// 修复前
private func handleAutoCheckIn() {
    dataManager.lastCheckInDate = userManager.lastCheckInDate
}

// 修复后
@MainActor
private func handleAutoCheckIn() {
    dataManager.lastCheckInDate = userManager.lastCheckInDate
}
```

### 5. HomeStatusView.swift - Timer 回调

**问题：** Timer 回调中调用 `updateStatus()` 时没有确保在主线程。

**修复：** 在 Timer 回调中使用 `Task { @MainActor in }` 包裹 `updateStatus()` 调用。

```swift
// 修复前
.onReceive(timer) { _ in
    if secondsRemaining <= 0 {
        updateStatus()  // 可能在后台线程调用
    }
}

// 修复后
.onReceive(timer) { _ in
    if secondsRemaining <= 0 {
        Task { @MainActor in
            updateStatus()  // 确保在主线程调用
        }
    }
}
```

## 已验证安全的代码

以下代码在审查中确认为安全，无需修改：

1. **UserManager.swift - `fetchUserData()`**: 已正确使用 `await MainActor.run { }` 包裹 GraphQL 回调中的 `@Published` 更新。

2. **UserManager.swift - `syncCheckInToServer()`**: 已标记为 `@MainActor`。

3. **UserManager.swift - `uploadLocation()`**: 已标记为 `@MainActor`。

4. **UserManager.swift - `updateCapsulesCount()` 等方法**: 已使用 `DispatchQueue.main.async` 包裹。

5. **DataManager.swift - `fetchServerConfig()`**: 已正确使用 `await MainActor.run { }`。

6. **DataManager.swift - `batchSyncWills()`**: 不直接修改 `@Published` 属性，仅读取数据发送到服务器，安全。

7. **DataManager.swift - `batchSyncEmergencyContacts()`**: 从 UserManager 读取数据，不直接修改 `@Published`，安全。

## 倒计时跳动问题

**原因分析：**
- Timer 已正确配置为在主线程运行：`Timer.publish(every: 1, on: .main, in: .common)`
- 但 `updateStatus()` 方法可能在某些调用路径中不在主线程执行

**修复方案：**
1. 将 `updateStatus()` 标记为 `@MainActor`
2. 将 `handleAutoCheckIn()` 标记为 `@MainActor`
3. 在 Timer 回调中使用 `Task { @MainActor in }` 确保调用在主线程

## 构建验证

修复完成后，请运行以下命令进行构建验证：

```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme zhonghuo -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 技术要点

### @MainActor vs DispatchQueue.main.async

- **@MainActor**: Swift 5.5+ 的并发特性，编译器级别保证代码在主线程执行
- **DispatchQueue.main.async**: 传统的 GCD 方式，运行时保证

推荐优先使用 `@MainActor`，因为它：
1. 编译器检查，更安全
2. 代码更简洁
3. 与 async/await 集成更好

### GraphQL 回调线程安全模式

```swift
// ✅ 推荐模式
func fetchData() async {
    let result = try await apiCall()
    
    await MainActor.run {
        // 所有 UI 更新在这里
        @Published 属性 = result.data
    }
}

// ✅ 或者整个方法标记为 @MainActor
@MainActor
func fetchData() async {
    let result = try await apiCall()
    // 所有 @Published 更新自动安全
    @Published 属性 = result.data
}
```

## 后续建议

1. **代码审查**: 定期检查新代码中的 `@Published` 属性更新是否在主线程
2. **静态分析**: 使用 Xcode 的 Thread Sanitizer 检测线程问题
3. **单元测试**: 添加并发场景下的单元测试，确保线程安全
