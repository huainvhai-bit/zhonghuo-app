# 📱 前端 API 迁移计划

## 状态

- ✅ 后端 GraphQL API 完成
- ✅ GraphQLClient.swift 完成
- ✅ APIManager.swift 完成
- ⏳ 前端文件迁移中

---

## 需要迁移的文件

### 高优先级（核心功能）

| 文件 | 旧 API 调用 | 新 GraphQL | 状态 |
|------|-----------|----------|------|
| `UserManager.swift` | users.php | user Query | ⏳ 待迁移 |
| `ContentView.swift` | users.php | user Query | ⏳ 待迁移 |
| `HomeStatusView.swift` | checkin.php | checkIn Mutation | ⏳ 待迁移 |
| `TimeCapsuleView.swift` | capsules.php | capsules Query/Mutation | ⏳ 待迁移 |
| `WillAssetsView.swift` | will.php | wills/assets Query/Mutation | ⏳ 待迁移 |
| `FamilyGuardView.swift` | family.php | family Query/Mutation | ⏳ 待迁移 |

---

### 中优先级（次要功能）

| 文件 | 旧 API 调用 | 新 GraphQL | 状态 |
|------|-----------|----------|------|
| `EmergencyContactsView.swift` | emergency_contacts.php | emergencyContacts | ⏳ 待迁移 |
| `WitnessesView.swift` | witnesses.php | witnesses | ⏳ 待迁移 |
| `UserManager.swift` | location.php | uploadLocation | ⏳ 待迁移 |
| `InviteCodeView.swift` | family.php | inviteFamily | ⏳ 待迁移 |

---

### 低优先级（辅助功能）

| 文件 | 旧 API 调用 | 新 GraphQL | 状态 |
|------|-----------|----------|------|
| `AccountValidator.swift` | users.php | user Query | ⏳ 待迁移 |
| `AuthView.swift` | users.php | user Query | ⏳ 待迁移 |
| `ZhonghuoApp.swift` | users.php | user Query | ⏳ 待迁移 |

---

## 迁移步骤

### 第 1 步：UserManager.swift

**修改内容**：
- 将 `loadUserFromServer()` 改为使用 GraphQL
- 将 `syncCapsulesToServer()` 等改为使用 APIManager

**示例代码**：
```swift
// 旧代码
func loadUserFromServer() async {
    var request = URLRequest(url: URL(string: "\(apiURL)/api/users.php?action=info")!)
    // ... 100+ 行代码
}

// 新代码
func loadUserFromServer() async {
    do {
        let userData = try await GraphQLClient.shared.fetchUserData()
        await MainActor.run {
            self.currentUser = User(
                id: userData.user.id,
                name: userData.user.name,
                // ...
            )
        }
    } catch {
        print("❌ 加载用户失败：\(error)")
    }
}
```

---

### 第 2 步：HomeStatusView.swift

**修改内容**：
- 签到功能改为使用 `APIManager.shared.checkIn()`

**示例代码**：
```swift
// 旧代码
func checkIn() async {
    let url = URL(string: "\(DataManager.apiURL)/api/checkin.php?action=sync")!
    // ... 50+ 行代码
}

// 新代码
func checkIn() async {
    do {
        try await APIManager.shared.checkIn(isAuto: false)
        await MainActor.run {
            lastCheckInDate = Date()
        }
    } catch {
        print("❌ 签到失败：\(error)")
    }
}
```

---

### 第 3 步：TimeCapsuleView.swift

**修改内容**：
- 胶囊列表改为使用 `GraphQLClient.shared.fetchUserData()`
- 创建/更新/删除改为使用 `APIManager.shared`

**示例代码**：
```swift
// 旧代码
func createCapsule() async {
    let url = URL(string: "\(DataManager.apiURL)/api/capsules.php?action=create")!
    // ... 60+ 行代码
}

// 新代码
func createCapsule() async {
    do {
        let id = try await APIManager.shared.createCapsule(
            title: newCapsuleTitle,
            type: selectedType,
            content: newCapsuleContent,
            openAt: selectedOpenDate
        )
        // 更新本地数据
    } catch {
        print("❌ 创建胶囊失败：\(error)")
    }
}
```

---

### 第 4 步：WillAssetsView.swift

**修改内容**：
- 遗嘱/资产列表改为使用 GraphQL
- 增删改改为使用 APIManager

---

### 第 5 步：FamilyGuardView.swift

**修改内容**：
- 家人列表改为使用 GraphQL
- 邀请码生成改为使用 `APIManager.shared.generateInviteCode()`

---

## 测试清单

### 功能测试

- [ ] 用户登录
- [ ] 用户信息加载
- [ ] 签到功能
- [ ] 胶囊增删改查
- [ ] 遗嘱增删改查
- [ ] 资产增删改查
- [ ] 家人邀请
- [ ] 紧急联系人增删改查
- [ ] 见证人增删改查
- [ ] 位置上传

---

### 性能测试

- [ ] 首页加载时间 < 1 秒
- [ ] 胶囊列表加载 < 500ms
- [ ] 签到响应 < 300ms
- [ ] 网络请求次数减少 80%

---

## 回滚方案

如果迁移过程中遇到问题，可以：

1. **从备份还原旧 API**
   ```bash
   cd /www/wwwroot/zhonghuo.cn
   cp -r backup/old-api-20260323/* api/
   ```

2. **使用旧版前端代码**
   ```bash
   cd /Users/lishimin/Documents/zhonghuo-app
   git checkout <commit-before-migration>
   ```

3. **混合模式**（临时方案）
   - 部分功能使用 GraphQL
   - 部分功能使用旧 REST API
   - 逐步迁移

---

## 迁移时间表

| 阶段 | 时间 | 任务 |
|------|------|------|
| 第 1 阶段 | 已完成 | 后端 GraphQL API |
| 第 2 阶段 | 已完成 | 前端 GraphQLClient + APIManager |
| 第 3 阶段 | 进行中 | UserManager + ContentView |
| 第 4 阶段 | 待执行 | HomeStatusView + TimeCapsuleView |
| 第 5 阶段 | 待执行 | WillAssetsView + FamilyGuardView |
| 第 6 阶段 | 待执行 | 其他辅助文件 |
| 第 7 阶段 | 待执行 | 全面测试 + 优化 |

---

## 迁移进度

```
后端 API 统一：✅ 100%
前端客户端：  ✅ 100%
核心文件迁移：⏳ 0%
完整测试：    ⏳ 0%
```

---

*最后更新：2026-03-23 22:25*
