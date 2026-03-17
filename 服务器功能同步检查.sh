#!/usr/bin/env bash
#
# 终活 App - 服务器功能同步检查
#

set -euo pipefail

echo "🔍 终活 App - 服务器功能同步检查"
echo ""
echo "⚠️  由于 SSH 无法连接，请手动在服务器上执行以下命令："
echo ""

cat << 'EOF'

# ============================================
# 在服务器上执行（SSH 登录 8.136.41.211）
# ============================================

# 1. SSH 登录
ssh root@8.136.41.211

# 2. 进入应用目录
cd /www/wwwroot/zhonghuo.cn

# 3. 检查当前 Git 状态
git log --oneline -5
git status

# 4. 拉取最新后端代码
git pull origin main

# 5. 检查关键 API 文件
echo "检查 admin.php 是否有 update_checkin_interval..."
grep -n "update_checkin_interval" api/admin.php

echo "检查 checkin.php 是否有 is_auto 支持..."
grep -n "is_auto" api/checkin.php

echo "检查 users.php 是否有 last_login_ip..."
grep -n "last_login_ip" api/users.php

# 6. 如果文件不存在或内容不对，说明代码没更新
# 需要检查 Git 仓库是否正确推送

# 7. 重启 PHP-FPM
/etc/init.d/php-81-fpm restart
# 或者
systemctl restart php-fpm

# 8. 测试 API
echo "测试配置连接..."
curl http://8.136.41.211:3395/api/check-config.php

echo ""
echo "测试签到间隔更新 API..."
curl -X POST http://8.136.41.211:3395/api/admin.php \
  -H "Content-Type: application/json" \
  -d '{"action":"update_checkin_interval","user_id":"test","check_in_interval":48}'

# 9. 检查日志
tail -f /www/wwwlogs/zhonghuo.cn_error.log

EOF

echo ""
echo "============================================"
echo "📋 前端检查（在本地 Mac 上执行）"
echo "============================================"
echo ""
echo "```bash"
echo "# 1. 检查前端代码"
echo "cd /Users/lishimin/Documents/zhonghuo-app"
echo "grep -n 'updateCheckInInterval' SettingsView.swift"
echo ""
echo "# 2. 检查 UserManager"
echo "grep -n 'recordCheckIn' UserManager.swift"
echo ""
echo "# 3. 编译测试"
echo "xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build"
echo "```"
echo ""
echo "============================================"
echo "🎯 问题诊断"
echo "============================================"
echo ""
echo "可能的问题："
echo "1. ❌ 服务器代码未更新（Git pull 失败）"
echo "2. ❌ PHP-FPM 未重启（缓存旧代码）"
echo "3. ❌ 数据库字段缺失（last_login_ip 等）"
echo "4. ❌ API 路由错误（admin.php 未处理）"
echo ""
echo "解决方案："
echo "1. ✅ 在服务器上执行 git pull"
echo "2. ✅ 重启 PHP-FPM"
echo "3. ✅ 检查数据库表结构"
echo "4. ✅ 测试 API 端点"
echo ""
