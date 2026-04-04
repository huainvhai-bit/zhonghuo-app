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
9. [测试策略](#9-测试策略)
10. [错误处理与日志规范](#10-错误处理与日志规范)
11. [缓存与网络层](#11-缓存与网络层)
12. [性能优化](#12-性能优化)
13. [安全规范](#13-安全规范)
14. [监控与告警](#14-监控与告警)
15. [版本兼容与数据迁移](#15-版本兼容与数据迁移)
16. [CI/CD 流程](#16-cicd-流程)
17. [第三方依赖](#17-第三方依赖)
18. [数据模型详解](#18-数据模型详解)
19. [API 完整参考](#19-api-完整参考)
20. [故障排查指南](#20-故障排查指南)
21. [版本历史](#21-版本历史)
22. [术语表](#22-术语表)

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
- **Xcode 15.0+** (前端开发主要工具)
- iOS Simulator 17.0+ 或真机 iOS 15.0+

#### 开发工具分工

| 开发领域 | 主要工具 | 辅助工具 |
|---------|---------|---------|
| **前端 (iOS/Swift)** | Xcode 15+ | exec (编译测试) |
| **后端 (PHP)** | Claude Code | exec/edit (文件操作) |
| **代码审查** | 审查助手 | - |
| **文档编写** | Markdown 编辑器 | - |

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
- **Claude Code** (后端开发主要工具)

#### 开发工具分工

| 开发领域 | 主要工具 | 辅助工具 |
|---------|---------|---------|
| **后端 (PHP)** | Claude Code | exec/edit (文件操作) |
| **数据库** | MySQL CLI / phpMyAdmin | - |
| **API 测试** | curl / Postman | - |
| **代码审查** | 审查助手 | - |

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
5. **开发工具规范** - 前端用 Xcode，后端用 Claude Code
6. **审查通过才能推送** - 所有代码必须经过审查
7. **自主解决问题** - 有问题先自己排查，实在搞不定再汇报
8. **进度列表汇报** - 任务进度用列表格式，30 秒刷新
9. **自动安装技能** - 缺少技能时自动安装
10. **规则分布记忆** - 规则分散在 memory 文件中
11. **禁止私自推送** - 推送前必须确认
12. **Memory 追加模式** - 更新 memory 时追加，不覆盖
13. **主代理写 Memory** - 只有主代理可以修改 memory 文件
14. **开发工具分工** - 前端 (Xcode) / 后端 (Claude Code) / 辅助工具 (exec/edit 等)

---

## 8. 部署指南

### 8.1 前端部署 (iOS)

#### 开发工具

**前端开发统一使用 Xcode**:
- 代码编写：Xcode 编辑器
- 界面设计：Interface Builder / SwiftUI Preview
- 编译调试：Xcode Build & Debug
- 性能分析：Instruments
- 归档发布：Xcode Organizer

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

#### 开发工具

**后端开发统一使用 Claude Code**:
- 代码编写：Claude Code 工具
- 文件操作：exec/edit 辅助工具
- 代码审查：审查助手
- API 测试：curl / Postman

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

## 9. 测试策略

### 9.1 单元测试 (XCTest)

**测试覆盖率目标**: 核心模块 > 80%

```swift
import XCTest
@testable import zhonghuo

final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() async throws {
        dataManager = DataManager.shared
        // 清理测试数据
        dataManager.capsules.removeAll()
    }
    
    func testAddCapsule() async throws {
        let capsule = TimeCapsule(
            id: "test-1",
            title: "测试胶囊",
            content: "测试内容",
            type: .text,
            sendDate: Date().addingTimeInterval(86400)
        )
        
        dataManager.capsules.append(capsule)
        XCTAssertEqual(dataManager.capsules.count, 1)
        XCTAssertEqual(dataManager.capsules.first?.title, "测试胶囊")
    }
    
    func testSaveCapsules() throws {
        // 测试本地持久化
        dataManager.saveCapsules()
        XCTAssertTrue(FileManager.default.fileExists(atPath: dataManager.capsulesPath))
    }
}
```

**测试命令**:
```bash
# 运行所有测试
xcodebuild test -project 终活.xcodeproj -scheme 终活 \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# 生成覆盖率报告
xcodebuild test -project 终活.xcodeproj -scheme 终活 \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -resultBundlePath TestResults.xcresult
```

### 9.2 UI 测试

```swift
import XCTest

final class zhonghuoUITests: XCTestCase {
    func testLoginFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // 输入手机号
        let phoneField = app.textFields["手机号"]
        phoneField.tap()
        phoneField.typeText("13800138000")
        
        // 获取验证码
        app.buttons["获取验证码"].tap()
        
        // 输入验证码
        let codeField = app.textFields["验证码"]
        codeField.tap()
        codeField.typeText("123456")
        
        // 登录
        app.buttons["登录"].tap()
        
        // 验证登录成功 (跳转到首页)
        XCTAssertTrue(app.staticTexts["首页"].exists)
    }
}
```

### 9.3 后端测试 (PHPUnit)

```php
<?php
use PHPUnit\Framework\TestCase;

class UserManagerTest extends TestCase {
    private $db;
    
    protected function setUp(): void {
        $this->db = getTestDB();
    }
    
    public function testLoginSuccess() {
        $result = login('13800138000', '123456');
        $this->assertTrue($result['success']);
        $this->assertArrayHasKey('token', $result['data']);
    }
    
    public function testLoginFailure() {
        $result = login('13800138000', 'wrong_code');
        $this->assertFalse($result['success']);
        $this->assertEquals('验证码错误', $result['error']);
    }
}
```

**运行测试**:
```bash
cd zhonghuo-backend-php
vendor/bin/phpunit tests/
```

### 9.4 API 接口测试

使用 Postman 或 curl 测试 API:

```bash
# 测试版本检测 API
curl https://api.zhonghuo.cn/api/version.php

# 测试 GraphQL 查询
curl -X POST https://api.zhonghuo.cn/api/graphql.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"query": "query { user { id name } }"}'
```

### 9.5 测试清单

**发布前必测**:
- [ ] 登录注册流程
- [ ] 胶囊创建/编辑/删除
- [ ] 家人邀请绑定
- [ ] 每日签到
- [ ] 紧急联系人设置
- [ ] 云存储上传下载
- [ ] 推送通知接收
- [ ] 离线模式数据同步

---

## 10. 错误处理与日志规范

### 10.1 统一错误类型 (前端)

```swift
// 统一错误类型
enum AppError: LocalizedError {
    case network(Error)
    case auth(String)
    case dataNotFound
    case serverError(Int, String)
    case localDatabase(Error)
    case invalidParameter(String)
    case permissionDenied
    
    var userMessage: String {
        switch self {
        case .network(let error):
            return "网络连接失败：\(error.localizedDescription)"
        case .auth(let message):
            return "认证失败：\(message)"
        case .dataNotFound:
            return "数据不存在"
        case .serverError(_, let msg):
            return msg
        case .localDatabase:
            return "本地数据错误"
        case .invalidParameter(let field):
            return "参数错误：\(field)"
        case .permissionDenied:
            return "权限不足"
        }
    }
    
    var logMessage: String {
        return "[\(self)] \(userMessage)"
    }
}

// 使用示例
func loadData() async throws {
    do {
        let result = try await GraphQLClient.shared.query(query)
        // 处理结果
    } catch let error as AppError {
        Logger.error(error.logMessage)
        showError(error.userMessage)
    } catch {
        Logger.error("未知错误：\(error)")
        showError("发生未知错误，请稍后重试")
    }
}
```

### 10.2 统一错误类型 (后端)

```php
<?php
class ApiException extends Exception {
    private $statusCode;
    private $userMessage;
    
    public function __construct(
        string $message, 
        int $statusCode = 500,
        string $userMessage = '服务器错误'
    ) {
        parent::__construct($message);
        $this->statusCode = $statusCode;
        $this->userMessage = $userMessage;
    }
    
    public function getResponse(): array {
        return [
            'success' => false,
            'error' => $this->userMessage,
            'code' => $this->statusCode,
            'debug' => $this->getMessage() // 仅开发环境
        ];
    }
}

// 使用示例
function getUserInfo(string $userId): array {
    if (!validateUserId($userId)) {
        throw new ApiException('无效的用户 ID', 400, '参数错误');
    }
    
    $user = fetchUser($userId);
    if (!$user) {
        throw new ApiException('用户不存在', 404, '用户不存在');
    }
    
    return $user;
}

// 全局错误处理
set_exception_handler(function($e) {
    if ($e instanceof ApiException) {
        http_response_code($e->getStatusCode());
        echo json_encode($e->getResponse(), JSON_UNESCAPED_UNICODE);
    } else {
        error_log("未捕获异常：{$e->getMessage()}");
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => '服务器错误']);
    }
});
```

### 10.3 日志规范 (前端)

```swift
// 统一日志工具
enum Logger {
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
    }
    
    static func log(_ message: String, level: Level = .info, file: String = #file, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("\(level.rawValue) [\(fileName):\(line)] \(message)")
        #endif
    }
    
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .debug, file: file, line: line)
    }
    
    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .info, file: file, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .warning, file: file, line: line)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(message, level: .error, file: file, line: line)
    }
}

// 使用示例
Logger.info("用户登录成功")
Logger.debug("API 响应：\(response)")
Logger.warning("Token 即将过期")
Logger.error("网络请求失败：\(error)")
```

### 10.4 日志规范 (后端)

```php
<?php
class Logger {
    const DEBUG = 'DEBUG';
    const INFO = 'INFO';
    const WARNING = 'WARNING';
    const ERROR = 'ERROR';
    
    public static function log(string $message, string $level = self::INFO, string $context = '') {
        $timestamp = date('Y-m-d H:i:s');
        $logMessage = "[$timestamp] [$level] [$context] $message";
        
        // 开发环境输出到控制台
        if (defined('DEBUG') && DEBUG) {
            echo $logMessage . PHP_EOL;
        }
        
        // 生产环境写入文件
        $logFile = __DIR__ . '/../logs/' . date('Y-m-d') . '.log';
        file_put_contents($logFile, $logMessage . PHP_EOL, FILE_APPEND);
    }
    
    public static function debug(string $message, string $context = '') {
        self::log($message, self::DEBUG, $context);
    }
    
    public static function info(string $message, string $context = '') {
        self::log($message, self::INFO, $context);
    }
    
    public static function warning(string $message, string $context = '') {
        self::log($message, self::WARNING, $context);
    }
    
    public static function error(string $message, string $context = '') {
        self::log($message, self::ERROR, $context);
    }
}

// 使用示例
Logger::info("用户登录成功", "auth");
Logger::debug("SQL 查询：$sql", "database");
Logger::warning("Token 即将过期", "auth");
Logger::error("数据库连接失败：" . $e->getMessage(), "database");
```

### 10.5 日志级别说明

| 级别 | 用途 | 示例 |
|------|------|------|
| DEBUG | 调试信息，仅开发环境 | API 请求/响应详情 |
| INFO | 正常业务日志 | 用户登录、数据同步 |
| WARNING | 警告信息，不影响功能 | 参数异常、降级处理 |
| ERROR | 错误信息，需要处理 | 网络失败、数据库错误 |

---

## 11. 缓存与网络层

### 11.1 缓存策略

| 数据类型 | 存储位置 | 过期时间 | 同步策略 |
|---------|---------|---------|---------|
| Token | Keychain | 永久 | 登录/登出更新 |
| 用户信息 | 内存 + 本地 JSON | 24 小时 | 启动时刷新 |
| 胶囊列表 | 内存 + 本地 JSON | 实时 | 修改后立即同步 |
| 遗嘱数据 | 内存 + 本地 JSON | 实时 | 修改后立即同步 |
| 配置信息 | UserDefaults | 长期 | 启动时获取 |
| 服务器配置 | 内存 | 24 小时 | 启动时获取 |

### 11.2 网络层抽象

```swift
// 统一网络服务
class NetworkService {
    static let shared = NetworkService()
    
    // HTTP 方法
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    // 统一请求
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // 1. 构建 URL
        guard var urlComponents = URLComponents(string: DataManager.apiURL + endpoint) else {
            throw AppError.invalidParameter("URL")
        }
        
        // 2. 添加查询参数 (GET)
        if method == .GET, let params = parameters {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        // 3. 创建请求
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 4. 添加 Token
        if requiresAuth {
            if let token = KeychainManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // 5. 添加请求体 (POST/PUT)
        if method == .POST || method == .PUT {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters ?? [:])
        }
        
        // 6. 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 7. 处理响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(NSError(domain: "Network", code: -1, userInfo: nil))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw AppError.auth("Token 无效，请重新登录")
        case 403:
            throw AppError.permissionDenied
        case 404:
            throw AppError.dataNotFound
        default:
            throw AppError.serverError(httpResponse.statusCode, "服务器错误")
        }
    }
    
    // GraphQL 专用方法
    func graphql<T: Decodable>(query: String, variables: [String: Any]? = nil) async throws -> T {
        var params: [String: Any] = ["query": query]
        if let variables = variables {
            params["variables"] = variables
        }
        return try await request(endpoint: "/graphql.php", method: .POST, parameters: params)
    }
}

// 使用示例
let result: UserResponse = try await NetworkService.shared.graphql(query: "query { user { id name } }")
```

### 11.3 重试机制

```swift
// 网络重试
func requestWithRetry<T: Decodable>(
    endpoint: String,
    maxRetries: Int = 3,
    delay: TimeInterval = 1.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await NetworkService.shared.request(endpoint: endpoint)
        } catch {
            lastError = error
            Logger.warning("请求失败，第 \(attempt) 次重试：\(error)")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    
    throw lastError ?? AppError.network(NSError(domain: "Retry", code: -1))
}
```

---

## 12. 性能优化

### 12.1 前端性能优化

**列表优化**:
```swift
// ✅ 使用 LazyVStack
ScrollView {
    LazyVStack {
        ForEach(capsules) { capsule in
            CapsuleRow(capsule: capsule)
        }
    }
}

// ❌ 避免使用 VStack (全部渲染)
VStack {
    ForEach(capsules) { capsule in
        CapsuleRow(capsule: capsule)
    }
}
```

**图片懒加载**:
```swift
// 使用 AsyncImage
AsyncImage(url: URL(string: mediaURL)) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
```

**避免不必要的 @Published 触发**:
```swift
// ✅ 批量更新
func updateMultiple() {
    $capsules.withTransaction {
        capsules.append(newCapsule)
        capsules.remove(at: 0)
    }
}

// ❌ 多次触发
capsules.append(newCapsule)  // 触发 1
capsules.remove(at: 0)       // 触发 2
```

**大文件异步处理**:
```swift
// 视频压缩在后台线程
func compressVideo(inputURL: URL, outputURL: URL) async throws {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            // 压缩逻辑
            continuation.resume()
        }
    }
}
```

### 12.2 后端性能优化

**数据库索引**:
```sql
-- 常用查询字段添加索引
CREATE INDEX idx_user_created ON capsules(user_id, created_at);
CREATE INDEX idx_status ON capsules(cloud_backup_status);
CREATE INDEX idx_phone ON users(phone);
CREATE INDEX idx_invite_code ON users(invite_code);
```

**查询优化**:
```php
// ✅ 使用 LIMIT 限制结果数
$stmt = $db->prepare("SELECT * FROM capsules WHERE user_id = ? ORDER BY created_at DESC LIMIT 50");

// ✅ 只查询需要的字段
$stmt = $db->prepare("SELECT id, title, type FROM capsules WHERE user_id = ?");

// ❌ 避免 SELECT *
$stmt = $db->prepare("SELECT * FROM capsules WHERE user_id = ?");
```

**缓存热点数据**:
```php
// 使用 Redis 缓存用户信息
function getCachedUser($userId) {
    $redis = getRedis();
    $key = "user:$userId";
    
    // 尝试从缓存获取
    $cached = $redis->get($key);
    if ($cached) {
        return json_decode($cached, true);
    }
    
    // 从数据库查询
    $user = fetchUser($userId);
    
    // 写入缓存 (5 分钟)
    $redis->setex($key, 300, json_encode($user));
    
    return $user;
}
```

### 12.3 性能监控指标

| 指标 | 目标值 | 监控方式 |
|------|--------|---------|
| App 启动时间 | < 2 秒 | Xcode Instruments |
| 页面渲染时间 | < 300ms | Instruments |
| API 响应时间 | < 200ms | 后端日志 |
| 网络请求成功率 | > 99% | 客户端统计 |
| 崩溃率 | < 0.1% | Crashlytics |

---

## 13. 安全规范

### 13.1 前端安全

**Token 存储**:
```swift
// ✅ 必须使用 Keychain
KeychainManager.shared.saveToken(token)

// ❌ 禁止使用 UserDefaults
UserDefaults.standard.set(token, forKey: "token")  // 不安全!
```

**HTTPS 强制 (ATS 配置)**:
```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.zhonghuo.cn</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

**输入验证**:
```swift
// 手机号验证
func validatePhone(_ phone: String) -> Bool {
    let pattern = "^1[3-9]\\d{9}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
    return predicate.evaluate(with: phone)
}

// 邀请码验证
func validateInviteCode(_ code: String) -> Bool {
    return code.count == 6 && code.uppercased() == code
}
```

**敏感数据不落日志**:
```swift
// ✅ 脱敏处理
Logger.info("用户登录：\(phone.prefix(3))****\(phone.suffix(4))")

// ❌ 禁止打印完整敏感信息
Logger.info("用户 Token: \(token)")  // 禁止!
```

### 13.2 后端安全

**SQL 预处理 (100% 覆盖)**:
```php
// ✅ 正确
$stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
$stmt->execute([$phone]);

// ❌ 禁止字符串拼接
$sql = "SELECT * FROM users WHERE phone = '$phone'";  // 禁止!
```

**XSS 防护**:
```php
// 输出转义
echo htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8');

// JSON 输出
header('Content-Type: application/json');
echo json_encode($data, JSON_UNESCAPED_UNICODE);
```

**CSRF 防护**:
```php
// 生成 CSRF Token
session_start();
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// 验证 CSRF Token
if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) {
    throw new ApiException('CSRF 验证失败', 403);
}
```

**接口限流**:
```php
// 防止短信接口被刷
function rateLimit($phone, $maxRequests = 5, $window = 3600) {
    $redis = getRedis();
    $key = "rate_limit:sms:$phone";
    
    $count = $redis->incr($key);
    if ($count == 1) {
        $redis->expire($key, $window);
    }
    
    if ($count > $maxRequests) {
        throw new ApiException('操作过于频繁', 429);
    }
}
```

**JWT Token 安全**:
```php
// Token 配置
$tokenConfig = [
    'exp' => time() + 86400,  // 24 小时过期
    'iat' => time(),
    'iss' => 'zhonghuo-api',
    'sub' => $userId
];

// 敏感操作日志
function logSensitiveAction($userId, $action, $ip) {
    error_log("[$userId] $action from $ip");
}

// 使用示例
logSensitiveAction($userId, 'login', $_SERVER['REMOTE_ADDR']);
```

### 13.3 安全清单

**发布前检查**:
- [ ] Token 使用 Keychain 存储
- [ ] 所有 SQL 使用预处理
- [ ] 输出内容 XSS 转义
- [ ] 敏感接口限流
- [ ] HTTPS 强制开启
- [ ] 错误信息不泄露敏感数据
- [ ] 敏感操作日志记录
- [ ] JWT Token 过期时间 < 24h

---

## 14. 监控与告警

### 14.1 前端监控

**崩溃收集 (Firebase Crashlytics)**:
```swift
import FirebaseCrashlytics

// 记录自定义日志
Crashlytics.crashlytics().log("用户执行了敏感操作")

// 记录非致命错误
Crashlytics.crashlytics().record(error: error)

// 设置用户标识
Crashlytics.crashlytics().setUserID(userId)
```

**性能监控**:
```swift
import FirebasePerformance

// 监控网络请求
let metric = Performance.startHTTPTrace(url: url)
// ... 请求完成
metric?.stop()

// 监控代码段
let trace = Performance.startTrace(name: "数据同步")
// ... 业务逻辑
trace?.stop()
```

### 14.2 后端监控

**API 响应时间监控**:
```php
// 中间件记录响应时间
$start = microtime(true);

// ... 处理请求

$duration = microtime(true) - $duration;
if ($duration > 1.0) {
    Logger::warning("慢查询：{$duration}s", "performance");
}

// 写入监控日志
file_put_contents('/var/log/zhonghuo/performance.log', 
    "$duration\t$endpoint\t" . date('Y-m-d H:i:s') . PHP_EOL, 
    FILE_APPEND);
```

**错误率监控**:
```php
// 统计错误率
$errorRate = $errorCount / $totalRequests * 100;
if ($errorRate > 5) {
    sendAlert("错误率超过 5%: {$errorRate}%");
}
```

**慢查询日志**:
```php
// MySQL 慢查询配置
// my.cnf
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2  # 超过 2 秒的查询
```

### 14.3 告警配置

**告警级别**:
| 级别 | 条件 | 通知方式 |
|------|------|---------|
| P0 - 严重 | 服务不可用、数据丢失 | 短信 + 电话 |
| P1 - 高 | 错误率 > 10%、响应时间 > 5s | 短信 + 飞书 |
| P2 - 中 | 错误率 > 5%、响应时间 > 2s | 飞书通知 |
| P3 - 低 | 警告信息、性能下降 | 邮件通知 |

**告警渠道**:
```php
// 飞书机器人通知
function sendFeishuAlert($message) {
    $webhook = "https://open.feishu.cn/open-apis/bot/v2/hook/xxx";
    $data = [
        "msg_type" => "text",
        "content" => ["text" => "🚨 终活 App 告警\n" . $message]
    ];
    
    $ch = curl_init($webhook);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_exec($ch);
}

// 邮件告警
function sendEmailAlert($subject, $message) {
    mail('admin@zhonghuo.cn', $subject, $message);
}
```

---

## 15. 版本兼容与数据迁移

### 15.1 版本兼容性

**前端版本检查**:
```swift
// 系统版本检查
if #available(iOS 17.0, *) {
    // 使用新 API
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        // iOS 15+ API
    }
} else {
    // 降级方案
    if let window = UIApplication.shared.windows.first {
        // 旧 API
    }
}

// App 版本检查
let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
```

**后端 API 版本控制**:
```
# URL 版本化
/api/v1/graphql.php
/api/v2/graphql.php

# 或 Header 版本化
Accept: application/vnd.zhonghuo.v1+json
```

### 15.2 数据迁移流程

**数据库变更原则**:
1. **只增不减** - 不删除字段，只添加新字段
2. **默认值兼容** - 新字段设置合理的默认值
3. **双写过渡** - 新旧字段同时写入一段时间
4. **向后兼容** - 旧版本 App 仍能正常使用

**迁移脚本示例**:
```sql
-- migrate_v1.1.sql
-- 添加新字段 (设置默认值)
ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) DEFAULT '';
ALTER TABLE users ADD COLUMN last_checkin_at DATETIME DEFAULT NULL;

-- 数据迁移 (如有需要)
UPDATE users SET last_checkin_at = created_at WHERE last_checkin_at IS NULL;
```

**迁移流程**:
1. 创建迁移脚本 `migrate_vX.X.sql`
2. 在测试环境验证
3. 灰度发布 (10% 用户)
4. 监控错误日志
5. 全量发布
6. 观察 24 小时无问题后完成

---

## 16. CI/CD 流程

### 16.1 前端 CI/CD

#### GitHub Actions 配置

创建 `.github/workflows/ios-ci.yml`:

```yaml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer
    
    - name: Build
      run: |
        xcodebuild -project 终活.xcodeproj \
          -scheme 终活 \
          -destination 'platform=iOS Simulator,name=iPhone 17,OS=17.0' \
          build
    
    - name: Run Tests
      run: |
        xcodebuild test -project 终活.xcodeproj \
          -scheme 终活 \
          -destination 'platform=iOS Simulator,name=iPhone 17,OS=17.0'
```

#### 编译检查清单

- [ ] Xcode 版本 >= 15.0
- [ ] iOS 部署目标 >= 15.0
- [ ] Swift 版本 >= 5.9
- [ ] 所有 `@Published` 属性在 `@MainActor` 类中
- [ ] 无编译警告

### 16.2 后端 CI/CD

#### GitHub Actions 配置

创建 `.github/workflows/php-ci.yml`:

```yaml
name: PHP CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.0'
    
    - name: Lint PHP files
      run: |
        find . -name "*.php" -not -path "./vendor/*" | xargs -n 1 php -l
    
    - name: Install dependencies
      run: composer install --no-progress
    
    - name: Run tests
      run: vendor/bin/phpunit tests/
```

#### 代码检查清单

- [ ] PHP 版本 >= 8.0
- [ ] 所有 SQL 使用预处理语句
- [ ] 无 PHP 语法错误
- [ ] 通过 PHPUnit 测试

### 16.3 自动部署流程

#### 前端发布流程

```
1. 测试通过 → 2. 修改版本号 → 3. Archive → 4. 上传 App Store Connect
```

**步骤**:
1. CI 测试通过
2. 手动修改 `Info.plist` 版本号
3. Xcode: Product → Archive
4. 上传到 App Store Connect
5. 等待审核发布

#### 后端部署流程

```
1. 推送到 main → 2. CI 检查 → 3. SSH 连接服务器 → 4. git pull → 5. 清理缓存
```

**部署脚本** (`deploy.sh`):
```bash
#!/bin/bash
set -e

echo "🚀 开始部署终活后端..."

# SSH 连接服务器
ssh user@server "
  cd /var/www/zhonghuo-backend-php &&
  git pull origin main &&
  composer install --no-dev --optimize-autoloader &&
  php -r \"opcache_reset();\" &&
  echo '✅ 部署完成'
"

echo "✅ 本地部署脚本执行完成"
```

---

## 17. 第三方依赖

### 17.1 前端依赖

#### Swift Package Manager

| 包名 | 用途 | 版本 | 必需 |
|------|------|------|------|
| Firebase | 崩溃收集/性能监控 | 最新 | 推荐 |
| (暂无其他) | - | - | - |

#### 系统框架

| 框架 | 用途 |
|------|------|
| SwiftUI | UI 框架 |
| Combine | 响应式编程 |
| AVFoundation | 音视频录制播放 |
| PDFKit | PDF 生成导出 |
| LocalAuthentication | 生物识别认证 |
| UserNotifications | 推送通知 |
| Photos | 相册访问 |
| AVKit | 视频播放 |

### 17.2 后端依赖

#### Composer 包 (如使用)

| 包名 | 用途 | 版本 |
|------|------|------|
| firebase/php-jwt | JWT Token 生成验证 | ^6.0 |
| graham-campbell/manager | 管理器基类 | ^3.0 |

#### PHP 扩展

| 扩展 | 用途 |
|------|------|
| PDO | 数据库访问 |
| OpenSSL | 加密解密 |
| GD | 图片处理 |
| JSON | JSON 处理 |
| MBString | 多字节字符串 |

---

## 18. 数据模型详解

### 18.1 前端 Swift 模型

#### TimeCapsule (时光胶囊)

```swift
struct TimeCapsule: Identifiable, Codable {
    var id: String                    // UUID
    var title: String                 // 标题
    var content: String               // 内容 (文字/转录文本)
    var type: CapsuleType             // text/audio/video
    var mediaURL: String              // 本地媒体文件 URL
    var mediaServerURL: String        // 服务器媒体 URL (云存储)
    var mediaDuration: Double         // 媒体时长 (秒)
    var sendDate: Date                // 发送时间
    var isSent: Bool                  // 是否已发送
    var createdAt: Date               // 创建时间
    var deletedAt: Date?              // 删除时间 (软删除)
    var cloudBackupStatus: CloudBackupStatus  // 云备份状态
    var cloudBackupAt: Date?          // 云备份时间
}

enum CapsuleType: String, Codable {
    case text = "文字"
    case audio = "语音"
    case video = "视频"
}

enum CloudBackupStatus: String, Codable {
    case pending = "待备份"
    case uploading = "上传中"
    case backedUp = "已备份"
    case failed = "失败"
}
```

#### WillModule (遗嘱模块)

```swift
struct WillModule: Identifiable, Codable {
    var id: String                    // UUID
    var userId: String                // 用户 ID
    var type: WillType                // 遗嘱类型
    var title: String                 // 标题
    var subtitle: String?             // 副标题
    var content: String               // 内容
    var mediaURL: String?             // 媒体 URL
    var isCompleted: Bool             // 是否完成
    var createdAt: Date               // 创建时间
    var updatedAt: Date               // 更新时间
}

enum WillType: String, Codable {
    case financial = "财产遗嘱"
    case message = "留言遗嘱"
    case video = "视频遗嘱"
    case letter = "信件遗嘱"
}
```

#### User (用户)

```swift
struct User: Codable {
    var id: String                    // UUID
    var name: String                  // 姓名
    var phone: String                 // 手机号
    var avatarUrl: String?            // 头像 URL
    var inviteCode: String            // 邀请码 (6 位)
    var lastLoginAt: Date?            // 最后登录时间
    var lastLoginIp: String?          // 最后登录 IP
    var stats: UserStats              // 统计信息
    var emergencyContacts: [EmergencyContact]  // 紧急联系人
}

struct UserStats: Codable {
    var capsulesCount: Int            // 胶囊数量
    var willsCount: Int               // 遗嘱数量
    var assetsCount: Int              // 资产数量
    var checkInStreak: Int            // 签到天数
    var familyMembersCount: Int       // 家人数量
    var emergencyContactsCount: Int   // 紧急联系人数量
}

struct EmergencyContact: Codable {
    var id: String                    // UUID
    var name: String                  // 姓名
    var relationship: String          // 关系
    var phone: String                 // 手机号
}
```

#### FamilyMember (家人成员)

```swift
struct FamilyMember: Identifiable, Codable {
    var id: String                    // UUID
    var userId: String?               // 用户 ID (已注册用户)
    var name: String                  // 姓名
    var phone: String?                // 手机号
    var relation: String              // 关系
    var status: FamilyStatus          // 状态
    var inviteCode: String?           // 邀请码
    var createdAt: Date               // 创建时间
}

enum FamilyStatus: String, Codable {
    case pending = "待接受"
    case accepted = "已接受"
    case rejected = "已拒绝"
}
```

### 18.2 后端数据库表

#### users 表

| 字段 | 类型 | 长度 | 说明 | 索引 |
|------|------|------|------|------|
| id | VARCHAR | 36 | 用户 ID (UUID) | PRIMARY |
| name | VARCHAR | 100 | 姓名 | - |
| phone | VARCHAR | 20 | 手机号 | UNIQUE |
| password_hash | VARCHAR | 255 | 密码哈希 | - |
| invite_code | VARCHAR | 10 | 邀请码 | UNIQUE |
| last_login_at | DATETIME | - | 最后登录时间 | - |
| last_login_ip | VARCHAR | 50 | 最后登录 IP | - |
| created_at | DATETIME | - | 创建时间 | - |
| updated_at | DATETIME | - | 更新时间 | - |

#### capsules 表

| 字段 | 类型 | 长度 | 说明 | 索引 |
|------|------|------|------|------|
| id | VARCHAR | 36 | 胶囊 ID | PRIMARY |
| user_id | VARCHAR | 36 | 用户 ID | INDEX |
| type | VARCHAR | 50 | 类型 | - |
| media_type | VARCHAR | 50 | 媒体类型 | - |
| title | VARCHAR | 255 | 标题 | - |
| content | TEXT | - | 内容 | - |
| media_url | VARCHAR | 512 | 媒体 URL | - |
| open_at | DATETIME | - | 开启时间 | INDEX |
| is_opened | TINYINT | 1 | 是否已开启 | - |
| cloud_backup_status | ENUM | - | 云备份状态 | INDEX |
| cloud_backup_at | DATETIME | - | 云备份时间 | - |
| created_at | DATETIME | - | 创建时间 | - |
| updated_at | DATETIME | - | 更新时间 | - |

#### will_modules 表

| 字段 | 类型 | 长度 | 说明 | 索引 |
|------|------|------|------|------|
| id | VARCHAR | 36 | 模块 ID | PRIMARY |
| user_id | VARCHAR | 36 | 用户 ID | INDEX |
| type | VARCHAR | 50 | 类型 | - |
| title | VARCHAR | 255 | 标题 | - |
| subtitle | VARCHAR | 255 | 副标题 | - |
| content | TEXT | - | 内容 | - |
| media_url | VARCHAR | 512 | 媒体 URL | - |
| is_completed | TINYINT | 1 | 是否完成 | INDEX |
| cloud_backup_status | ENUM | - | 云备份状态 | INDEX |
| created_at | DATETIME | - | 创建时间 | - |
| updated_at | DATETIME | - | 更新时间 | - |

---

## 19. API 完整参考

### 19.1 GraphQL Schema

#### Query 类型

```graphql
type Query {
  # 获取当前用户信息
  user: UserResponse!
  
  # 获取胶囊列表
  capsules(limit: Int = 50, offset: Int = 0): CapsuleListResponse!
  
  # 获取遗嘱模块列表
  willModules: WillModuleListResponse!
  
  # 获取资产列表
  assets: AssetListResponse!
  
  # 获取见证人列表
  witnesses: WitnessListResponse!
  
  # 获取家人列表
  familyMembers: FamilyMemberListResponse!
  
  # 获取紧急联系人列表
  emergencyContacts: EmergencyContactListResponse!
  
  # 获取签到状态
  checkInStatus: CheckInStatusResponse!
  
  # 获取服务器配置
  serverConfig: ServerConfigResponse!
}
```

#### Mutation 类型

```graphql
type Mutation {
  # 发送短信验证码
  sendSmsCode(phone: String!, type: SmsType!): SmsCodeResponse!
  
  # 登录
  login(phone: String!, code: String!): AuthResponse!
  
  # 注册
  register(phone: String!, code: String!, name: String!): AuthResponse!
  
  # 退出登录
  logout: LogoutResponse!
  
  # 创建胶囊
  createCapsule(input: CreateCapsuleInput!): CapsuleResponse!
  
  # 更新胶囊
  updateCapsule(id: ID!, input: UpdateCapsuleInput!): CapsuleResponse!
  
  # 删除胶囊
  deleteCapsule(id: ID!): DeleteResponse!
  
  # 绑定家人 (邀请码)
  bindFamilyByInviteCode(inviteCode: String!): FamilyBindResponse!
  
  # 接受家人邀请
  acceptFamilyInvite(memberId: ID!): FamilyMemberResponse!
  
  # 拒绝家人邀请
  rejectFamilyInvite(memberId: ID!): FamilyMemberResponse!
  
  # 移除家人
  removeFamilyMember(memberId: ID!): DeleteResponse!
  
  # 添加紧急联系人
  addEmergencyContact(input: AddEmergencyContactInput!): EmergencyContactResponse!
  
  # 更新紧急联系人
  updateEmergencyContact(id: ID!, input: UpdateEmergencyContactInput!): EmergencyContactResponse!
  
  # 删除紧急联系人
  deleteEmergencyContact(id: ID!): DeleteResponse!
  
  # 签到
  checkIn: CheckInResponse!
}
```

### 19.2 查询示例

#### 获取用户完整信息

```graphql
query {
  user {
    success
    data {
      id
      name
      phone
      avatarUrl
      inviteCode
      lastLoginAt
      stats {
        capsulesCount
        willsCount
        assetsCount
        checkInStreak
        familyMembersCount
        emergencyContactsCount
      }
      emergencyContacts {
        id
        name
        relationship
        phone
      }
    }
  }
}
```

#### 获取胶囊列表 (分页)

```graphql
query {
  capsules(limit: 20, offset: 0) {
    success
    data {
      capsules {
        id
        title
        type
        mediaType
        sendDate
        isSent
        cloudBackupStatus
        createdAt
      }
      total
      hasMore
    }
  }
}
```

#### 创建胶囊

```graphql
mutation($input: CreateCapsuleInput!) {
  createCapsule(input: $input) {
    success
    message
    data {
      id
      title
      type
      sendDate
      createdAt
    }
  }
}

// 变量
{
  "input": {
    "title": "给未来的自己",
    "type": "text",
    "content": "希望你一切都好...",
    "sendDate": "2027-01-01T00:00:00Z"
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
      members {
        id
        name
        phone
        relation
        status
      }
      invited {
        id
        name
        phone
        relation
        status
      }
    }
  }
}
```

### 19.3 REST API

#### GET /api/version.php - 版本检测

**响应**:
```json
{
  "success": true,
  "data": {
    "ios": {
      "version": "1.0.0",
      "build": "1",
      "minVersion": "1.0.0",
      "updateUrl": "https://apps.apple.com/app/idxxx",
      "description": "Bug 修复和性能优化",
      "forceUpdate": false
    },
    "android": {
      "version": "1.0.0",
      "build": "1",
      "minVersion": "1.0.0",
      "updateUrl": "",
      "description": "Bug 修复和性能优化",
      "forceUpdate": false
    }
  },
  "serverTime": "2026-04-04 16:00:00"
}
```

#### POST /api/sms/send.php - 发送验证码

**请求**:
```json
{
  "phone": "13800138000",
  "type": "login"
}
```

**响应**:
```json
{
  "success": true,
  "message": "验证码已发送",
  "data": {
    "expireIn": 300
  }
}
```

---

## 20. 故障排查指南

### 20.1 前端常见问题

#### Q4: App 启动后一直加载

**症状**: App 打开后显示加载动画，无法进入首页

**排查步骤**:
1. 检查网络连接
   ```swift
   // 控制台查看网络状态
   Logger.info("网络状态：\(NetworkMonitor.shared.isConnected)")
   ```
2. 检查 API 地址配置
   ```swift
   Logger.info("API URL: \(DataManager.apiURL)")
   ```
3. 查看控制台日志，定位卡住位置
4. 尝试重启 App 或重新安装

**解决方案**:
- 确保服务器可访问
- 检查 `AppConfig.defaultAPIURL` 配置

#### Q5: 图片/视频无法上传

**症状**: 选择媒体文件后上传失败

**排查步骤**:
1. 检查云存储配置
   ```swift
   Logger.info("云存储开关：\(CloudStorageManager.shared.isEnabled)")
   ```
2. 检查文件大小限制
   ```swift
   let maxSize = 50 * 1024 * 1024  // 50MB
   if fileSize > maxSize { /* 提示过大 */ }
   ```
3. 查看网络请求日志
4. 检查服务器存储空间

**解决方案**:
- 配置云存储 (阿里云 OSS / 腾讯云 COS)
- 确保文件大小在限制范围内

#### Q6: Token 读取失败 (-25300)

**症状**: 真机测试时 Token 无法读取，提示 `errSecItemNotFound`

**原因**: Token 未保存到 Keychain

**解决方案**:
```swift
// AuthView.swift 注册/登录成功后
KeychainManager.shared.saveToken(token)
KeychainManager.shared.saveUserId(userId)
```

#### Q7: 后台线程修改@Published 警告

**症状**: 控制台打印警告 `Publishing changes from background threads...`

**解决方案**:
```swift
// 给 ObservableObject 添加 @MainActor
@MainActor
class DataManager: ObservableObject {
    @Published var capsules: [TimeCapsule] = []
}

// 或在修改时切换到主线程
Task { @MainActor in
    self.capsules.append(newCapsule)
}
```

### 20.2 后端常见问题

#### Q8: API 返回 500 错误

**症状**: 前端请求返回 500 Internal Server Error

**排查步骤**:
1. 检查 PHP 错误日志
   ```bash
   tail -f /var/log/php/error.log
   ```
2. 检查数据库连接
   ```php
   // test-db.php
   $db = getDB();
   echo "数据库连接成功";
   ```
3. 检查 JWT Token 配置
   ```php
   // 确认 config.php 中 API_SECRET 配置正确
   echo API_SECRET;
   ```
4. 检查 GraphQL 查询语法

**解决方案**:
- 修复 PHP 语法错误
- 确保数据库连接正常
- 确认 JWT 密钥配置一致

#### Q9: 短信验证码收不到

**症状**: 点击发送验证码后，手机未收到短信

**排查步骤**:
1. 检查短信服务商配置
   ```sql
   SELECT * FROM system_config WHERE config_key LIKE 'sms_%';
   ```
2. 检查开发者模式开关
   ```sql
   SELECT config_value FROM system_config WHERE config_key = 'sms_is_development';
   ```
3. 查看短信发送日志
   ```php
   Logger::info("发送短信到：$phone", "sms");
   ```

**解决方案**:
- 开发者模式下，使用测试验证码 (默认 123456)
- 生产环境配置短信服务商 (阿里云/腾讯云)

#### Q10: 数据库连接失败

**症状**: API 返回数据库连接错误

**排查步骤**:
1. 检查数据库服务状态
   ```bash
   systemctl status mysql
   ```
2. 检查配置文件
   ```php
   // config.php
   echo DB_HOST . ':' . DB_NAME . ':' . DB_USER;
   ```
3. 测试数据库连接
   ```bash
   mysql -u root -p -e "SHOW DATABASES;"
   ```

**解决方案**:
- 启动 MySQL 服务
- 修正 config.php 配置
- 确保数据库用户权限正确

#### Q11: SQL 注入风险

**症状**: 代码审查发现 SQL 注入风险

**预防措施**:
```php
// ✅ 正确 - 使用预处理
$stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
$stmt->execute([$phone]);

// ❌ 错误 - 禁止字符串拼接
$sql = "SELECT * FROM users WHERE phone = '$phone'";
```

### 20.3 部署常见问题

#### Q12: 前端编译失败

**症状**: xcodebuild 报错

**排查步骤**:
1. 检查 Xcode 版本
   ```bash
   xcodebuild -version
   ```
2. 清理构建缓存
   ```bash
   xcodebuild clean -project 终活.xcodeproj -scheme 终活
   ```
3. 检查证书和描述文件

**解决方案**:
- 升级 Xcode 到 15.0+
- 重新下载证书和描述文件

#### Q13: 后端部署后 502

**症状**: Nginx 返回 502 Bad Gateway

**排查步骤**:
1. 检查 PHP-FPM 状态
   ```bash
   systemctl status php-fpm
   ```
2. 检查 Nginx 配置
   ```bash
   nginx -t
   ```
3. 查看 Nginx 错误日志
   ```bash
   tail -f /var/log/nginx/error.log
   ```

**解决方案**:
- 重启 PHP-FPM: `systemctl restart php-fpm`
- 修正 Nginx 配置

---

## 21. 版本历史

### 21.1 文档版本

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| 1.0.0 | 2026-04-04 | 初始版本，包含完整开发文档 | 小皮 |
| 1.0.1 | 2026-04-04 | 补充测试、错误处理、安全规范等 7 章 | 小皮 |
| 1.0.2 | 2026-04-04 | 更新开发工具规范 (前端 Xcode/后端 Claude Code) | 小皮 |
| 1.0.3 | 2026-04-04 | 完善 CI/CD、数据模型、API 参考、故障排查 | 小皮 |

### 21.2 App 版本

| 版本 | 日期 | 类型 | 变更内容 |
|------|------|------|---------|
| 1.0.0 | TBD | iOS/Android | 初始发布 |

---

## 22. 术语表

### 22.1 产品术语

| 术语 | 英文 | 说明 |
|------|------|------|
| 终活 | Zhonghuo / End-of-life Planning | 生命管理规划应用 |
| 时光胶囊 | Time Capsule | 定时发送的消息或媒体内容 |
| 家人守护 | Family Guard | 家人关联和互相关爱功能 |
| 遗嘱模块 | Will Module | 遗嘱的不同组成部分 |
| 签到 | Check-in | 每日安全打卡 |
| 邀请码 | Invite Code | 6 位家人邀请绑定码 |
| 云存储 | Cloud Storage | 阿里云 OSS / 腾讯云 COS |

### 22.2 技术术语

| 术语 | 说明 |
|------|------|
| GraphQL | API 查询语言和运行时 |
| JWT | JSON Web Token，认证令牌 |
| Keychain | iOS 安全存储系统 |
| @MainActor | Swift 并发标记，确保在主线程执行 |
| @Published | SwiftUI 数据绑定标记 |
| PDO | PHP Data Objects，数据库访问层 |
| 预处理语句 | Prepared Statement，防 SQL 注入 |
| ATS | App Transport Security，iOS 网络安全策略 |

### 22.3 角色术语

| 角色 | 说明 |
|------|------|
| 主代理 | 主要协调代理，负责任务分配和 Memory 管理 |
| 前端助手 | 负责 iOS/Swift 开发 |
| 后端助手 | 负责 PHP 开发 |
| 审查助手 | 负责代码审查 |

---

## 附录

### A. 常见问题 (FAQ)

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
**文档版本**: v1.0.3
