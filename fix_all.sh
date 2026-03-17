#!/bin/bash
# =====================================================
# 终活后端修复脚本
# 修复所有前后端对接问题
# =====================================================

set -e

echo "🔧 开始修复终活后端..."
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 root 权限运行此脚本"
    echo "   执行：sudo bash fix_all.sh"
    exit 1
fi

BACKEND_DIR="/www/wwwroot/zhonghuo.cn/backend"

# 检查目录是否存在
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ 错误：后端目录不存在：$BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

echo "📦 步骤 1/4: 修复 API 文件..."
# 备份当前 users.php
if [ -f "api/users.php" ] && [ ! -f "api/users.php.old" ]; then
    mv api/users.php api/users.php.old
    echo "   ✅ 已备份 users.php"
fi

# 复制 backup 版本（如果存在）
if [ -f "api/users.php.backup" ]; then
    cp api/users.php.backup api/users.php
    echo "   ✅ 已恢复 users.php.backup"
else
    echo "   ⚠️  warning: users.php.backup 不存在"
fi

echo ""
echo "📝 步骤 2/4: 修复数据库配置..."

# 修复 config.php
cat > config.php << 'EOF'
<?php
/**
 * 终活 App 后端数据库配置
 */

// 数据库配置
$GLOBALS['db_host'] = 'localhost';
$GLOBALS['db_name'] = 'zhonghuo_db';       // 修复：数据库名
$GLOBALS['db_user'] = 'zhonghuo_user';     // 修复：用户名
$GLOBALS['db_pass'] = 'Zhonghuo@2026';     // 修复：密码

// 应用配置
$GLOBALS['app_name'] = '终活 App';
$GLOBALS['app_version'] = '2026';
EOF

echo "   ✅ 已修复 config.php"

echo ""
echo "🔧 步骤 3/4: 修复 admin 后台查询..."

# 修复 admin/users.php 中的表名
if [ -f "admin/users.php" ]; then
    sed -i 's/FROM check_ins ci/FROM check_in_records ci/g' admin/users.php
    sed -i 's/FROM wills w/FROM will_templates w/g' admin/users.php
    echo "   ✅ 已修复 admin/users.php 表名"
else
    echo "   ⚠️  warning: admin/users.php 不存在"
fi

echo ""
echo "📊 步骤 4/4: 验证数据库..."

# 检查数据库是否存在
if mysql -u root -p -e "USE zhonghuo_db;" 2>/dev/null; then
    echo "   ✅ 数据库 zhonghuo_db 存在"
    
    # 检查用户表
    if mysql -u root -p -e "USE zhonghuo_db; SELECT COUNT(*) FROM users;" 2>/dev/null; then
        echo "   ✅ users 表存在"
    else
        echo "   ⚠️  users 表不存在，需要运行安装脚本"
    fi
else
    echo "   ❌ 数据库 zhonghuo_db 不存在"
    echo "   请运行：mysql -u root -p < install/schema.sql"
fi

echo ""
echo "🔍 验证修复..."

# 检查 PHP 语法
if php -l api/users.php > /dev/null 2>&1; then
    echo "   ✅ api/users.php 语法正确"
else
    echo "   ❌ api/users.php 语法错误"
fi

if php -l config.php > /dev/null 2>&1; then
    echo "   ✅ config.php 语法正确"
else
    echo "   ❌ config.php 语法错误"
fi

echo ""
echo "========================================="
echo "✅ 修复完成！"
echo "========================================="
echo ""
echo "📋 修复内容："
echo "   1. 恢复 api/users.php 为完整版本"
echo "   2. 修复 config.php 数据库配置"
echo "   3. 修复 admin/users.php 表名"
echo ""
echo "🧪 测试命令："
echo "   # 测试注册"
echo "   curl -X POST 'http://8.136.41.211:3395/backend/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"register\",\"phone\":\"13800138009\",\"name\":\"测试 9\",\"password\":\"test123\"}'"
echo ""
echo "   # 测试登录"
echo "   curl -X POST 'http://8.136.41.211:3395/backend/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"login\",\"phone\":\"13800138006\",\"password\":\"test123456\"}'"
echo ""
echo "   # 查看数据库用户"
echo "   mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e 'SELECT * FROM users;'"
echo ""
echo "🌐 访问 admin 后台："
echo "   http://8.136.41.211:3395/backend/admin/"
echo ""
