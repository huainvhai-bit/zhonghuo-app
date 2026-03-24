# 🔧 Token 验证修复报告 - 解决登录后退出问题

**时间**: 2026-03-24 14:10  
**状态**: ✅ 代码已修复，⏳ 待部署  
**问题**: 登录后立即自动退出登录

---

## 📊 问题分析

### 错误日志
```
❌ 胶囊同步失败：networkError
❌ 遗嘱同步失败：networkError
❌ 见证人同步失败：networkError
❌ 用户不存在（404）
❌ Token 验证失败（401），后端可能没有此账号，执行退出登录
🔴 UserManager.logout() 被调用
```

### 根本原因（2 个问题）

#### 问题 1: getConfig 返回值格式错误
```php
// ❌ 之前
return ['success' => true, 'config' => [...]];

// ✅ 修复后
return [
    'checkinIntervalHours' => 48,
    'notificationReminderThresholdHours' => 12,
    ...
];
```

**影响**: 系统配置加载失败，但不导致退出

#### 问题 2: Token 验证 API 不存在 🔴
```swift
// ❌ 前端调用
GET /api/users.php?action=info

// ❌ 后端状态
users.php 文件不存在 → 返回 404

// 🔴 结果
触发自动退出登录
```

---

## 🔧 修复方案

### 1. 前端修复（ContentView.swift）

**修改前**:
```swift
let url = URL(string: "\(DataManager.apiURL)/api/users.php?action=info")!
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

**修改后**:
```swift
// 使用 GraphQL validateUser query
let query = """
query {
    validateUser(userId: "") {
        success
        message
        data { id name phone }
    }
}
"""

var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/graphql.php")!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
```

**响应解析**:
```swift
// GraphQL 响应格式：{"data": {"validateUser": {"success": true, ...}}}
if let dataObj = json?["data"] as? [String: Any],
   let validateUser = dataObj["validateUser"] as? [String: Any],
   let success = validateUser["success"] as? Bool {
    return success ? .success : .unauthorized
}
```

### 2. 后端修复（graphql.php）

#### 修复 1: getConfig 返回值
```php
function getConfig($db) {
    $config = [];
    $stmt = $db->query('SELECT config_key, config_value FROM system_config 
                        WHERE config_key IN ("checkin_interval_hours", ...)');
    while ($row = $stmt->fetch()) {
        $config[$row['config_key']] = $row['config_value'];
    }
    
    return [
        'checkinIntervalHours' => (int)($config['checkin_interval_hours'] ?? 48),
        'notificationReminderThresholdHours' => (int)($config['notification_reminder_threshold_hours'] ?? 12),
        'notificationPushIntervalHours' => (int)($config['notification_push_interval_hours'] ?? 2),
        'smsIsDevelopment' => (int)($config['sms_is_development'] ?? 1)
    ];
}
```

#### 修复 2: validateUser 移动 + 返回值
```php
// 从 resolveMutation 移至 resolveQuery
function resolveQuery($query, $variables, $userId, $db) {
    // validateUser 查询
    if (preg_match('/validateUser\s*\(/', $query)) {
        $result['validateUser'] = validateUser($userId, $db);
    }
    ...
}

// 修正返回值格式
function validateUser($userId, $db) {
    if (!$userId) return ['success' => false, 'message' => '未授权'];
    
    $stmt = $db->prepare('SELECT id, name, phone FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user) return ['success' => false, 'message' => '用户不存在'];
    
    return [
        'success' => true,
        'message' => '验证通过',
        'data' => ['id' => $user['id'], 'name' => $user['name'], 'phone' => $user['phone']]
    ];
}
```

---

## 📝 Git 提交

### 前端 (zhonghuo-app)
```
723376c - 🔧 修复 Token 验证 - 改用 GraphQL validateUser
```

### 后端 (zhonghuo-backend-php)
```
72d0c82 - 🔧 修复 validateUser - 移至 Query 并修正返回值格式
946e73c - 🐛 修复 getConfig 返回值格式 - 匹配 GraphQL Schema
```

---

## 🚀 部署步骤

### 一键部署
```bash
ssh root@8.136.41.211
cd /www/wwwroot/zhonghuo.cn
git pull origin main
systemctl restart php-fpm-81
```

### 详细步骤
```bash
# 1. SSH 登录
ssh root@8.136.41.211

# 2. 拉取最新代码
cd /www/wwwroot/zhonghuo.cn
git pull origin main

# 应看到：
# Updating 3e99529..72d0c82
# Fast-forward
# api/graphql.php | 20 ++++++++++++--------
# 1 file changed, 12 insertions(+), 8 deletions(-)

# 3. 重启 PHP-FPM
systemctl restart php-fpm-81

# 4. 验证部署
git log --oneline -1
# 应看到：72d0c82 - 🔧 修复 validateUser - 移至 Query 并修正返回值格式
```

---

## 🧪 验证测试

### 测试 1: GraphQL Token 验证
```bash
# 获取 Token（从 App 日志或数据库）
TOKEN="eyJhbGciOiJIUzI1NiIs..."

# 测试 validateUser
curl -X POST http://localhost:3395/api/graphql.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { validateUser(userId: \"\") { success message data { id name phone } } }"}'
```

**预期响应**:
```json
{
  "data": {
    "validateUser": {
      "success": true,
      "message": "验证通过",
      "data": {
        "id": "user_xxx",
        "name": "张三",
        "phone": "18888888889"
      }
    }
  }
}
```

### 测试 2: GraphQL 配置查询
```bash
curl -X POST http://localhost:3395/api/graphql.php \
  -H "Content-Type: application/json" \
  -d '{"query": "query { getConfig { checkinIntervalHours notificationReminderThresholdHours } }"}'
```

**预期响应**:
```json
{
  "data": {
    "getConfig": {
      "checkinIntervalHours": 48,
      "notificationReminderThresholdHours": 12
    }
  }
}
```

### 测试 3: App 登录
1. 打开终活 App
2. 登录：18888888889 / 123456
3. 点击登录

**预期**:
- ✅ 登录成功
- ✅ 显示首页
- ✅ **不再自动退出登录** 🎉
- ✅ Token 验证成功
- ✅ 系统配置加载成功
- ✅ 位置上传成功
- ⚠️ 胶囊/遗嘱/见证人同步失败（正常，这些 API 还未迁移）

---

## 📊 修复效果

### 修复前 ❌
```
登录 → Token 验证 (404) → 用户不存在 → 退出登录 🔴
```

### 修复后 ✅
```
登录 → Token 验证 (GraphQL) → 验证通过 → 保持登录 ✅
```

---

## ⚠️ 注意事项

### 仍然失败的功能（预期内）
以下功能使用旧 REST API，尚未迁移到 GraphQL，会失败但不影响核心功能：

- ❌ 胶囊同步 - `capsules.php`
- ❌ 遗嘱同步 - `will.php`
- ❌ 见证人同步 - `witnesses.php`
- ❌ 紧急联系人 - `emergency_contacts.php`

**影响**: 数据同步失败，使用本地缓存  
**解决**: 下次迭代迁移到 GraphQL

### 正常工作的功能
- ✅ 用户注册/登录
- ✅ Token 验证
- ✅ 系统配置加载
- ✅ 位置上传
- ✅ 自动签到
- ✅ 本地数据访问

---

## 🎯 部署检查清单

- [ ] SSH 登录成功
- [ ] git pull 成功（看到 72d0c82 提交）
- [ ] PHP-FPM 已重启
- [ ] curl 测试 GraphQL validateUser 成功
- [ ] curl 测试 GraphQL getConfig 成功
- [ ] App 登录测试成功
- [ ] **登录后不再自动退出** ✅

---

## 💡 经验教训

### 问题根源
1. **API 删除不彻底** - users.php 被删除但前端仍在调用
2. **GraphQL 迁移不完整** - 只迁移了部分 API
3. **错误处理过于严格** - 404 直接触发退出登录

### 改进方案
1. **统一入口** - 所有 API 通过 graphql.php
2. **优雅降级** - 网络错误时保持登录，使用本地缓存
3. **完整迁移** - 迁移所有 API 后再删除旧文件

---

**部署后，登录退出问题将完全解决！** 🎉

**最后更新**: 2026-03-24 14:10
