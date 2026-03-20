# 🔍 前后端 API 对接检查报告

## 检查时间
2026-03-21 01:40

---

## 📊 前端 API 调用统计

### 前端发送的 action 参数

| 文件 | Action | 调用方式 |
|------|--------|---------|
| AuthView.swift | `login` | POST |
| AuthView.swift | `register` | POST |
| DataManager.swift | `config_get` | GET |
| DataManager.swift | `will_update_asset` | POST |
| DataManager.swift | `checkin_sync` | POST |
| DataManager.swift | `will_batch_sync` | POST |
| DataManager.swift | `capsule_batch_sync` | POST |
| DataManager.swift | `capsule_list` | GET |
| DataManager.swift | `will_list` | GET |
| DataManager.swift | `emergency_list` | GET |
| DataManager.swift | `will_list_witnesses` | GET |
| DataManager.swift | `will_sync_witnesses` | POST |
| DataManager.swift | `emergency_batch_sync` | POST |
| DataManager.swift | `upload_file` | POST |

---

## 🎯 后端路由表

### 已配置的路由（35+ 个）

| 类别 | Action | 文件 | 函数 |
|------|--------|------|------|
| **用户认证** | user_login | api/users.php | login |
| | user_register | api/users.php | register |
| | user_info | api/users.php | getUserInfo |
| | **login** | api/users.php | login |
| | **register** | api/users.php | register |
| **家人守护** | family_get_invite_code | api/family.php | getInviteCode |
| | family_bind | api/family.php | bindFamily |
| | family_list | api/family.php | listFamily |
| | family_accept | api/family.php | acceptInvite |
| | family_remove | api/family.php | removeFamily |
| **位置服务** | location_upload | location.php | uploadLocation |
| | location_get_history | location.php | getLocationHistory |
| | location_get_latest | location.php | getLatestLocation |
| **时光胶囊** | capsule_list | api/capsules.php | listCapsules |
| | capsule_create | api/capsules.php | createCapsule |
| | capsule_update | api/capsules.php | updateCapsule |
| | capsule_delete | api/capsules.php | deleteCapsule |
| | capsule_batch_sync | api/capsules.php | batchSync |
| **遗嘱见证** | will_batch_sync | api/will.php | batchSyncWills |
| | will_list | api/will.php | listWills |
| | will_list_witnesses | api/will.php | listWitnesses |
| | will_sync_witnesses | api/will.php | syncWitnesses |
| **紧急联系人** | emergency_list | api/emergency_contacts.php | listContacts |
| | emergency_add | api/emergency_contacts.php | addContact |
| | emergency_update | api/emergency_contacts.php | updateContact |
| | emergency_delete | api/emergency_contacts.php | deleteContact |
| | emergency_batch_sync | api/emergency_contacts.php | batchSyncEmergencyContacts |
| **见证人** | witness_batch_sync | witness.php | batchSync |
| **签到** | checkin_record | api/checkin.php | recordCheckIn |
| | checkin_status | api/checkin.php | getCheckInStatus |
| | checkin_sync | api/checkin.php | syncCheckIn |
| **系统配置** | config_get | api/config.php | getConfig |
| **设备信息** | device_upload | api/device_info.php | uploadDeviceInfo |
| | device_get | api/device_info.php | getDeviceInfo |
| **文件上传** | upload_file | api/upload.php | null |
| **配置检查** | check_config | api/check-config.php | null |

---

## ✅ 对接状态检查

### 1. 用户认证 ✅ 已修复

| 前端 | 后端 | 状态 |
|------|------|------|
| `login` | `login` (别名) | ✅ 匹配 |
| `register` | `register` (别名) | ✅ 匹配 |
| - | `user_login` (原名) | ✅ 兼容 |
| - | `user_register` (原名) | ✅ 兼容 |

**修复**: 添加 action 别名支持

---

### 2. 数据同步 ✅ 完全匹配

| 前端调用 | 后端路由 | 状态 |
|---------|---------|------|
| `will_batch_sync` | `will_batch_sync` | ✅ |
| `capsule_batch_sync` | `capsule_batch_sync` | ✅ |
| `emergency_batch_sync` | `emergency_batch_sync` | ✅ |
| `checkin_sync` | `checkin_sync` | ✅ |
| `will_sync_witnesses` | `will_sync_witnesses` | ✅ |

---

### 3. 数据查询 ✅ 完全匹配

| 前端调用 | 后端路由 | 状态 |
|---------|---------|------|
| `capsule_list` | `capsule_list` | ✅ |
| `will_list` | `will_list` | ✅ |
| `will_list_witnesses` | `will_list_witnesses` | ✅ |
| `emergency_list` | `emergency_list` | ✅ |
| `config_get` | `config_get` | ✅ |

---

### 4. 文件上传 ✅ 完全匹配

| 前端调用 | 后端路由 | 状态 |
|---------|---------|------|
| `upload_file` | `upload_file` | ✅ |
| `will_update_asset` | ❓ 待确认 | ⚠️ |

---

## ⚠️ 待确认项目

### 1. will_update_asset

**前端调用**:
```swift
// DataManager.swift:531
var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api.php?action=will_update_asset")!)
```

**后端路由**: ❌ 未找到

**可能问题**:
- 后端可能使用其他 action 名称
- 或者这个功能未实现

**建议**:
1. 检查后端是否有 `will_update` 或类似路由
2. 或者前端使用 `will_batch_sync` 代替

---

## 📋 完整对接清单

### ✅ 已对接（14 个）

| # | Action | 前端 | 后端 | 状态 |
|---|--------|------|------|------|
| 1 | login/register | ✅ | ✅ | 完成 |
| 2 | will_batch_sync | ✅ | ✅ | 完成 |
| 3 | capsule_batch_sync | ✅ | ✅ | 完成 |
| 4 | emergency_batch_sync | ✅ | ✅ | 完成 |
| 5 | checkin_sync | ✅ | ✅ | 完成 |
| 6 | will_sync_witnesses | ✅ | ✅ | 完成 |
| 7 | capsule_list | ✅ | ✅ | 完成 |
| 8 | will_list | ✅ | ✅ | 完成 |
| 9 | will_list_witnesses | ✅ | ✅ | 完成 |
| 10 | emergency_list | ✅ | ✅ | 完成 |
| 11 | config_get | ✅ | ✅ | 完成 |
| 12 | upload_file | ✅ | ✅ | 完成 |
| 13 | location_upload | - | ✅ | 后端就绪 |
| 14 | family_* | - | ✅ | 后端就绪 |

---

## 🎯 总结

### 对接状态
- **完全匹配**: 12/14 (86%)
- **待确认**: 1 (will_update_asset)
- **未使用**: 后端多个 API 前端未调用

### 已修复问题
- ✅ login/register action 别名
- ✅ API 路径统一（api.php）
- ✅ 403 自杀问题
- ✅ 位置上传 SQL 错误

### 建议
1. **确认 will_update_asset** - 检查是否需要此 API
2. **统一命名规范** - 建议使用 `will_update` 而非 `will_update_asset`
3. **添加缺失路由** - 如前端需要但未实现的 API

---

*检查完成时间：2026-03-21 01:40*
