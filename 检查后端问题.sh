#!/bin/bash
# 在服务器上执行，检查后端问题

echo "=== 1. 检查 users.php 开头 ==="
head -15 /www/wwwroot/zhonghuo.cn/api/users.php

echo ""
echo "=== 2. 检查 SKIP_VERIFY_CODE 定义 ==="
grep -n "SKIP_VERIFY_CODE" /www/wwwroot/zhonghuo.cn/api/users.php | head -3

echo ""
echo "=== 3. 测试 PHP 语法 ==="
php -l /www/wwwroot/zhonghuo.cn/api/users.php

echo ""
echo "=== 4. 检查 config.php ==="
cat /www/wwwroot/zhonghuo.cn/config.php

echo ""
echo "=== 5. 测试数据库连接 ==="
cd /www/wwwroot/zhonghuo.cn
php -r "require 'config.php'; try { \$db = new PDO('mysql:host='.\$GLOBALS['db_host'].';dbname='.\$GLOBALS['db_name'], \$GLOBALS['db_user'], \$GLOBALS['db_pass']); echo '数据库连接成功\n'; } catch(Exception \$e) { echo '数据库连接失败：'.\$e->getMessage().'\n'; }"

echo ""
echo "=== 6. 查看 PHP 错误日志 ==="
tail -20 /www/wwwlogs/zhonghuo.cn.error.log 2>/dev/null || tail -20 /var/log/php-fpm/error.log 2>/dev/null || echo "找不到日志文件"

echo ""
echo "=== 7. 测试注册（带详细输出） ==="
curl -v -X POST "http://localhost:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"register","phone":"13800138099","name":"本地测试","password":"test123"}' 2>&1 | grep -E "HTTP/|success|error|data"
