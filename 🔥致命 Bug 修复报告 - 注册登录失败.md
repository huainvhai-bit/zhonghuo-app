# 🔥 致命 Bug 修复报告 - 注册登录失败

## 报告时间
2026-03-21 02:05

---

## 🚨 问题描述

**症状**: 用户注册/登录时持续返回 400 错误

```json
{
  "error": "未知操作，需要 action 参数 (register/login/get_userinfo/validate)",
  "code": "INVALID_ACTION"
}
```

**影响**: 
- ❌ 无法注册新用户
- ❌ 无法登录现有用户
- ❌ App 完全无法使用

---

## 🔍 问题诊断

### 第一次排查：后端路由问题

**怀疑**: 后端缺少 `login/register` 路由

**修复**: 添加 action 别名
```php
// api.php
'login' => ['file' => 'api/users.php', 'func' => 'login'],
'register' => ['file' => 'api/users.php', 'func' => 'register'],
```

**结果**: ❌ 仍然失败

---

### 第二次排查：服务器缓存问题

**怀疑**: 服务器 OPcache 缓存旧代码

**检查**: 服务器确认是最新代码（c0c305f）

**结果**: ❌ 不是缓存问题

---

### 第三次排查：前端请求参数

**发现关键问题**:

```
日志显示:
请求 URL: http://8.136.41.211:3395/api.php?action=user_login  ← GET 参数
请求 Body: {"action": "register", ...}                        ← POST 参数
```

**问题分析**:
1. 前端调用 `apiRequest(action: "register")`
2. 但 URL 硬编码为 `?action=user_login`
3. Body 中是 `{"action": "register"}`
4. **后端优先读取 GET 参数** → 得到 `user_login`
5. 路由表中 `user_login` 存在，但后端实际检查的是 Body 的 action
6. 导致混乱和 400 错误

---

## 🔧 根本原因

**文件**: `AuthView.swift`

**错误代码**（第 343 行）:
```swift
private func apiRequest(action: String, body: [String: Any]) async throws -> [String: Any] {
    // ...
    
    // ❌ 致命 Bug：硬编码 action=user_login
    let urlString = "\(DataManager.apiURL)/api.php?action=user_login"
    
    // 无论传入的 action 是什么（login 或 register）
    // URL 始终是 user_login
}
```

**调用链**:
```
AuthView.handleSubmit()
  → apiRequest(action: "register", body: ...)
    → URL 硬编码为 ?action=user_login  ← 错误！
    → Body: {"action": "register"}
    → 后端读取 GET 的 user_login
    → 返回 400 错误
```

---

## ✅ 修复方案

**修改文件**: `AuthView.swift`

**修复代码**:
```swift
private func apiRequest(action: String, body: [String: Any]) async throws -> [String: Any] {
    // ...
    
    // ✅ 修复：使用传入的 action 参数
    let urlString = "\(DataManager.apiURL)/api.php?action=\(action)"
    
    // 现在:
    // - 调用 login 时 → ?action=login
    // - 调用 register 时 → ?action=register
}
```

**同时修复日志**:
```swift
// ❌ 旧
print("   请求 URL: \(DataManager.apiURL)/api.php?action=user_login")

// ✅ 新
print("   请求 URL: \(DataManager.apiURL)/api.php?action=\(action)")
```

---

## 📦 提交记录

### 前端（zhonghuo-app）

| 提交号 | 说明 | 时间 |
|--------|------|------|
| `dd79204` | 🔥 致命 Bug 修复 - 注册登录 URL 硬编码问题 | 2026-03-21 01:55 |
| `1cf6839` | ⚡ 性能优化 - 消除卡顿问题 | 2026-03-21 01:35 |

### 后端（zhonghuo-backend-php）

| 提交号 | 说明 | 时间 |
|--------|------|------|
| `c0c305f` | 🔧 添加 will_update_asset API | 2026-03-21 01:45 |
| `630cdbf` | 🔧 添加用户认证 action 别名 | 2026-03-21 01:38 |

---

## ✅ 验证方法

### 1. 测试注册

```bash
curl -X POST "http://8.136.41.211:3395/api.php?action=register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "18888888889",
    "password": "123456",
    "name": "测试用户"
  }'
```

**预期结果**:
```json
{
  "success": true,
  "message": "注册成功",
  "data": {
    "user_id": "xxx",
    "token": "xxx"
  }
}
```

---

### 2. 测试登录

```bash
curl -X POST "http://8.136.41.211:3395/api.php?action=login" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "18888888889",
    "password": "123456"
  }'
```

**预期结果**:
```json
{
  "success": true,
  "message": "登录成功",
  "data": {
    "user_id": "xxx",
    "token": "xxx",
    "is_new": false
  }
}
```

---

### 3. App 测试

1. **打开 App**
2. **点击注册**
3. **输入信息**:
   - 手机号：`18888888889`
   - 密码：`123456`
   - 验证码：（可选，开发模式跳过）
4. **点击注册按钮**
5. **预期**: 注册成功，自动登录

---

## 📊 问题排查过程总结

| 步骤 | 怀疑原因 | 排查方法 | 结果 |
|------|---------|---------|------|
| 1 | 后端路由缺失 | 添加 login/register 别名 | ❌ 未解决 |
| 2 | 服务器缓存 | 检查 OPcache | ❌ 不是缓存 |
| 3 | 前端代码 | 检查请求日志 | ✅ 找到根因 |

**关键发现**:
- 后端优先读取 GET 参数的 action
- 前端 URL 和 Body 的 action 不一致
- 硬编码导致参数传递错误

---

## 🎯 教训和改进

### 教训
1. **不要硬编码参数** - 尤其是函数参数
2. **日志要准确** - 打印实际值而非固定字符串
3. **排查要系统** - 从前端到后端逐层检查
4. **URL 和 Body 要一致** - 避免参数冲突

### 改进
1. ✅ 使用参数构建 URL
2. ✅ 日志打印实际值
3. ✅ 统一 action 传递方式
4. ✅ 添加更多调试信息

---

## 📋 修复清单

### 已完成
- [x] 发现 URL 硬编码问题
- [x] 修复 apiRequest() 函数
- [x] 修复日志输出
- [x] 编译测试通过
- [x] 代码推送

### 待测试
- [ ] 注册功能测试
- [ ] 登录功能测试
- [ ] 完整流程测试

---

## 🚀 下一步

1. **重新编译安装 App**
   ```bash
   cd /Users/lishimin/Documents/zhonghuo-app
   xcodebuild -scheme 终活 build
   ```

2. **测试注册登录**
   - 使用测试账号：18888888889 / 123456
   - 验证是否能正常注册和登录

3. **如果成功**
   - 继续测试其他功能
   - 验证数据同步

4. **如果失败**
   - 查看最新日志
   - 继续排查

---

## 📞 快速参考

### 当前版本
- **前端**: `dd79204` (最新)
- **后端**: `c0c305f` (最新)

### 测试账号
- 手机号：`18888888889`
- 密码：`123456`

### API 地址
- URL: `http://8.136.41.211:3395/api.php`
- Action: `login` / `register`

---

*修复完成时间：2026-03-21 02:05*  
*状态：✅ 已修复，待测试*
