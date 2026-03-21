# 🔧 API 对接修复方案

**排查时间**: 2026-03-22 00:12  
**问题等级**: 🔴 高优先级  
**影响范围**: 所有前后端数据同步功能

---

## 🚨 问题诊断

### 核心问题

**前端使用统一的 `/api.php?action=xxx` 模式**，但**后端使用独立的 API 文件路径**。

### 具体表现

```swift
// ❌ 前端当前写法（错误）
POST http://8.136.41.211:3395/api.php?action=capsule_list
POST http://8.136.41.211:3395/api.php?action=will_list

// ✅ 后端期望路径（正确）
POST http://8.136.41.211:3395/api/capsules.php?action=list
POST http://8.136.41.211:3395/api/will.php?action=list
```

---

## 📊 问题 API 清单

### 需要修复的 API 调用（共 18 处）

| 序号 | 文件 | 行号 | 错误写法 | 正确写法 |
|------|------|------|---------|---------|
| 1 | DataManager.swift | 102 | `api.php?action=config_get` | `api/config.php?action=config_get` |
| 2 | DataManager.swift | 477 | `api.php?action=send_reset_code` | **API 缺失** |
| 3 | DataManager.swift | 508 | `api.php?action=reset_password` | **API 缺失** |
| 4 | DataManager.swift | 544 | `api.php?action=send_sms` | `api/sms.php?action=send_sms` |
| 5 | DataManager.swift | 579 | `api/notification_config.php?action=get` | ✅ 正确 |
| 6 | DataManager.swift | 712 | `api.php?action=will_update_asset` | `api/will.php?action=update_asset` |
| 7 | DataManager.swift | 850 | `api.php?action=checkin_sync` | **API 缺失** |
| 8 | DataManager.swift | 875 | `api.php?action=will_batch_sync` | `api/will.php?action=batch_sync` |
| 9 | DataManager.swift | 954 | `api.php?action=capsule_batch_sync` | `api/capsules.php?action=batch_sync` |
| 10 | DataManager.swift | 1114 | `api.php?action=will_batch_sync` | `api/will.php?action=batch_sync` |
| 11 | DataManager.swift | 1245 | `api.php?action=emergency_batch_sync` | `api/emergency_contacts.php?action=batch_sync` |
| 12 | DataManager.swift | 1338 | `api.php?action=capsule_list&token=...` | `api/capsules.php?action=list&token=...` |
| 13 | DataManager.swift | 1415 | `api.php?action=will_list&token=...` | `api/will.php?action=list&token=...` |
| 14 | DataManager.swift | 1481 | `api.php?action=emergency_list&token=...` | `api/emergency_contacts.php?action=list&token=...` |
| 15 | DataManager.swift | 1547 | `api.php?action=will_list_witnesses&token=...` | `api/will.php?action=list_witnesses&token=...` |
| 16 | DataManager.swift | 1636 | `api.php?action=will_sync_witnesses` | `api/will.php?action=sync_witnesses` |
| 17 | DataManager.swift | 1752 | `api.php?action=upload_file` | `api/upload.php?action=upload` |
| 18 | DataManager.swift | 1827 | `api.php?action=config_get` | `api/config.php?action=config_get` |
| 19 | AuthView.swift | 347, 355 | `api.php?action=xxx` | `api/users.php?action=xxx` |

---

## 🔧 修复方案

### 方案选择：**修改前端**（推荐）

**理由**:
1. ✅ 后端 API 文件结构清晰，符合 RESTful 规范
2. ✅ 前端修改集中，只需修改 DataManager.swift
3. ✅ 未来扩展性好，新增 API 只需添加新文件

---

## 📝 修复步骤

### Step 1: 创建 API 路由映射工具

在 `DataManager.swift` 中添加：

```swift
extension DataManager {
    /// 构建 API URL（统一入口）
    static func apiURL(action: String, endpoint: String? = nil) -> URL? {
        // endpoint 是 API 文件名（不含 .php）
        let file = endpoint ?? "users" // 默认 users.php
        let path = "\(DataManager.apiURL)/api/\(file).php?action=\(action)"
        return URL(string: path)
    }
}
```

### Step 2: 批量替换 API 调用

#### 用户认证相关（AuthView.swift）
```swift
// 修改前
let urlString = "\(DataManager.apiURL)/api.php?action=\(action)"

// 修改后
let urlString = "\(DataManager.apiURL)/api/users.php?action=\(action)"
```

#### 时光胶囊相关（DataManager.swift）
```swift
// 修改前
var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api.php?action=capsule_list&token=\(token)")!)

// 修改后
var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/capsules.php?action=list&token=\(token)")!)
```

#### 遗嘱与资产相关（DataManager.swift）
```swift
// 修改前
var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api.php?action=will_list&token=\(token)")!)

// 修改后
var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/will.php?action=list&token=\(token)")!)
```

---

## ⚠️ 缺失 API 处理

### 需要新增的后端 API

1. **`api/users.php`** - 添加 `send_reset_code` action
2. **`api/users.php`** - 添加 `reset_password` action  
3. **`api/checkin.php`** - 添加 `checkin_sync` action

### 临时方案

在缺失 API 实现前，前端暂时注释或跳过这些调用：

```swift
// TODO: 后端 API 实现后再启用
// func sendResetCode() async throws { ... }
// func resetPassword() async throws { ... }
// func checkinSync() async throws { ... }
```

---

## 🧪 测试计划

### 阶段 1: 编译测试
```bash
cd /Users/lishimin/Documents/zhonghuo-app
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### 阶段 2: API 连通性测试
```bash
# 测试每个修复后的 API
curl -X POST http://8.136.41.211:3395/api/capsules.php?action=list \
  -H "Content-Type: application/json" \
  -d '{"token":"xxx"}'
```

### 阶段 3: 功能测试
- [ ] 登录注册
- [ ] 时光胶囊 CRUD
- [ ] 遗嘱与资产 CRUD
- [ ] 家人守护 CRUD
- [ ] 签到功能
- [ ] 数据同步

---

## 📋 修复清单

### P0 - 核心功能（立即修复）
- [ ] 用户认证 API（AuthView.swift）
- [ ] 时光胶囊 API（capsules.php）
- [ ] 遗嘱与资产 API（will.php）
- [ ] 家人守护 API（family.php）

### P1 - 重要功能（尽快修复）
- [ ] 签到 API（checkin.php）
- [ ] 短信 API（sms.php）
- [ ] 配置 API（config.php）

### P2 - 次要功能（可延后）
- [ ] 位置服务 API（location.php）
- [ ] 通知配置 API（notification_config.php）
- [ ] 设备信息 API（device_info.php）
- [ ] 紧急联系人 API（emergency_contacts.php）
- [ ] 用户设置 API（settings.php）

### P3 - 缺失 API（需要新增）
- [ ] send_reset_code
- [ ] reset_password
- [ ] checkin_sync

---

## 🎯 预计工作量

| 任务 | 预计时间 |
|------|---------|
| 修改前端 API 调用 | 30 分钟 |
| 新增缺失 API | 1 小时 |
| 测试验证 | 1 小时 |
| 推送更新 | 15 分钟 |
| **总计** | **约 3 小时** |

---

## 🚀 下一步

**请确认**:
1. ✅ 是否采用此修复方案？
2. ✅ 是否立即开始修复？
3. ✅ 优先修复 P0 核心功能还是全部一起修复？

确认后我将开始执行修复。
