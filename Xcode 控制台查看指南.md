# 📖 Xcode 控制台查看指南 - 图文版

## 🎯 目标
查看终活 App 登录时的详细日志，诊断登录问题

---

## 📋 步骤 1: 打开 Xcode

1. 打开 **Spotlight**（按 `Cmd + Space`）
2. 输入 `Xcode`
3. 按 `Enter` 打开

**或者**：
- 打开 Finder
- 前往「应用程序」
- 双击 `Xcode.app`

---

## 📋 步骤 2: 打开 Devices and Simulators

### 方法 1: 使用快捷键（推荐）
在 Xcode 激活状态下，按：
```
Cmd + Shift + 2
```

### 方法 2: 通过菜单
1. 点击顶部菜单栏的 **Window**
2. 选择 **Devices and Simulators**

![Xcode Window 菜单](https://via.placeholder.com/400x200?text=Window+Menu+->+Devices+and+Simulators)

---

## 📋 步骤 3: 选择 iPhone 17 Pro

在打开的窗口中：
1. 左侧边栏找到 **Simulators** 部分
2. 点击 **iPhone 17 Pro**
3. 右侧会显示模拟器信息

![Devices Window](https://via.placeholder.com/600x400?text=Select+iPhone+17+Pro)

---

## 📋 步骤 4: 打开控制台

### 方法 1: 右键菜单
1. 在 **iPhone 17 Pro** 上右键点击
2. 选择 **Open Console**

### 方法 2: 底部按钮
1. 查看窗口底部
2. 点击 **Open Console** 按钮

### 方法 3: 快捷键
选中 iPhone 17 Pro 后，按：
```
Cmd + L
```

![Open Console](https://via.placeholder.com/400x300?text=Right+Click+->+Open+Console)

---

## 📋 步骤 5: 查看控制台日志

控制台窗口打开后，你会看到：
- 左侧：设备列表（确保选择了 iPhone 17 Pro）
- 右侧：实时日志流
- 顶部：搜索框、过滤选项

**重要设置**：
1. 确保顶部的 **Activity** 选择为 **All Activity**
2. 确保 **Level** 选择为 **All**
3. 点击 🔴 **Clear** 按钮清空旧日志

![Console Window](https://via.placeholder.com/800x500?text=Console+Window+with+Logs)

---

## 📋 步骤 6: 在模拟器中登录

1. 切换到模拟器窗口
2. 打开「终活」App
3. 输入测试账号：
   - 手机号：`13800138008`
   - 密码：`test123`
4. 点击「登录」按钮

---

## 📋 步骤 7: 查看登录日志

### ✅ 成功的日志（期望看到）
```
🔵 开始登录流程...
  phone: 13800138008
  loginType: password
✅ API 已就绪
🌐 请求 URL: http://8.136.41.211:3395/api/users.php
📡 发送请求...
  HTTP 状态码：200
✅ JSON 解析成功
  success: true
✅ 用户数据已加载：测试用户
登录成功！
```

### ❌ 可能的错误日志

#### 网络错误
```
❌ 登录失败：Error Domain=NSURLErrorDomain Code=-1009
  错误描述：The Internet connection appears to be offline.
```

#### 404 错误
```
❌ 404 错误 - 服务器找不到 API 文件
  响应内容：<html><body>404</body></html>
```

#### JSON 解析错误
```
❌ JSON 解析失败：The data couldn't be read because it isn't in the correct format.
  原始响应：{...}
```

#### 服务器错误
```
❌ HTTP 错误：500
  响应内容：Internal Server Error
```

---

## 📋 步骤 8: 复制日志

1. 在控制台中选中相关日志
2. 按 `Cmd + C` 复制
3. 粘贴到聊天中发给我

**或者**：
1. 右键点击日志
2. 选择 **Copy**
3. 粘贴发送

---

## 🔧 故障排查

### Q1: 找不到 Devices and Simulators 窗口
**解决**：
- 确保 Xcode 完全启动
- 检查 Xcode 是否已打开项目
- 重启 Xcode 再试

### Q2: 控制台没有日志
**解决**：
- 确保选择了正确的设备（iPhone 17 Pro）
- 点击 🔴 **Clear** 清空旧日志
- 重新启动 App

### Q3: 模拟器打不开
**解决**：
```bash
xcrun simctl shutdown "iPhone 17 Pro"
xcrun simctl boot "iPhone 17 Pro"
```

### Q4: 日志太多看不清
**解决**：
- 使用顶部搜索框，输入关键词如「登录」
- 使用过滤器，只显示 Error 级别
- 先清空日志，再执行登录操作

---

## 📞 需要帮助？

**请提供**：
1. 控制台的完整日志（复制粘贴）
2. 或者控制台截图
3. App 显示的错误信息
4. 登录步骤（输入了什么，点击了哪里）

---

**最后更新**：2026-03-17 17:15  
**版本**：终活 v2.0 ✅
