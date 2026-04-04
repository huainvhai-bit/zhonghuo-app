# 📖 终活 App 技术开发文档

> **版本**: v1.0.0  
> **最后更新**: 2026-04-04  
> **项目状态**: 开发中  
> **团队**: 小皮 (前端) + 龙虾 (后端)

---

## 📑 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [前端开发](#3-前端开发)
4. [后端开发](#4-后端开发)
5. [数据库设计](#5-数据库设计)
6. [API 接口](#6-api-接口)
7. [开发规范](#7-开发规范)
8. [部署指南](#8-部署指南)

---

## 1. 项目概述

### 1.1 产品介绍

**终活 App** 是一款生命管理应用，帮助用户规划和管理生命中的重大事项，包括：

- 📝 **遗嘱管理** - 记录和保存个人遗嘱
- 💰 **资产管理** - 整理个人资产信息
- 👥 **家人守护** - 关联家人，互相关爱守护
- ⏰ **时光胶囊** - 定时发送消息给未来的自己或家人
- ✅ **每日签到** - 安全打卡，家人可知
- 🆘 **紧急联系人** - 设置紧急情况下的联系人

### 1.2 项目信息

| 项目 | 信息 |
|------|------|
| 前端仓库 | https://github.com/huainvhai-bit/zhonghuo-app |
| 后端仓库 | https://github.com/huainvhai-bit/zhonghuo-backend-php |
| 前端技术 | Swift 5 + SwiftUI + iOS 15+ |
| 后端技术 | PHP 8.0+ + MySQL 8.0 + GraphQL |
| 开发工具 | Xcode 15+ |

### 1.3 核心功能模块

```
终活 App
├── 首页模块
│   ├── 签到打卡 (CheckIn)
│   ├── 安全状态 (LifeCheckStatus)
│   ├── 进度卡片 (ProgressCard)
│   └── 胶囊预览 (CapsulePreview)
├── 遗嘱模块
│   ├── 遗嘱列表 (WillAssetsView)
│   ├── 遗嘱编辑 (WillModuleEdit)
│   ├── 资产管理 (AssetsView)
│   └── 见证人管理 (WitnessView)
├── 时光胶囊 (TimeCapsuleView)
│   ├── 文字胶囊
│   ├── 语音胶囊
│   └── 视频胶囊
├── 家人守护 (FamilyGuardView)
│   ├── 家人列表
│   ├── 邀请码绑定
│   ├── 二维码分享
│   └── 家人详情
├── 我的 (SettingsView)
│   ├── 个人信息
│   ├── 统计信息
│   ├── 设备信息
│   ├── 设置
│   └── 关于
└── 通用功能
    ├── 登录注册 (AuthView)
    ├── 紧急联系人 (EmergencyContactsView)
    ├── 云存储管理 (CloudStorageManager)
    └── 消息通知 (NotificationManager)
```

---

## 2. 技术架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS 客户端 (SwiftUI)                    │
├─────────────────────────────────────────────────────────────┤
│  View 层          │  Manager 层       │  Model 层           │
│  - HomeView       │  - DataManager    │  - User             │
│  - WillView       │  - UserManager    │  - TimeCapsule      │
│  - CapsuleView    │  - KeychainManager│  - WillModule       │
│  - FamilyView     │  - CloudStorage   │  - FamilyMember     │
│  - SettingsView   │  - AuthManager    │  - EmergencyContact │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    HTTPS / GraphQL API
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHP 后端服务器                            │
├─────────────────────────────────────────────────────────────┤
│  API 层            │  业务逻辑层       │  数据访问层         │
│  - graphql.php    │  - UserManager    │  - DB.php (PDO)     │
│  - version.php    │  - CapsuleManager │  - CloudStorage.php │
│  - family.php     │  - FamilyManager  │  - SMSManager.php   │
│  - auth.php       │  - AuthManager    │                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │   MySQL 8.0     │
                    │   Database      │
                    └─────────────────┘
```

### 2.2 技术栈详情

#### 前端 (iOS)

| 技术 | 版本 | 用途 |
|------|------|------|
| Swift | 5.9+ | 开发语言 |
| SwiftUI | 5.0+ | UI 框架 |
| iOS | 15.0+ | 最低支持版本 |
| Xcode | 15.0+ | 开发工具 |
| GraphQL | - | API 调用 |
| Keychain | - | 安全存储 Token |
| UserDefaults | - | 本地配置存储 |
| FileManager | - | 本地文件管理 |
| AVFoundation | - | 音视频录制播放 |
| PDFKit | - | PDF 生成导出 |

#### 后端 (PHP)

| 技术 | 版本 | 用途 |
|------|------|------|
| PHP | 8.0+ | 后端语言 |
| MySQL | 8.0+ | 数据库 |
| PDO | - | 数据库访问 (预处理) |
| JWT | - | Token 认证 |
| GraphQL | - | API 查询语言 |
| OpenSSL | - | 加密解密 |
| GD/ImageMagick | - | 图片处理 |

### 2.3 项目结构

#### 前端目录结构

```
zhonghuo-app/
├── zhonghuo/zhonghuo/          # 主应用目录
│   ├── zhonghuoApp.swift       # 应用入口
│   └── ContentView.swift       # 主视图
├── Views/                       # 视图层
│   ├── HomeStatusView.swift    # 首页
│   ├── WillAssetsView.swift    # 遗嘱资产
│   ├── TimeCapsuleView.swift   # 时光胶囊
│   ├── FamilyGuardView.swift   # 家人守护
│   ├── SettingsView.swift      # 设置
│   ├── AuthView.swift          # 登录注册
│   └── ...
├── Managers/                    # 管理层
│   ├── DataManager.swift       # 数据中心
│   ├── UserManager.swift       # 用户管理
│   ├── KeychainManager.swift   # Keychain 管理
│   ├── CloudStorageManager.swift
│   ├── NotificationManager.swift
│   └── ...
├── Models/                      # 数据模型
│   ├── Models.swift            # 完整数据模型
│   └── FamilyMember.swift      # 家人模型
├── Utils/                       # 工具类
│   ├── SecureStorage.swift     # 安全存储
│   ├── Colors.swift            # 颜色定义
│   ├── ErrorHandler.swift      # 错误处理
│   └── ...
└── Components/                  # 通用组件
    ├── QRCodeScannerView.swift # 二维码扫描
    └── ...
```

#### 后端目录结构

```
zhonghuo-backend-php/
├── api/                         # API 接口
│   ├── graphql.php             # GraphQL 统一接口
│   ├── version.php             # 版本检测 API
│   └── ...
├── lib/                         # 核心库
│   ├── DB.php                  # 数据库连接
│   ├── CloudStorage.php        # 云存储
│   ├── GraphQLClient.php       # GraphQL 客户端
│   └── ...
├── admin/                       # 后台管理
│   ├── index.php               # 后台首页
│   ├── users.php               # 用户管理
│   ├── capsules.php            # 胶囊管理
│   └── ...
├── config.php                   # 配置文件
├── database.sql                 # 数据库初始化脚本
└── .htaccess                    # Apache 配置
```

---

## 3. 前端开发

### 3.1 开发环境配置

#### 系统要求

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS Simulator 17.0+ 或真机 iOS 15.0+

#### 克隆项目

```bash
git clone https://github.com/huainvhai-bit/zhonghuo-app.git
cd zhonghuo-app
```

#### 配置文件

创建 `AppConfig.swift` (如不存在):

```swift
struct AppConfig {
    static let defaultAPIURL = "http://localhost:8080"
    static let appVersion = "1.0.0"
}
```

### 3.2 核心类说明

#### DataManager (数据中心)

```swift
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // API 地址
    static var baseURL: String = ""
    static var apiURL: String = ""
    
    // 用户数据
    @Published var currentUser: User?
    @Published var capsules: [TimeCapsule] = []
    @Published var willModules: [WillModule] = []
    @Published var assets: [WillAsset] = []
    @Published var witnesses: [Witness] = []
    @Published var emergencyContacts: [User.EmergencyContact] = []
    
    // 核心方法
    func fetchServerConfig() async throws
    func saveCapsules()
    func syncWithBackend() async throws
}
```

#### UserManager (用户管理)

```swift
@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    // 登录注册
    func login(phone: String, code: String) async throws
    func register(phone: String, code: String, name: String) async throws
    func logout()
    
    // 用户信息
    func fetchUserInfo() async throws
    func updateUserInfo() async throws
}
```

#### KeychainManager (安全存储)

```swift
class KeychainManager {
    static let shared = KeychainManager()
    
    func saveToken(_ token: String) -> OSStatus
    func getToken() -> String?
    func deleteToken() -> OSStatus
    
    func saveUserId(_ userId: String) -> OSStatus
    func getUserId() -> String?
}
```

### 3.3 视图开发规范

#### 基本结构

```swift
struct XXXView: View {
    // MARK: - 数据绑定
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 状态
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAlert = false
    
    // MARK: - 主体视图
    var body: some View {
        NavigationView {
            VStack {
                // 内容
            }
            .navigationTitle("标题")
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - 方法
    private func loadData() {
        Task {
            await loadAsync()
        }
    }
}
```

#### @MainActor 标记

**重要**: 所有 `ObservableObject` 类必须标记 `@MainActor`，避免后台线程修改 `@Published` 属性导致警告。

```swift
@MainActor
class DataManager: ObservableObject {
    @Published var capsules: [TimeCapsule] = []
}
```

### 3.4 GraphQL 调用

```swift
// 查询用户信息
let query = """
query {
    user {
        id
        name
        phone
        stats {
            capsulesCount
            willsCount
            checkInStreak
        }
    }
}
"""

let result = try await GraphQLClient.shared.query(query)
```

### 3.5 编译与运行

```bash
# 清理构建
xcodebuild clean -project 终活.xcodeproj -scheme 终活

# 编译
xcodebuild -project 终活.xcodeproj -scheme 终活 \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# 或使用 Xcode GUI
# 打开 终活.xcodeproj，按 Cmd+R 运行
```

---

## 4. 后端开发

### 4.1 开发环境配置

#### 系统要求

- PHP 8.0+
- MySQL 8.0+
- Apache/Nginx
- Composer (可选)

#### 安装依赖

```bash
cd zhonghuo-backend-php
composer install  # 如有 composer.json
```

#### 配置文件

复制并编辑 `config.php`:

```php
<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'zhonghuo');
define('DB_USER', 'root');
define('DB_PASS', 'password');
define('API_SECRET', 'your_secret_key');
```

### 4.2 核心库说明

#### DB.php (数据库连接)

```php
function getDB(): PDO {
    static $db = null;
    if ($db === null) {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $db = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]);
    }
    return $db;
}
```

#### graphql.php (统一 API 接口)

```php
// 支持 GraphQL 查询
$query = $_POST['query'] ?? '';
$variables = $_POST['variables'] ?? [];

// 解析并执行查询
$result = GraphQLClient::execute($query, $variables);

// 返回 JSON 响应
header('Content-Type: application/json');
echo json_encode($result, JSON_UNESCAPED_UNICODE);
```

### 4.3 API 开发规范

#### 响应格式

所有 API 统一返回格式:

```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}
```

错误响应:

```json
{
  "success": false,
  "error": "错误信息",
  "code": 400
}
```

#### 预处理语句 (安全)

**必须使用预处理语句**防止 SQL 注入:

```php
// ✅ 正确
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$userId]);
$user = $stmt->fetch();

// ❌ 错误 (禁止)
$user = $db->query("SELECT * FROM users WHERE id = $userId");
```

### 4.4 云存储集成

支持三种存储方式:

| 存储类型 | 配置项 | 用途 |
|---------|--------|------|
| local | `storage_type=local` | 本地存储 |
| aliyun | `storage_type=aliyun` | 阿里云 OSS |
| tencent | `storage_type=tencent` | 腾讯云 COS |

配置项在 `system_config` 表中管理。

---

## 5. 数据库设计

### 5.1 核心表结构

#### users (用户表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 用户 ID (UUID) |
| name | VARCHAR(100) | 姓名 |
| phone | VARCHAR(20) | 手机号 |
| password_hash | VARCHAR(255) | 密码哈希 |
| invite_code | VARCHAR(10) | 邀请码 |
| last_login_at | DATETIME | 最后登录时间 |
| last_login_ip | VARCHAR(50) | 最后登录 IP |
| created_at | DATETIME | 创建时间 |

#### capsules (时光胶囊表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 胶囊 ID |
| user_id | VARCHAR(36) | 用户 ID |
| type | VARCHAR(50) | 类型 (text/audio/video) |
| title | VARCHAR(255) | 标题 |
| content | TEXT | 内容 |
| media_url | VARCHAR(512) | 媒体文件 URL |
| open_at | DATETIME | 开启时间 |
| is_opened | TINYINT | 是否已开启 |
| cloud_backup_status | ENUM | 云备份状态 |

#### will_modules (遗嘱模块表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 模块 ID |
| user_id | VARCHAR(36) | 用户 ID |
| type | VARCHAR(50) | 类型 |
| title | VARCHAR(255) | 标题 |
| content | TEXT | 内容 |
| media_url | VARCHAR(512) | 媒体 URL |
| is_completed | TINYINT | 是否完成 |

#### family_members (家人表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 成员 ID |
| user_id | VARCHAR(36) | 用户 ID |
| name | VARCHAR(100) | 姓名 |
| relation | VARCHAR(50) | 关系 |
| phone | VARCHAR(20) | 手机号 |
| status | ENUM | 状态 (pending/accepted) |
| invite_code | VARCHAR(10) | 邀请码 |

#### emergency_contacts (紧急联系人表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) | 联系人 ID |
| user_id | VARCHAR(36) | 用户 ID |
| name | VARCHAR(100) | 姓名 |
| relationship | VARCHAR(50) | 关系 |
| phone | VARCHAR(20) | 手机号 |

#### system_config (系统配置表)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 自增 ID |
| config_key | VARCHAR(100) | 配置键 |
| config_value | TEXT | 配置值 |
| description | VARCHAR(255) | 描述 |

### 5.2 表关系图

```
users (1) ──────< (N) capsules
  │
  ├──────< (N) will_modules
  │
  ├──────< (N) will_assets
  │
  ├──────< (N) witnesses
  │
  ├──────< (N) family_members
  │
  └──────< (N) emergency_contacts
```

---

## 6. API 接口

### 6.1 GraphQL 接口

#### 查询用户信息

```graphql
query {
  user {
    id
    name
    phone
    stats {
      capsulesCount
      willsCount
      checkInStreak
      emergencyContactsCount
    }
  }
}
```

#### 查询胶囊列表

```graphql
query {
  capsules {
    id
    title
    type
    sendDate
    isSent
  }
}
```

#### 绑定家人

```graphql
mutation($inviteCode: String!) {
  bindFamilyByInviteCode(inviteCode: $inviteCode) {
    success
    message
    data {
      members { id name relation status }
      invited { id name relation status }
    }
  }
}
```

### 6.2 REST API

#### 版本检测

**GET** `/api/version.php`

响应:

```json
{
  "success": true,
  "data": {
    "ios": {
      "version": "1.0.0",
      "build": "1",
      "updateUrl": "https://apps.apple.com/...",
      "description": "Bug 修复和性能优化",
      "forceUpdate": false
    }
  }
}
```

#### 短信验证码

**POST** `/api/sms/send.php`

请求:

```json
{
  "phone": "13800138000",
  "type": "login"
}
```

---

## 7. 开发规范

### 7.1 代码规范

#### Swift 命名规范

```swift
// 类名：大驼峰
class DataManager { }

// 变量/函数：小驼峰
private var currentUser: User?
func loadData() { }

// 常量：小驼峰
let defaultAPIURL = "..."

// 枚举：大驼峰
enum CheckInStatus { case safe, warning, danger }
```

#### PHP 命名规范

```php
// 类名：大驼峰
class GraphQLClient { }

// 函数：小写 + 下划线
function get_db() { }

// 常量：大写 + 下划线
define('API_SECRET', '...');
```

### 7.2 Git 提交规范

```bash
# 格式：<type>: <description>

# 类型
feat:     新功能
fix:      Bug 修复
docs:     文档更新
style:    代码格式 (不影响功能)
refactor: 重构
test:     测试
chore:    构建/工具

# 示例
git commit -m "feat: 添加版本检测功能"
git commit -m "fix: 修复 Keychain Token 读取失败"
git commit -m "docs: 更新 API 文档"
```

### 7.3 开发流程

1. **需求分析** - 明确功能需求和技术方案
2. **分支开发** - 从 `main` 创建功能分支
3. **本地测试** - 编译通过 + 功能测试
4. **代码审查** - 审查助手检查代码质量
5. **合并推送** - PR 合并到 `main` 并推送

### 7.4 开发规则

1. **功能变更必须先请示** - 不允许私自修改功能逻辑
2. **指令不明确时必须确认** - 模糊需求先澄清再执行
3. **不要添加多余文件** - 直接修改源码，不添加 .sh/.md
4. **分工明确** - 前端 (Swift) / 后端 (PHP) / 审查助手
5. **使用 Claude Code 工具** - 代码修改通过工具执行
6. **审查通过才能推送** - 所有代码必须经过审查
7. **自主解决问题** - 有问题先自己排查，实在搞不定再汇报
8. **进度列表汇报** - 任务进度用列表格式，30 秒刷新
9. **自动安装技能** - 缺少技能时自动安装
10. **规则分布记忆** - 规则分散在 memory 文件中
11. **禁止私自推送** - 推送前必须确认
12. **Memory 追加模式** - 更新 memory 时追加，不覆盖
13. **主代理写 Memory** - 只有主代理可以修改 memory 文件

---

## 8. 部署指南

### 8.1 前端部署 (iOS)

#### App Store 发布流程

1. **准备发布**
   ```bash
   # 修改版本号
   # Xcode: Project → Build Settings → Version
   
   # 归档
   # Xcode: Product → Archive
   ```

2. **上传到 App Store Connect**
   - 打开 Xcode Organizer
   - 选择 Archive → Distribute App
   - 选择 App Store Connect → Upload

3. **App Store Connect 配置**
   - 填写应用信息
   - 上传截图
   - 提交审核

### 8.2 后端部署 (PHP)

#### 服务器要求

- PHP 8.0+
- MySQL 8.0+
- Apache 2.4+ / Nginx 1.20+
- SSL 证书 (推荐)

#### 部署步骤

1. **上传代码**
   ```bash
   git clone https://github.com/huainvhai-bit/zhonghuo-backend-php.git
   cd zhonghuo-backend-php
   ```

2. **配置数据库**
   ```bash
   # 创建数据库
   mysql -u root -p -e "CREATE DATABASE zhonghuo CHARACTER SET utf8mb4"
   
   # 导入表结构
   mysql -u root -p zhonghuo < database.sql
   ```

3. **配置文件**
   ```bash
   cp config.example.php config.php
   # 编辑 config.php 填入数据库信息
   ```

4. **设置权限**
   ```bash
   chmod 755 .
   chmod 644 config.php
   chown -R www-data:www-data .
   ```

5. **验证部署**
   ```bash
   # 测试 API
   curl https://your-domain.com/api/version.php
   ```

### 8.3 环境变量配置

#### system_config 表配置项

| 配置键 | 说明 | 默认值 |
|--------|------|--------|
| `sms_is_development` | 短信开发者模式 | 1 |
| `sms_test_code` | 测试验证码 | 123456 |
| `api_secret` | JWT 密钥 | (自定义) |
| `storage_type` | 存储类型 | local |
| `cloud_storage_enabled` | 云存储开关 | 0 |
| `app_version_ios` | iOS 版本号 | 1.0.0 |
| `app_update_url_ios` | iOS 更新地址 | App Store URL |

---

## 附录

### A. 常见问题 (FAQ)

#### Q1: Token 读取失败 (-25300)

**原因**: Token 未保存到 Keychain

**解决**: 在 `AuthView.swift` 中添加:
```swift
KeychainManager.shared.saveToken(token)
KeychainManager.shared.saveUserId(userId)
```

#### Q2: SQL 注入风险

**预防**: 始终使用 PDO 预处理语句
```php
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$userId]);
```

#### Q3: 后台线程修改@Published 警告

**解决**: 给 ObservableObject 添加 `@MainActor` 标记
```swift
@MainActor
class DataManager: ObservableObject { }
```

### B. 相关文档

- [GraphQL API 文档](📚GraphQL API 文档.md)
- [后端部署指南](🚀后端部署指南.md)
- [云存储使用指南](☁️云存储总开关使用指南.md)
- [代码审查报告](CODE_REVIEW_REPORT.md)

---

**文档维护**: 小皮  
**联系方式**: support@zhonghuo.cn  
**最后更新**: 2026-04-04
