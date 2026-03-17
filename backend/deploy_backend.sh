#!/bin/bash
# 终活 App 后端部署脚本
# 在服务器上执行

set -e

echo "🚀 开始部署终活 App 后端..."

# 1. 初始化数据库
echo "📊 初始化数据库..."
mysql -u root -p < /tmp/init_zhonghuo_db.sql

# 2. 备份旧代码
echo "💾 备份旧代码..."
if [ -f /www/wwwroot/zhonghuo.cn/api/users.php ]; then
    cp /www/wwwroot/zhonghuo.cn/api/users.php /www/wwwroot/zhonghuo.cn/api/users.php.bak.$(date +%Y%m%d_%H%M%S)
fi

# 3. 部署新代码
echo "📦 部署新代码..."
cp /tmp/users_production.php /www/wwwroot/zhonghuo.cn/api/users.php

# 4. 设置权限
echo "🔐 设置权限..."
chown www:www /www/wwwroot/zhonghuo.cn/api/users.php
chmod 644 /www/wwwroot/zhonghuo.cn/api/users.php

# 5. 创建测试模式配置文件
echo "⚙️ 创建配置..."
cat > /www/wwwroot/zhonghuo.cn/api/config.php << 'EOF'
<?php
// 测试模式配置
define('SKIP_VERIFY_CODE', true);  // 跳过验证码验证（开发环境）
define('DEBUG_MODE', true);         // 调试模式
EOF

# 6. 验证部署
echo "✅ 验证部署..."
php -l /www/wwwroot/zhonghuo.cn/api/users.php

echo ""
echo "🎉 部署完成！"
echo ""
echo "测试账号："
echo "  手机号：13800138006"
echo "  密码：test123456"
echo ""
echo "  手机号：13800138008"
echo "  密码：test123"
