# 终活 App 技术开发文档

**版本**: v2.0  
**最后更新**: 2026-03-24 12:00  
**项目状态**: ✅ 生产就绪  
**文档状态**: 🔄 持续更新

---

## 📋 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [前端技术栈](#3-前端技术栈)
4. [后端技术栈](#4-后端技术栈)
5. [数据库设计](#5-数据库设计)
6. [API 接口文档](#6-api-接口文档)
7. [核心功能模块](#7-核心功能模块)
8. [管理后台](#8-管理后台)
9. [安全机制](#9-安全机制)
10. [部署指南](#10-部署指南)
11. [开发规范](#11-开发规范)
12. [故障排查](#12-故障排查)

---

## 1. 项目概述

### 1.1 产品介绍

**终活（Zhonghuo）** 是一款 end-of-life 规划应用，帮助用户提前规划身后事宜，包括遗嘱撰写、资产管理、时光胶囊、紧急联系人等功能。

### 1.2 核心功能

| 模块 | 功能描述 | 状态 |
|------|----------|------|
| 首页 | 签到、48 小时倒计时、紧急通知 | ✅ 完成 |
| 时光胶囊 | 文字/语音/视频胶囊、定时发送 | ✅ 完成 |
| 嘱托与资产 | 10+ 遗嘱模板、资产管理、PDF 导出 | ✅ 完成 |
| 家人守护 | 位置共享、邀请码、紧急联系人 | ✅ 完成 |
| 见证人 | 见证人管理、确认状态跟踪 | ✅ 完成 |
| 新手引导 | 5 屏滑动引导 | ✅ 完成 |

### 1.3 技术亮点

- **GraphQL API** - 统一查询语言，灵活高效
- **精度动画** - 查找我的 iPhone 风格位置精度提升
- **iMessage 紧急通知** - 倒计时结束自动通知紧急联系人
- **开发者模式** - 短信验证码测试模式
- **PDF 导出** - 遗嘱与资产一键导出
- **本地加密存储** - 敏感数据安全存储

### 1.4 项目仓库

- **前端**: https://github.com/huainvhai-bit/zhonghuo-app
- **后端**: https://github.com/huainvhai-bit/zhonghuo-backend-php
- **Bundle ID**: `com.zhonghuo.app`
- **前端文档**: `📖 终活 App 技术开发文档.md`
- **后端文档**: `README.md`, `📚GraphQL API 文档.md`

### 1.5 服务器信息

| 项目 | 值 |
|------|-----|
| 服务器 IP | `8.136.41.211` |
| SSH | `ssh root@8.136.41.211` |
| Web 目录 | `/www/wwwroot/zhonghuo.cn` |
| PHP 版本 | PHP 8.1-FPM |
| 数据库 | MySQL 8.0 |
| 端口 | 3395 |
| 时区 | Asia/Shanghai |

### 1.6 访问地址

| 页面 | URL |
|------|-----|
| 前端 App | iOS 模拟器/真机 |
| 后端 API | `http://8.136.41.211:3395/api/graphql.php` |
| 管理后台 | `http://8.136.41.211:3395/admin/` |
| 位置地图 | `http://8.136.41.211:3395/admin/map.php` |
| 系统统计 | `http://8.136.41.211:3395/admin/stats.php` |

---

## 2. 技术架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS App (SwiftUI)                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │   首页   │ │ 时光胶囊 │ │ 嘱托资产 │ │ 家人守护 │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS / GraphQL
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PHP Backend (API Server)                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  GraphQL API Layer                    │   │
│  │  /api/graphql.php - 统一 API 入口                     │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ 用户认证 │ │ 数据同步 │ │ 位置服务 │ │ 短信服务 │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ MySQL
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MySQL Database                            │
│  14 张核心表：users, capsules, wills, assets, locations...  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 数据流

```
用户操作 → SwiftUI View → DataManager → API Manager → GraphQL
                                                    │
                                                    ▼
                                              PHP Backend
                                                    │
                                                    ▼
                                              MySQL Database
                                                    │
                                                    ▼
                                              响应返回 → UI 更新
```

---

## 3. 前端技术栈

### 3.1 技术选型

| 技术 | 版本 | 用途 |
|------|------|------|
| Swift | 5.9+ | 开发语言 |
| SwiftUI | iOS 15+ | UI 框架 |
| Xcode | 15.0+ | 开发工具 |
| iOS 目标版本 | iOS 15.0+ | 最低兼容版本 |

### 3.2 项目结构

```
zhonghuo-app/
├── ZhonghuoApp.swift          # App 入口
├── ContentView.swift          # 主界面（TabView）
├── Models.swift               # 数据模型定义
├── DataManager.swift          # 数据管理（单例）
├── UserManager.swift          # 用户管理（API 调用）
├── AuthView.swift             # 登录/注册界面
├── OnboardingView.swift       # 新手引导
│
├── # 核心功能模块
├── HomeStatusView.swift       # 首页（签到、倒计时）
├── TimeCapsuleView.swift      # 时光胶囊
├── WillAssetsView.swift       # 遗嘱与资产
├── FamilyGuardView.swift      # 家人守护
│
├── # 子功能模块
├── EmergencyContactsView.swift    # 紧急联系人
├── WitnessView.swift              # 见证人
├── InviteCodeView.swift           # 邀请码
├── BindFamilyView.swift           # 绑定家人
├── SettingsView.swift             # 设置
│
├── # 工具类
├── MessageManager.swift           # iMessage 管理
├── NotificationManager.swift      # 通知管理
├── PDFGenerator.swift             # PDF 导出
├── MediaRecorderView.swift        # 录音录像
├── QRCodeScannerView.swift        # 二维码扫描
├── DeviceMonitor.swift            # 设备监控
└── Info.plist                     # 配置文件
```

### 3.3 核心组件说明

#### 3.3.1 DataManager（数据管理单例）

```swift
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // 服务器配置
    static let apiURL = "http://8.136.41.211:3395"
    
    // 本地数据
    @Published var currentUser: User?
    @Published var capsules: [TimeCapsule] = []
    @Published var willModules: [WillModule] = []
    @Published var assets: [Asset] = []
    
    // 数据持久化方法
    func saveCapsules()
    func loadCapsules()
    func syncWithServer()
}
```

#### 3.3.2 UserManager（用户 API 管理）

```swift
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // 用户认证
    func login(phone: String, code: String) async
    func register(phone: String, code: String) async
    func sendSmsCode(phone: String, scene: String) async
    
    // 数据同步
    func syncCapsules() async
    func syncWillModules() async
    func uploadLocation(latitude: Double, longitude: Double) async
    
    // 家人相关
    func getInviteCode() async
    func bindFamily(inviteCode: String) async
}
```

### 3.4 数据模型（Models.swift）

#### 核心模型

```swift
// 用户
struct User: Codable {
    var id: String
    var name: String
    var phone: String
    var token: String
    var checkInInterval: CheckInInterval
}

// 时光胶囊
struct TimeCapsule: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var type: CapsuleType  // 文字/语音/视频
    var mediaURL: String
    var sendDate: Date
    var isSent: Bool
}

// 遗嘱模块
struct WillModule: Identifiable, Codable {
    var id: String
    var type: WillType  // 财产分配/继承人指定/...
    var title: String
    var content: String
    var isCompleted: Bool
}

// 资产
struct Asset: Identifiable, Codable {
    var id: String
    var type: AssetType  // 银行存款/股票/房产/...
    var name: String
    var accountNumber: String
    var value: Double
}

// 紧急联系人
struct EmergencyContact: Identifiable, Codable {
    var id: String
    var name: String
    var phone: String
    var relationship: String
}

// 见证人
struct WillWitness: Identifiable, Codable {
    var id: String
    var name: String
    var phone: String
    var isConfirmed: Bool
}
```

---

## 4. 后端技术栈

### 4.1 技术选型

| 技术 | 版本 | 用途 |
|------|------|------|
| PHP | 8.1+ | 后端语言 |
| MySQL | 8.0+ | 数据库 |
| GraphQL | - | API 查询语言 |
| JWT | - | Token 认证 |
| PHP-FPM | 8.1 | 进程管理器 |

### 4.2 项目结构

```
zhonghuo-backend-php/
├── index.php                    # 首页
├── database.sql                 # 数据库初始化脚本
├── config.example.php           # 配置示例
├── graphql-patch.php            # GraphQL 补丁
│
├── api/                         # API 目录
│   ├── graphql.php              # GraphQL 统一入口
│   ├── core.php                 # 核心函数
│   ├── check-config.php         # 配置检查
│   ├── config_get.php           # 获取配置
│   └── sms.php                  # 短信服务
│
├── admin/                       # 管理后台
│   ├── index.php                # 后台首页
│   ├── map.php                  # 位置地图
│   ├── users.php                # 用户管理
│   └── ...                      # 其他管理页面
│
├── install/                     # 安装向导
│   ├── index.php                # 安装入口
│   └── .lock                    # 安装锁定文件
│
└── cron/                        # 定时任务
    └── check-offline.php        # 离线检查
```

### 4.3 GraphQL API 层

#### 4.3.1 API 入口

**端点**: `POST /api/graphql.php`

**请求格式**:
```json
{
  "query": "query { user { id name phone } }"
}
```

**响应格式**:
```json
{
  "data": {
    "user": {
      "id": "123",
      "name": "张三",
      "phone": "13800138000"
    }
  }
}
```

#### 4.3.2 认证方式

```
Authorization: Bearer <JWT_TOKEN>
```

#### 4.3.3 核心 Queries

| Query | 描述 | 参数 |
|-------|------|------|
| `user` | 获取当前用户信息 | 无 |
| `capsules` | 获取胶囊列表 | type（可选） |
| `wills` | 获取遗嘱列表 | 无 |
| `assets` | 获取资产列表 | 无 |
| `family` | 获取家人列表 | 无 |
| `emergencyContacts` | 获取紧急联系人 | 无 |
| `witnesses` | 获取见证人 | 无 |
| `locations` | 获取位置历史 | limit（可选） |
| `stats` | 获取统计数据 | 无 |
| `getInviteCode` | 获取邀请码 | 无 |

#### 4.3.4 核心 Mutations

| Mutation | 描述 | 参数 |
|----------|------|------|
| `createCapsule` | 创建胶囊 | title, type, content, openAt |
| `updateCapsule` | 更新胶囊 | id, title, content |
| `deleteCapsule` | 删除胶囊 | id |
| `createWill` | 创建遗嘱 | type, title, content |
| `createAsset` | 创建资产 | name, type, value |
| `uploadLocation` | 上传位置 | latitude, longitude, accuracy |
| `checkin` | 签到 | 无 |
| `sendSmsCode` | 发送验证码 | phone, scene |
| `login` | 登录 | phone, code |
| `register` | 注册 | phone, code, name |

---

## 5. 数据库设计

### 5.1 数据库表总览

| 表名 | 描述 | 核心字段 |
|------|------|----------|
| `users` | 用户表 | id, name, phone, token, checkin_count |
| `capsules` | 时光胶囊 | id, user_id, type, title, content, open_at |
| `will_modules` | 遗嘱模块 | id, user_id, type, title, content |
| `will_assets` | 资产表 | id, user_id, name, type, value |
| `witnesses` | 见证人 | id, user_id, name, phone, is_confirmed |
| `emergency_contacts` | 紧急联系人 | id, user_id, name, phone, is_guardian |
| `user_locations` | 用户位置 | id, user_id, latitude, longitude, accuracy |
| `family_relations` | 家人关系 | id, user_id, related_user_id, relation_type |
| `sms_codes` | 短信验证码 | id, phone, code, expire_at, used |
| `system_config` | 系统配置 | config_key, config_value |
| `admin_users` | 管理员 | id, username, password_hash |
| `files` | 文件表 | id, user_id, file_key, file_url |
| `login_attempts` | 登录尝试 | ip_address, username, attempt_time |
| `captcha_codes` | 验证码 | code, ip_address, used |

### 5.2 核心表结构

#### 5.2.1 users（用户表）

```sql
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    token VARCHAR(255),
    token_expires_at DATETIME,
    checkin_interval_hours INT DEFAULT 48,
    checkin_count INT DEFAULT 0,
    last_checkin_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_token (token)
);
```

#### 5.2.2 capsules（时光胶囊表）

```sql
CREATE TABLE capsules (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(50) NOT NULL COMMENT '文字/语音/视频',
    media_type VARCHAR(50) COMMENT 'text/audio/video',
    title VARCHAR(255) NOT NULL,
    content TEXT,
    media_url VARCHAR(512),
    open_at DATETIME,
    is_opened TINYINT(1) DEFAULT 0,
    opened_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_open (open_at)
);
```

#### 5.2.3 user_locations（用户位置表）

```sql
CREATE TABLE user_locations (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    accuracy DECIMAL(10,2) COMMENT '精度（米）',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_time (created_at)
);
```

### 5.3 系统配置表

```sql
-- 短信配置
INSERT INTO system_config (config_key, config_value) VALUES
('sms_is_development', '1'),      -- 开发者模式：1=开启
('sms_maintenance_mode', '1'),    -- 维护模式
('sms_test_code', '123456'),      -- 测试验证码
('sms_provider', 'aliyun');       -- 短信服务商

-- 告警配置
INSERT INTO system_config (config_key, config_value) VALUES
('alert_offline_timeout', '24'),  -- 离线超时（小时）
('alert_abnormal_distance', '100'); -- 异常距离（公里）
```

---

## 6. API 接口文档

### 6.1 用户认证 API

#### 6.1.1 发送验证码

```graphql
mutation {
  sendSmsCode(phone: "13800138000", scene: "login") {
    success
    message
    data {
      code  # 开发者模式下返回验证码
    }
  }
}
```

**响应**:
```json
{
  "data": {
    "sendSmsCode": {
      "success": true,
      "message": "验证码已发送",
      "data": {
        "code": "123456"
      }
    }
  }
}
```

#### 6.1.2 登录

```graphql
mutation {
  login(phone: "13800138000", code: "123456") {
    success
    message
    data {
      token
      user {
        id
        name
        phone
      }
    }
  }
}
```

#### 6.1.3 注册

```graphql
mutation {
  register(phone: "13800138000", code: "123456", name: "张三") {
    success
    message
    data {
      token
      user {
        id
        name
        phone
      }
    }
  }
}
```

### 6.2 签到 API

#### 6.2.1 签到

```graphql
mutation {
  checkin {
    success
    message
    data {
      isSafe
      hoursRemaining
      nextCheckIn
      checkinCount
    }
  }
}
```

### 6.3 时光胶囊 API

#### 6.3.1 获取胶囊列表

```graphql
query {
  capsules {
    id
    title
    type
    content
    mediaUrl
    openAt
    createdAt
  }
}
```

#### 6.3.2 创建胶囊

```graphql
mutation {
  createCapsule(
    title: "给未来的信"
    type: "文字"
    content: "这是内容..."
    openAt: "2027-01-01 00:00:00"
  ) {
    success
    message
    data {
      id
    }
  }
}
```

#### 6.3.3 上传胶囊媒体

```graphql
mutation {
  uploadCapsuleMedia(
    capsuleId: "xxx"
    base64: "data:audio/mp4;base64,..."
  ) {
    success
    message
    data {
      mediaUrl
    }
  }
}
```

### 6.4 位置服务 API

#### 6.4.1 上传位置

```graphql
mutation {
  uploadLocation(
    latitude: 39.9042
    longitude: 116.4074
    accuracy: 10.5
  ) {
    success
    message
  }
}
```

#### 6.4.2 获取位置历史

```graphql
query {
  locations(limit: 100) {
    id
    latitude
    longitude
    accuracy
    createdAt
  }
}
```

### 6.5 家人守护 API

#### 6.5.1 获取邀请码

```graphql
query {
  getInviteCode {
    inviteCode
    qrUrl
    expiresAt
  }
}
```

#### 6.5.2 绑定家人

```graphql
mutation {
  bindFamily(inviteCode: "ABC123") {
    success
    message
    data {
      familyMember {
        id
        name
        relationType
      }
    }
  }
}
```

---

## 7. 核心功能模块

### 7.1 首页模块

#### 功能点
- ✅ 用户签到（48 小时间隔）
- ✅ 倒计时显示
- ✅ 安全状态指示
- ✅ iMessage 紧急通知（倒计时归零时）

#### 关键代码

**HomeStatusView.swift**:
```swift
// 签到逻辑
func checkIn() {
    Task {
        let result = await UserManager.shared.checkIn()
        if result.isSafe {
            // 更新 UI
            lastCheckInDate = Date()
            hoursRemaining = result.hoursRemaining
        }
    }
}

// 倒计时归零触发 iMessage
if hoursRemaining <= 0 && !notified {
    MessageManager.shared.sendEmergencyNotification(
        contacts: emergencyContacts,
        userName: currentUser?.name ?? "用户"
    )
    notified = true
}
```

### 7.2 时光胶囊模块

#### 功能点
- ✅ 文字胶囊
- ✅ 语音胶囊（AVAudioRecorder）
- ✅ 视频胶囊（AVCaptureSession）
- ✅ 类型筛选
- ✅ 定时发送

#### 媒体录制

**MediaRecorderView.swift**:
```swift
// 录音
class AudioRecorder: ObservableObject {
    var audioRecorder: AVAudioRecorder?
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ]
        audioRecorder = try? AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.record()
    }
}

// 录像
class VideoRecorder: ObservableObject {
    var captureSession: AVCaptureSession?
    
    func startRecording() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        // 配置前置摄像头...
    }
}
```

### 7.3 遗嘱与资产模块

#### 功能点
- ✅ 10+ 遗嘱模板
- ✅ 资产管理（银行/股票/房产/...）
- ✅ PDF 导出
- ✅ 本地加密存储

#### PDF 导出

**PDFGenerator.swift**:
```swift
func exportWillToPDF(willModules: [WillModule], assets: [Asset]) -> Data {
    let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        // 绘制遗嘱内容
        // 绘制资产列表
    }
    return data
}
```

### 7.4 家人守护模块

#### 功能点
- ✅ 位置共享（精度动画）
- ✅ 邀请码生成
- ✅ 二维码展示
- ✅ 家人绑定
- ✅ 紧急联系人管理

#### 位置精度动画

**前端实现**:
```swift
// 每 3 秒上传一次位置，模拟精度提升
Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
    locationUpdateCount += 1
    let accuracy = max(10, 1000 / pow(2, Double(locationUpdateCount)))
    uploadLocation(accuracy: accuracy)
}
```

**后端地图** (OpenStreetMap + Leaflet):
```javascript
// 精度圆圈动画
L.circle(userLocation, {
    radius: accuracy,
    color: '#3b82f6',
    fillColor: '#3b82f6',
    fillOpacity: 0.3
}).addTo(map);
```

---

## 8. 管理后台

### 8.1 管理后台架构

管理后台提供完整的用户管理、数据统计、系统配置等功能。

**技术栈**:
- PHP 8.1 + HTML + CSS + JavaScript
- Leaflet.js 地图库（OpenStreetMap）
- Chart.js 数据可视化
- JWT Token 认证

### 8.2 管理后台功能模块

| 页面 | 文件 | 功能描述 |
|------|------|----------|
| 登录页 | `admin/login.php` | 管理员登录、图形验证码 |
| 仪表盘 | `admin/index.php` | 用户统计、系统状态、快速操作 |
| 用户管理 | `admin/users.php` | 用户列表、搜索、详情、编辑 |
| 用户详情 | `admin/user_detail.php` | 单个用户完整信息 |
| 用户轨迹 | `admin/user_track.php` | 用户位置历史追踪 |
| 位置地图 | `admin/map.php` | 实时位置地图（精度动画） |
| 紧急联系人 | `admin/emergency_contacts.php` | 紧急联系人管理 |
| 家人关系 | `admin/family.php` | 家人关系管理 |
| 系统设置 | `admin/settings.php` | 系统配置、短信配置 |
| 性能监控 | `admin/performance.php` | API 性能监控、慢查询 |
| 数据统计 | `admin/stats.php` | 详细统计数据 |
| 告警中心 | `admin/alerts.php` | 离线告警、异常位置告警 |

### 8.3 位置地图功能

**文件**: `admin/map.php`

**功能**:
- 实时显示所有用户位置
- 精度圆圈动画（查找我的 iPhone 风格）
- 每 5 秒自动刷新
- 点击用户标记查看详情
- 支持搜索和筛选

**技术实现**:
```javascript
// 精度圆圈
L.circle(userLocation, {
    radius: accuracy,  // 精度（米）
    color: '#3b82f6',
    fillColor: '#3b82f6',
    fillOpacity: 0.3
}).addTo(map);

// 自动刷新
setInterval(() => {
    fetch('/api/graphql.php', {
        method: 'POST',
        body: JSON.stringify({ query: '{ locations { id latitude longitude accuracy } }' })
    }).then(updateMap);
}, 5000);
```

### 8.4 管理员认证

**登录流程**:
```php
// admin/login.php
POST /admin/login.php
{
    "username": "admin",
    "password": "password123",
    "captcha": "ABCD"
}

// 验证成功
Set-Cookie: admin_token=eyJhbGc...; Path=/admin; HttpOnly

// 重定向到仪表盘
Location: /admin/index.php
```

**权限检查**:
```php
// admin/check_auth.php
require_once 'check_auth.php';
// 未登录自动跳转到登录页
```

### 8.5 系统配置管理

**可配置项**:
```sql
-- 短信配置
sms_is_development      -- 开发者模式（1=开启）
sms_provider            -- 服务商（aliyun/tencent）
sms_test_code           -- 测试验证码

-- 告警配置
alert_offline_timeout   -- 离线超时（小时）
alert_abnormal_distance -- 异常距离（公里）

-- 通知配置
notify_checkin_interval -- 签到间隔（小时）
notify_first_reminder   -- 首次提醒（小时）
```

---

## 9. 安全机制

### 9.1 认证安全

- **JWT Token**: 有效期 30 天
- **Token 刷新**: 登录后自动刷新
- **防爆破**: 登录失败 5 次锁定 30 分钟

### 9.2 数据安全

- **本地存储**: JSON 文件加密存储
- **传输加密**: HTTPS/TLS
- **敏感数据**: 密码哈希（password_hash）

### 9.3 API 安全

- **Token 验证**: 所有 API 需携带 Authorization header
- **参数校验**: 严格校验输入参数
- **SQL 注入防护**: 使用预处理语句

### 9.4 短信安全

```php
// 开发者模式开关
if ($config['sms_is_development'] == '1') {
    // 返回验证码，不发送真实短信
    return ['success' => true, 'code' => $code];
} else {
    // 调用阿里云/腾讯云发送真实短信
    sendRealSms($phone, $message);
    return ['success' => true];
}
```

---

## 10. 部署指南

### 10.1 前端部署

#### 10.1.1 编译构建

```bash
cd /Users/lishimin/Documents/zhonghuo-app

# 清理缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*

# 编译到模拟器
xcodebuild -scheme 终活 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# 安装到模拟器
xcrun simctl install "iPhone 17 Pro" \
  ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app
```

#### 10.1.2 推送到 GitHub

```bash
git add -A
git commit -m "描述"
git push origin main
```

### 10.2 后端部署

#### 10.2.1 服务器部署

```bash
# SSH 登录
ssh root@8.136.41.211

# 进入应用目录
cd /www/wwwroot/zhonghuo.cn

# 拉取最新代码
git pull origin main

# 执行数据库迁移（如有）
mysql -u zhonghuo -pzhonghuo zhonghuo < migrate-database.sql

# 重启 PHP-FPM
systemctl restart php-fpm-81

# 验证
curl http://localhost:3395/api/check-config.php
# 应返回：{"success":true,"message":"配置加载成功"}
```

#### 10.2.2 数据库初始化

```bash
# 首次安装
mysql -u root -p
CREATE DATABASE zhonghuo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'zhonghuo'@'localhost' IDENTIFIED BY 'zhonghuo';
GRANT ALL PRIVILEGES ON zhonghuo.* TO 'zhonghuo'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# 导入表结构
mysql -u zhonghuo -pzhonghuo zhonghuo < database.sql
```

### 10.3 配置检查清单

#### 后端配置
- [ ] `config/database.php` 存在且正确
- [ ] `install/.lock` 文件存在（安装后）
- [ ] PHP-FPM 运行正常
- [ ] 数据库连接正常
- [ ] API 可访问

#### 前端配置
- [ ] `DataManager.apiURL` 指向正确服务器
- [ ] 编译无错误无警告
- [ ] 模拟器/真机可正常运行

---

## 11. 开发规范

### 11.1 代码规范

#### 11.1.1 Swift 命名规范
```swift
// 类名：大驼峰
class DataManager {}

// 变量/函数：小驼峰
var currentUser: User?
func syncWithServer() {}

// 常量：大驼峰
enum CapsuleType {}

// 枚举值：小驼峰
case audio, video
```

#### 11.1.2 PHP 命名规范
```php
// 函数：小写 + 下划线
function send_sms_code() {}

// 类名：大驼峰
class UserManager {}

// 常量：大写 + 下划线
define('DB_HOST', 'localhost');
```

### 11.2 Git 提交规范

```bash
# 格式：<emoji> <类型>: <描述>

# 示例
git commit -m "🐛 修复位置上传 API 路径错误"
git commit -m "✨ 新增 iMessage 紧急通知功能"
git commit -m "🎨 优化导航栏背景色"
git commit -m "📝 更新 API 文档"
```

#### Emoji 含义

| Emoji | 含义 |
|-------|------|
| ✨ | 新功能 |
| 🐛 | Bug 修复 |
| 🎨 | UI/样式 |
| 📝 | 文档 |
| 🔧 | 配置修改 |
| 🚀 | 性能优化 |
| 🔒 | 安全相关 |
| 🗑️ | 删除代码 |

### 11.3 开发流程

```
收到需求 → 理解需求 → 审查关联性 → 提供选项（如有歧义）
    ↓
用户确认 → 执行修改 → 验证编译 → 推送 GitHub
    ↓
服务器部署 → 测试验证 → 更新文档
```

### 11.4 5 条铁律

1. **不擅作主张添加功能** - 没让添加的绝不添加
2. **修改前全面审查关联性** - 搜索所有调用处
3. **新增文件必须被调用** - 确保有入口
4. **没让删除的绝不删除** - 不能擅自删除
5. **指令模棱两可时提供选择** - 不确定时列出选项

---

## 12. 故障排查

### 12.1 常见问题（FAQ）

#### Q1: 位置上传失败？
**A**: 检查 `UserManager.swift` 中 API URL 是否为 `/api/location.php`

#### Q2: 邀请码生成失败？
**A**: 检查后端 `api/core.php` 的 error 函数是否返回 `success` 字段

#### Q3: 真机白屏？
**A**: 检查 `Info.plist` 后台任务声明，确保在 `didFinishLaunchingWithOptions` 中注册

#### Q4: 短信验证码收不到？
**A**: 检查 `system_config` 表中 `sms_is_development` 配置

### 12.2 后端诊断工具

#### 12.2.1 配置检查

```bash
# 访问配置检查 API
curl http://8.136.41.211:3395/api/check-config.php

# 预期响应
{"success":true,"message":"配置加载成功"}
```

#### 12.2.2 数据库检查

```bash
# 访问数据库检查 API
curl http://8.136.41.211:3395/api/check-db.php

# 检查表完整性
mysql -u zhonghuo -pzhonghuo zhonghuo < check-db-integrity.sql
```

#### 12.2.3 全量诊断

```bash
# 访问全量诊断 API
curl http://8.136.41.211:3395/api/diagnose-all.php

# 位置专项诊断
curl http://8.136.41.211:3395/api/diagnose-location.php
```

### 12.3 前端诊断工具

#### 12.3.1 调试模式

在 `DebugConfig.swift` 中开启调试模式：

```swift
struct DebugConfig {
    static let enableLogs = true
    static let enableMockData = false
    static let apiTimeout = 30.0
}
```

#### 12.3.2 网络诊断

```bash
# 测试 API 连通性
curl -v http://8.136.41.211:3395/api/graphql.php \
  -H "Content-Type: application/json" \
  -d '{"query": "query { user { id } }"}'
```

### 12.4 日志查看

#### 12.4.1 PHP 日志

```bash
# PHP-FPM 日志
tail -f /www/wwwlogs/php-fpm.log

# Nginx 日志
tail -f /www/wwwlogs/zhonghuo.cn.error.log
tail -f /www/wwwlogs/zhonghuo.cn.access.log
```

#### 12.4.2 MySQL 日志

```bash
# 慢查询日志
tail -f /var/log/mysql/slow.log

# 错误日志
tail -f /var/log/mysql/error.log
```

### 12.5 性能优化

#### 12.5.1 数据库优化

```sql
-- 添加索引
ALTER TABLE capsules ADD INDEX idx_user_open (user_id, open_at);
ALTER TABLE user_locations ADD INDEX idx_user_time (user_id, created_at);

-- 分析慢查询
EXPLAIN SELECT * FROM capsules WHERE user_id = 'xxx' AND open_at > NOW();
```

#### 12.5.2 API 优化

- 使用 GraphQL 按需查询，避免过度获取
- 启用查询缓存
- 批量操作代替单个操作

### 12.6 备份与恢复

#### 12.6.1 数据库备份

```bash
# 备份数据库
mysqldump -u zhonghuo -pzhonghuo zhonghuo > backup_$(date +%Y%m%d).sql

# 恢复数据库
mysql -u zhonghuo -pzhonghuo zhonghuo < backup_20260324.sql
```

#### 12.6.2 代码备份

```bash
# 备份后端代码
tar -czf backend_backup_$(date +%Y%m%d).tar.gz /www/wwwroot/zhonghuo.cn

# 备份前端代码
cd /Users/lishimin/Documents/zhonghuo-app
git bundle create frontend_backup.bundle main
```

---

## 附录

### A. 快速参考

#### A.1 常用命令速查

```bash
# 前端编译
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 前端推送
cd /Users/lishimin/Documents/zhonghuo-app
git add -A && git commit -m "描述" && git push origin main

# 后端部署
ssh root@8.136.41.211
cd /www/wwwroot/zhonghuo.cn
git pull origin main
mysql -u zhonghuo -pzhonghuo zhonghuo < migrate-database.sql
systemctl restart php-fpm-81

# 数据库备份
mysqldump -u zhonghuo -pzhonghuo zhonghuo > backup.sql
```

#### A.2 API 端点速查

| 功能 | 端点 | 方法 |
|------|------|------|
| GraphQL API | `/api/graphql.php` | POST |
| 配置检查 | `/api/check-config.php` | GET |
| 数据库检查 | `/api/check-db.php` | GET |
| 全量诊断 | `/api/diagnose-all.php` | GET |
| 位置诊断 | `/api/diagnose-location.php` | GET |
| 短信发送 | `/api/sms.php` | POST |
| 管理后台 | `/admin/` | GET |
| 位置地图 | `/admin/map.php` | GET |

#### A.3 数据模型速查

| 模型 | 核心字段 |
|------|----------|
| User | id, name, phone, token, checkInInterval |
| TimeCapsule | id, title, type, content, openAt, isSent |
| WillModule | id, type, title, content, isCompleted |
| Asset | id, type, name, value, accountNumber |
| EmergencyContact | id, name, phone, relationship, isGuardian |
| WillWitness | id, name, phone, isConfirmed, confirmedAt |

#### A.4 端口与路径

| 项目 | 值 |
|------|-----|
| Web 端口 | 3395 |
| SSH 端口 | 22 |
| MySQL 端口 | 3306 |
| 前端项目 | `/Users/lishimin/Documents/zhonghuo-app/` |
| 后端项目 | `/Users/lishimin/Documents/zhonghuo-backend-php/` |
| 服务器路径 | `/www/wwwroot/zhonghuo.cn` |

### B. 常见问题（FAQ）

#### Q1: 位置上传失败？
**A**: 检查 `UserManager.swift` 中 API URL 是否为 `/api/location.php`

#### Q2: 邀请码生成失败？
**A**: 检查后端 `api/core.php` 的 error 函数是否返回 `success` 字段

#### Q3: 真机白屏？
**A**: 检查 `Info.plist` 后台任务声明，确保在 `didFinishLaunchingWithOptions` 中注册

#### Q4: 短信验证码收不到？
**A**: 检查 `system_config` 表中 `sms_is_development` 配置

#### Q5: GraphQL 查询返回空数据？
**A**: 检查 Authorization header 是否携带有效 Token

#### Q6: 编译失败 DerivedData 缓存问题？
**A**: 执行 `rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*`

### C. 相关文档

- `/Users/lishimin/Documents/zhonghuo-app/📊前后端对接完整排查报告.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/✅前后端对接修复完成.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/📚GraphQL API 文档.md`

### C. 相关文档

- `/Users/lishimin/Documents/zhonghuo-app/📊前后端对接完整排查报告.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/✅前后端对接修复完成.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/📚GraphQL API 文档.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/📚GraphQL 使用指南.md`
- `/Users/lishimin/Documents/zhonghuo-backend-php/🚀后端部署指南.md`

### D. 项目链接

| 项目 | 链接 |
|------|------|
| 前端 GitHub | https://github.com/huainvhai-bit/zhonghuo-app |
| 后端 GitHub | https://github.com/huainvhai-bit/zhonghuo-backend-php |
| 服务器 IP | http://8.136.41.211:3395 |
| 管理后台 | http://8.136.41.211:3395/admin/ |
| 位置地图 | http://8.136.41.211:3395/admin/map.php |

### E. 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v2.0 | 2026-03-24 | 完整技术文档（12 章节） |
| v1.0 | 2026-03-15 | 初始版本（基础功能） |

---

**文档版本**: v2.0  
**最后更新**: 2026-03-24 12:00  
**文档状态**: ✅ 生产就绪  
**维护者**: 终活开发团队

**📖 终活 App 技术开发文档 - 完**
