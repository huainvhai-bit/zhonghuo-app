# 📡 终活 App API 对接映射表

**更新时间**: 2026-03-22 00:10  
**状态**: 🔴 需要修复

---

## 🚨 核心问题

### 问题 1: API 路由不匹配

**前端期望**:
```swift
POST http://8.136.41.211:3395/api.php?action=login
POST http://8.136.41.211:3395/api.php?action=capsule_list
```

**后端实际**:
```php
/api/users.php        // 处理 login, register
/api/capsules.php     // 处理 capsule_list, capsule_create
/api/will.php         // 处理 will_*, asset_*
```

---

## 📊 完整 API 映射

### 用户认证模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 登录 | `login` | `api/users.php` | `login` | ✅ 匹配 |
| 注册 | `register` | `api/users.php` | `register` | ✅ 匹配 |
| 获取用户信息 | `get_userinfo` | `api/users.php` | `get_userinfo` | ✅ 匹配 |
| 验证账号 | `validate` | `api/users.php` | `validate` | ✅ 匹配 |
| 发送重置码 | `send_reset_code` | `api/users.php` | ❌ 不存在 | 🔴 缺失 |
| 重置密码 | `reset_password` | `api/users.php` | ❌ 不存在 | 🔴 缺失 |

### 时光胶囊模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 列表 | `capsule_list` | `api/capsules.php` | `list` | ⚠️ 不匹配 |
| 创建 | `capsule_create` | `api/capsules.php` | `create` | ⚠️ 不匹配 |
| 更新 | `capsule_update` | `api/capsules.php` | `update` | ⚠️ 不匹配 |
| 删除 | `capsule_delete` | `api/capsules.php` | `delete` | ⚠️ 不匹配 |

### 遗嘱与资产模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 遗嘱列表 | `will_list` | `api/will.php` | `will_list` | ✅ 匹配 |
| 遗嘱创建 | `will_create` | `api/will.php` | `will_create` | ✅ 匹配 |
| 遗嘱更新 | `will_update` | `api/will.php` | `will_update` | ✅ 匹配 |
| 遗嘱删除 | `will_delete` | `api/will.php` | `will_delete` | ✅ 匹配 |
| 资产列表 | `asset_list` | `api/will.php` | `asset_list` | ✅ 匹配 |
| 资产创建 | `asset_create` | `api/will.php` | `asset_create` | ✅ 匹配 |
| 资产更新 | `asset_update` | `api/will.php` | `asset_update` | ✅ 匹配 |
| 资产删除 | `asset_delete` | `api/will.php` | `asset_delete` | ✅ 匹配 |

### 家人守护模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 列表 | `family_list` | `api/family.php` | `list` | ⚠️ 不匹配 |
| 创建 | `family_create` | `api/family.php` | `create` | ⚠️ 不匹配 |
| 更新 | `family_update` | `api/family.php` | `update` | ⚠️ 不匹配 |
| 删除 | `family_delete` | `api/family.php` | `delete` | ⚠️ 不匹配 |
| 批量同步 | `family_batch_sync` | `api/family.php` | `batch_sync` | ⚠️ 不匹配 |

### 签到模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 签到 | `checkin` | `api/checkin.php` | `checkin` | ✅ 匹配 |
| 签到历史 | `checkin_history` | `api/checkin.php` | `history` | ⚠️ 不匹配 |
| 签到同步 | `checkin_sync` | `api/checkin.php` | ❌ 不存在 | 🔴 缺失 |

### 短信模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 发送验证码 | `send_sms_code` | `api/sms.php` | `send_sms_code` | ✅ 匹配 |
| 验证验证码 | `verify_sms_code` | `api/sms.php` | `verify_sms_code` | ✅ 匹配 |
| 发送短信 | `send_sms` | `api/sms.php` | `send_sms` | ✅ 匹配 |

### 配置模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 获取配置 | `config_get` | `api/config.php` | `config_get` | ✅ 匹配 |

### 位置服务模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 更新位置 | `location_update` | `api/location.php` | `update` | ⚠️ 不匹配 |
| 获取位置 | `location_get` | `api/location.php` | `get` | ⚠️ 不匹配 |

### 设备信息模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 上传设备信息 | `device_info_upload` | `api/device_info.php` | `upload` | ⚠️ 不匹配 |
| 获取设备信息 | `device_info_get` | `api/device_info.php` | `get` | ⚠️ 不匹配 |

### 通知配置模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 获取通知配置 | `notification_config_get` | `api/notification_config.php` | `get` | ⚠️ 不匹配 |
| 更新通知配置 | `notification_config_update` | `api/notification_config.php` | `update` | ⚠️ 不匹配 |

### 紧急联系人模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 列表 | `emergency_contact_list` | `api/emergency_contacts.php` | `list` | ⚠️ 不匹配 |
| 创建 | `emergency_contact_create` | `api/emergency_contacts.php` | `create` | ⚠️ 不匹配 |
| 更新 | `emergency_contact_update` | `api/emergency_contacts.php` | `update` | ⚠️ 不匹配 |
| 删除 | `emergency_contact_delete` | `api/emergency_contacts.php` | `delete` | ⚠️ 不匹配 |

### 用户设置模块

| 功能 | 前端 Action | 后端文件 | 后端 Action | 状态 |
|------|------------|---------|------------|------|
| 获取设置 | `settings_get` | `api/settings.php` | `get` | ⚠️ 不匹配 |
| 更新设置 | `settings_update` | `api/settings.php` | `update` | ⚠️ 不匹配 |

---

## 🔧 修复方案

### 方案 A: 修改前端（推荐）

修改 `DataManager.swift` 中的 API 调用，使用正确的 action 名称：

```swift
// 修改前
let url = URL(string: "\(DataManager.apiURL)/api.php?action=capsule_list")!

// 修改后
let url = URL(string: "\(DataManager.apiURL)/api/capsules.php")!
// 并在 POST body 中传递 {"action": "list"}
```

### 方案 B: 修改后端

在每个 API 文件中添加 action 别名映射：

```php
// api/capsules.php
$action = $data['action'] ?? '';
// 添加别名映射
$aliases = [
    'capsule_list' => 'list',
    'capsule_create' => 'create',
    'capsule_update' => 'update',
    'capsule_delete' => 'delete',
];
$action = $aliases[$action] ?? $action;
```

---

## 📋 修复优先级

### P0 - 立即修复（影响核心功能）
1. ✅ 用户认证 - 已正常
2. ⚠️ 时光胶囊 - action 不匹配
3. ⚠️ 遗嘱与资产 - 部分正常
4. ⚠️ 家人守护 - action 不匹配

### P1 - 尽快修复（影响用户体验）
5. ⚠️ 位置服务 - action 不匹配
6. ⚠️ 通知配置 - action 不匹配
7. ⚠️ 设备信息 - action 不匹配

### P2 - 可延后修复（边缘功能）
8. 🔴 重置密码 - API 缺失
9. ⚠️ 紧急联系人 - action 不匹配
10. ⚠️ 用户设置 - action 不匹配

---

## 🎯 下一步行动

1. **确认修复方案** - 选择修改前端还是后端
2. **批量修复 action 映射** - 按优先级修复
3. **测试验证** - 每个模块逐一测试
4. **推送更新** - 前后端同步推送

---

*等待用户确认修复方案...*
