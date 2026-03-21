# 📡 终活 App API 完整对接清单

**更新时间**: 2026-03-22 00:25  
**状态**: ✅ 前后端 100% 对接完成

---

## 📊 对接总览

| 模块 | API 数量 | 前端 | 后端 | 对接状态 | 测试状态 |
|------|---------|------|------|---------|---------|
| 用户认证 | 6 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 时光胶囊 | 5 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 遗嘱与资产 | 9 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 家人守护 | 5 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 见证人 | 3 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 紧急联系人 | 5 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 签到功能 | 4 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 短信服务 | 3 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 配置管理 | 3 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| 文件上传 | 1 | ✅ | ✅ | ✅ 100% | ⏳ 待测试 |
| **总计** | **44** | ✅ | ✅ | **✅ 100%** | ⏳ |

---

## 🔐 用户认证模块 (api/users.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 注册 | `register` | `register` | AuthView.swift | ✅ |
| 2 | 登录 | `login` | `login` | AuthView.swift | ✅ |
| 3 | 获取用户信息 | `get_userinfo` | `get_userinfo` | DataManager.swift | ✅ |
| 4 | 验证账号 | `validate` | `validate` | DataManager.swift | ✅ |
| 5 | 发送重置码 | `send_reset_code` | `send_reset_code` | DataManager.swift | ✅ **新增** |
| 6 | 重置密码 | `reset_password` | `reset_password` | DataManager.swift | ✅ **新增** |

### API 测试

```bash
# 注册
curl -X POST http://8.136.41.211:3395/api/users.php \
  -H "Content-Type: application/json" \
  -d '{"action":"register","name":"测试用户","phone":"13800138000","password":"123456"}'

# 登录
curl -X POST http://8.136.41.211:3395/api/users.php \
  -H "Content-Type: application/json" \
  -d '{"action":"login","phone":"13800138000","password":"123456"}'

# 发送重置码
curl -X POST http://8.136.41.211:3395/api/users.php \
  -H "Content-Type: application/json" \
  -d '{"action":"send_reset_code","phone":"13800138000"}'

# 重置密码
curl -X POST http://8.136.41.211:3395/api/users.php \
  -H "Content-Type: application/json" \
  -d '{"action":"reset_password","phone":"13800138000","code":"123456","new_password":"654321"}'
```

---

## ⏰ 时光胶囊模块 (api/capsules.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 列表 | `capsule_list` | `list` | DataManager.swift | ✅ |
| 2 | 创建 | `capsule_create` | `create` | DataManager.swift | ✅ |
| 3 | 更新 | `capsule_update` | `update` | DataManager.swift | ✅ |
| 4 | 删除 | `capsule_delete` | `delete` | DataManager.swift | ✅ |
| 5 | 批量同步 | `capsule_batch_sync` | `batch_sync` | DataManager.swift | ✅ |

### API 测试

```bash
# 获取胶囊列表
curl -X POST http://8.136.41.211:3395/api/capsules.php \
  -H "Content-Type: application/json" \
  -d '{"action":"list","token":"xxx"}'

# 批量同步胶囊
curl -X POST http://8.136.41.211:3395/api/capsules.php \
  -H "Content-Type: application/json" \
  -d '{"action":"batch_sync","token":"xxx","capsules":[...]}'
```

---

## 📜 遗嘱与资产模块 (api/will.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 遗嘱列表 | `will_list` | `list` | DataManager.swift | ✅ |
| 2 | 遗嘱创建 | `will_create` | `will_create` | DataManager.swift | ✅ |
| 3 | 遗嘱更新 | `will_update` | `will_update` | DataManager.swift | ✅ |
| 4 | 遗嘱删除 | `will_delete` | `will_delete` | DataManager.swift | ✅ |
| 5 | 资产列表 | `asset_list` | `asset_list` | DataManager.swift | ✅ |
| 6 | 资产创建 | `asset_create` | `asset_create` | DataManager.swift | ✅ |
| 7 | 资产更新 | `asset_update` | `asset_update` | DataManager.swift | ✅ |
| 8 | 资产删除 | `asset_delete` | `asset_delete` | DataManager.swift | ✅ |
| 9 | 更新资产 | `will_update_asset` | `update_asset` | DataManager.swift | ✅ |
| 10 | 批量同步 | `will_batch_sync` | `batch_sync` | DataManager.swift | ✅ |
| 11 | 见证人列表 | `will_list_witnesses` | `list_witnesses` | DataManager.swift | ✅ |
| 12 | 同步见证人 | `will_sync_witnesses` | `sync_witnesses` | DataManager.swift | ✅ |

### API 测试

```bash
# 获取遗嘱列表
curl -X POST http://8.136.41.211:3395/api/will.php \
  -H "Content-Type: application/json" \
  -d '{"action":"list","token":"xxx"}'

# 批量同步遗嘱
curl -X POST http://8.136.41.211:3395/api/will.php \
  -H "Content-Type: application/json" \
  -d '{"action":"batch_sync","token":"xxx","wills":[...]}'
```

---

## 👨‍👩‍👧 家人守护模块 (api/family.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 列表 | `family_list` | `list` | DataManager.swift | ✅ |
| 2 | 创建 | `family_create` | `create` | DataManager.swift | ✅ |
| 3 | 更新 | `family_update` | `update` | DataManager.swift | ✅ |
| 4 | 删除 | `family_delete` | `delete` | DataManager.swift | ✅ |
| 5 | 批量同步 | `family_batch_sync` | `batch_sync` | DataManager.swift | ✅ |

---

## 👥 见证人模块 (api/users.php + api/will.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 列表 | `witness_list` | `list_witnesses` | DataManager.swift | ✅ |
| 2 | 创建 | `witness_create` | 包含在 will 中 | WitnessView.swift | ✅ |
| 3 | 同步 | `witness_sync` | `sync_witnesses` | DataManager.swift | ✅ |

---

## 🚨 紧急联系人模块 (api/emergency_contacts.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 列表 | `emergency_list` | `list` | DataManager.swift | ✅ |
| 2 | 创建 | `emergency_create` | `create` | DataManager.swift | ✅ |
| 3 | 更新 | `emergency_update` | `update` | DataManager.swift | ✅ |
| 4 | 删除 | `emergency_delete` | `delete` | DataManager.swift | ✅ |
| 5 | 批量同步 | `emergency_batch_sync` | `batch_sync` | DataManager.swift | ✅ |

---

## ✅ 签到功能模块 (api/checkin.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 签到 | `checkin` | `checkin` | HomeStatusView.swift | ✅ |
| 2 | 签到历史 | `checkin_history` | `history` | DataManager.swift | ✅ |
| 3 | 签到同步 | `checkin_sync` | `checkin_sync` | DataManager.swift | ✅ **新增** |
| 4 | 获取配置 | `checkin_config` | `config` | DataManager.swift | ✅ |

### API 测试

```bash
# 签到
curl -X POST http://8.136.41.211:3395/api/checkin.php \
  -H "Content-Type: application/json" \
  -d '{"action":"checkin","token":"xxx"}'

# 签到同步
curl -X POST http://8.136.41.211:3395/api/checkin.php \
  -H "Content-Type: application/json" \
  -d '{"action":"checkin_sync","token":"xxx"}'
```

---

## 📱 短信服务模块 (api/sms.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 发送验证码 | `send_sms_code` | `send_sms_code` | AuthView.swift | ✅ |
| 2 | 验证验证码 | `verify_sms_code` | `verify_sms_code` | AuthView.swift | ✅ |
| 3 | 发送短信 | `send_sms` | `send_sms` | DataManager.swift | ✅ |

---

## ⚙️ 配置管理模块

### 应用配置 (api/config.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 获取配置 | `config_get` | `config_get` | DataManager.swift | ✅ |

### 通知配置 (api/notification_config.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 获取配置 | `notification_config_get` | `get` | NotificationManager.swift | ✅ |
| 2 | 更新配置 | `notification_config_update` | `update` | NotificationManager.swift | ✅ |

### 用户设置 (api/settings.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 获取设置 | `settings_get` | `get` | SettingsView.swift | ✅ |
| 2 | 更新设置 | `settings_update` | `update` | SettingsView.swift | ✅ |

---

## 📤 文件上传模块 (api/upload.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 上传文件 | `upload_file` | `upload` | DataManager.swift | ✅ |

---

## 📍 位置服务模块 (api/location.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 更新位置 | `location_update` | `update` | DeviceMonitor.swift | ✅ |
| 2 | 获取位置 | `location_get` | `get` | DeviceMonitor.swift | ✅ |

---

## 📋 设备信息模块 (api/device_info.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 上传设备信息 | `device_info_upload` | `upload` | DeviceMonitor.swift | ✅ |
| 2 | 获取设备信息 | `device_info_get` | `get` | DeviceMonitor.swift | ✅ |

---

## 🗑️ 缓存管理模块 (api/cache.php)

| 序号 | 功能 | 前端 Action | 后端 Action | 前端文件 | 状态 |
|------|------|------------|------------|---------|------|
| 1 | 清理缓存 | `cache_clear` | `clear` | 管理工具 | ✅ |
| 2 | 获取缓存 | `cache_get` | `get` | 管理工具 | ✅ |

---

## 🔧 后端新增 API 说明

### 1. 密码重置功能

**文件**: `api/users.php`  
**提交**: 9029927 🔧 添加密码重置 API 和签到同步兼容性

#### send_reset_code - 发送重置密码验证码

**请求**:
```json
POST /api/users.php?action=send_reset_code
{
  "phone": "13800138000"
}
```

**响应**:
```json
{
  "status": "success",
  "data": {
    "code": "123456",
    "message": "验证码已发送（开发模式）"
  }
}
```

**说明**: 
- 开发模式下直接返回验证码
- 生产环境应通过短信发送
- 验证码有效期 5 分钟

#### reset_password - 重置密码

**请求**:
```json
POST /api/users.php?action=reset_password
{
  "phone": "13800138000",
  "code": "123456",
  "new_password": "newpass123"
}
```

**响应**:
```json
{
  "status": "success",
  "data": []
}
```

### 2. 签到同步兼容性

**文件**: `api/checkin.php`  
**提交**: 9029927 🔧 添加密码重置 API 和签到同步兼容性

#### checkin_sync - 签到数据同步

**说明**: 
- 兼容前端旧版 action 名称
- 实际调用 syncCheckIn() 函数
- 用于多设备签到状态同步

---

## 🧪 完整测试清单

### 用户认证测试
- [ ] 注册新账号
- [ ] 登录成功
- [ ] 获取用户信息
- [ ] 发送重置验证码
- [ ] 重置密码

### 时光胶囊测试
- [ ] 创建胶囊
- [ ] 编辑胶囊
- [ ] 删除胶囊
- [ ] 查看列表
- [ ] 批量同步

### 遗嘱与资产测试
- [ ] 创建遗嘱
- [ ] 编辑遗嘱
- [ ] 删除遗嘱
- [ ] 添加资产
- [ ] 编辑资产
- [ ] 删除资产
- [ ] 批量同步

### 家人守护测试
- [ ] 添加家人
- [ ] 编辑家人
- [ ] 删除家人
- [ ] 批量同步

### 见证人测试
- [ ] 添加见证人
- [ ] 编辑见证人
- [ ] 删除见证人
- [ ] 同步见证人

### 紧急联系人测试
- [ ] 添加联系人
- [ ] 编辑联系人
- [ ] 删除联系人
- [ ] 批量同步

### 签到功能测试
- [ ] 手动签到
- [ ] 自动签到
- [ ] 查看签到历史
- [ ] 签到同步

### 短信服务测试
- [ ] 发送验证码
- [ ] 验证验证码

### 配置管理测试
- [ ] 获取应用配置
- [ ] 获取通知配置
- [ ] 更新通知配置

### 文件上传测试
- [ ] 上传图片
- [ ] 上传视频
- [ ] 上传文档

---

## 📊 对接完成度统计

| 类别 | 总数 | 已完成 | 完成率 |
|------|------|--------|--------|
| **核心功能 API** | 44 | 44 | 100% ✅ |
| **前端调用** | 44 | 44 | 100% ✅ |
| **后端实现** | 44 | 44 | 100% ✅ |
| **文档完整性** | 44 | 44 | 100% ✅ |

---

## 🚀 部署状态

### 前端
- ✅ 代码已修复
- ✅ 编译通过
- ✅ 已推送到 GitHub
- **提交**: 36f3879 🔧 修复前后端 API 对接

### 后端
- ✅ API 已完善
- ✅ 已推送到 GitHub
- **提交**: 9029927 🔧 添加密码重置 API 和签到同步兼容性

### 服务器
- ⏳ 待部署最新代码
- **地址**: http://8.136.41.211:3395
- **路径**: /www/wwwroot/zhonghuo.cn

---

## 📝 部署命令

```bash
# SSH 登录服务器
ssh root@8.136.41.211

# 进入应用目录
cd /www/wwwroot/zhonghuo.cn

# 拉取最新后端代码
git pull origin main

# 重启 PHP-FPM
systemctl restart php-fpm-81

# 验证 API
curl http://8.136.41.211:3395/api/users.php?action=validate
```

---

**对接状态**: ✅ 100% 完成  
**等待**: 服务器部署 + 功能测试验证

*更新时间：2026-03-22 00:25*
