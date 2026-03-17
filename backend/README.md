# 终活 App 后端部署指南

## 📦 文件说明

- `users.php` - 用户管理 API（支持注册、登录、密码重置）
- `init_zhonghuo_db.sql` - 数据库初始化脚本
- `deploy_backend.sh` - 一键部署脚本

## 🚀 快速部署

### 1. 拉取代码
```bash
cd /www/wwwroot/zhonghuo.cn
git pull origin main
```

### 2. 初始化数据库
```bash
mysql -u root -p < backend/init_zhonghuo_db.sql
```

### 3. 部署 API
```bash
# 备份旧代码
cp api/users.php api/users.php.bak

# 部署新代码
cp backend/users.php api/users.php

# 设置权限
chown www:www api/users.php
chmod 644 api/users.php
```

### 4. 创建配置文件
```bash
cat > api/config.php << 'EOF'
<?php
// 测试模式配置
define('SKIP_VERIFY_CODE', true);  // 跳过验证码验证（开发环境）
define('DEBUG_MODE', true);         // 调试模式
EOF
```

### 5. 验证部署
```bash
# 检查 PHP 语法
php -l api/users.php

# 测试注册
curl -X POST "http://8.136.41.211:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "register",
    "phone": "13800138009",
    "name": "测试用户 9",
    "password": "test123",
    "verify_code": "123456"
  }'

# 测试登录
curl -X POST "http://8.136.41.211:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "login",
    "phone": "13800138006",
    "login_type": "password",
    "password": "test123456"
  }'

# 查看数据库
mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "SELECT * FROM users;"
```

## 📊 数据库配置

- **数据库名**：`zhonghuo_db`
- **用户名**：`zhonghuo_user`
- **密码**：`Zhonghuo@2026`
- **主机**：`localhost`

## 🧪 测试账号

| 手机号 | 密码 | 说明 |
|--------|------|------|
| 13800138006 | test123456 | 主测试账号 |
| 13800138008 | test123 | 备用测试账号 |

## ⚠️ 注意事项

1. **安全性**：
   - 生产环境应设置 `DEBUG_MODE = false`
   - 启用验证码验证
   - 修改默认数据库密码

2. **日志**：
   - API 日志：`/www/wwwlogs/zhonghuo.cn.log`
   - 错误日志：`/www/wwwlogs/zhonghuo.cn.error.log`

3. **备份**：
   - 部署前自动备份旧代码
   - 定期备份数据库：`mysqldump -u zhonghuo_user -p zhonghuo_db > backup.sql`

## 🔧 故障排查

### 问题 1：数据库连接失败
```bash
# 检查数据库是否存在
mysql -u root -p -e "SHOW DATABASES LIKE 'zhonghuo_db';"

# 检查用户权限
mysql -u root -p -e "SHOW GRANTS FOR 'zhonghuo_user'@'localhost';"
```

### 问题 2：API 返回 500 错误
```bash
# 查看错误日志
tail -50 /www/wwwlogs/zhonghuo.cn.error.log

# 检查 PHP 版本
php -v

# 检查 PDO 扩展
php -m | grep pdo_mysql
```

### 问题 3：注册成功但数据库无数据
```bash
# 检查表是否存在
mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "SHOW TABLES;"

# 检查表结构
mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "DESCRIBE users;"
```

---

*最后更新：2026-03-17*
