# 📝 手动操作步骤

## 1. 在 Xcode 中添加 DeviceMonitor.swift

1. 打开 `/Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj`
2. 右键点击 `终活/` 文件夹
3. 选择 "Add Files to '终活'..."
4. 选择 `DeviceMonitor.swift`
5. 确保勾选 "Copy items if needed" 和 "Add to targets: 终活"
6. 点击 "Add"

## 2. 编译测试

```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## 3. 测试功能

### 静默模式
1. 打开 App → 我的 → 设置
2. 找到"通知设置"部分
3. 打开"静默模式"开关
4. 确认开关状态保存
5. 关闭 App，重新打开，确认状态依然保存

### 设备信息
1. 打开 App → 我的 → 设置
2. 滚动到"设备信息"部分
3. 确认显示：
   - ✅ 今日步数（应该显示数字）
   - ✅ 设备电量（百分比）
   - ✅ 充电状态（未充电/充电中/已充满）
4. 等待 5 秒，确认数据刷新
5. 点击右上角刷新按钮，确认手动刷新

### 家人守护（待实现）
- 后续实现

---

*创建时间：2026-03-20 16:35*
