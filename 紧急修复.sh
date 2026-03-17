#!/bin/bash
# =====================================================
# 终活后端紧急修复脚本
# 修复 API 返回测试数据问题
# =====================================================

set -e

echo "🚨 开始紧急修复..."
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 root 权限运行此脚本"
    exit 1
fi

# 网站根目录
WEB_ROOT="/www/wwwroot/zhonghuo.cn"

echo "📂 网站目录：$WEB_ROOT"
echo ""

# 检查目录结构
if [ -d "$WEB_ROOT/backend" ]; then
    echo "✅ 发现 backend 目录"
    BACKEND_DIR="$WEB_ROOT/backend"
elif [ -d "$WEB_ROOT/api" ]; then
    echo "✅ 发现 api 目录（根目录部署）"
    BACKEND_DIR="$WEB_ROOT"
else
    echo "❌ 错误：找不到后端目录"
    exit 1
fi

echo ""
echo "🔧 步骤 1/3: 修复 API 文件..."

# 备份当前 users.php
if [ -f "$BACKEND_DIR/api/users.php" ]; then
    cp "$BACKEND_DIR/api/users.php" "$BACKEND_DIR/api/users.php.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   ✅ 已备份 users.php"
fi

# 如果有 backup 文件，恢复它
if [ -f "$BACKEND_DIR/api/users.php.backup" ] && [[ ! "$BACKEND_DIR/api/users.php.backup" =~ \.[0-9]{8} ]]; then
    cp "$BACKEND_DIR/api/users.php.backup" "$BACKEND_DIR/api/users.php"
    echo "   ✅ 已恢复 users.php.backup"
else
    echo "   ⚠️  没有可用的 backup 文件"
fi

echo ""
echo "📝 步骤 2/3: 修复数据库配置..."

# 修复 config.php
cat > "$BACKEND_DIR/config.php" << 'EOF'
<?php
/**
 * 终活 App 后端数据库配置
 */

// 数据库配置
$GLOBALS['db_host'] = 'localhost';
$GLOBALS['db_name'] = 'zhonghuo_db';
$GLOBALS['db_user'] = 'zhonghuo_user';
$GLOBALS['db_pass'] = 'Zhonghuo@2026';

// 应用配置
$GLOBALS['app_name'] = '终活 App';
$GLOBALS['app_version'] = '2.0.0';
EOF

echo "   ✅ 已修复 config.php"

echo ""
echo "🔧 步骤 3/3: 修复 admin 后台表名..."

# 修复 admin/users.php 表名
if [ -f "$BACKEND_DIR/admin/users.php" ]; then
    sed -i 's/FROM check_ins ci/FROM check_in_records ci/g' "$BACKEND_DIR/admin/users.php"
    sed -i 's/FROM wills w/FROM will_templates w/g' "$BACKEND_DIR/admin/users.php"
    echo "   ✅ 已修复 admin/users.php"
else
    echo "   ⚠️  admin/users.php 不存在"
fi

echo ""
echo "🔍 验证修复..."

# 检查 PHP 语法
if php -l "$BACKEND_DIR/api/users.php" > /dev/null 2>&1; then
    echo "   ✅ api/users.php 语法正确"
else
    echo "   ❌ api/users.php 语法错误"
fi

# 检查文件权限
chown -R www:www "$BACKEND_DIR"
chmod 644 "$BACKEND_DIR/api/users.php"
chmod 644 "$BACKEND_DIR/config.php"
echo "   ✅ 权限设置完成"

echo ""
echo "========================================="
echo "✅ 修复完成！"
echo "========================================="
echo ""
echo "📂 修复目录：$BACKEND_DIR"
echo ""
echo "🧪 测试命令："
echo "   # 测试注册"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"register\",\"phone\":\"13800138009\",\"name\":\"测试 9\",\"password\":\"test123\"}'"
echo ""
echo "   # 测试登录"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"login\",\"phone\":\"13800138006\",\"password\":\"test123456\"}'"
echo ""
echo "   # 查看数据库"
echo "   mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e 'SELECT * FROM users;'"
echo ""
echo "🌐 访问地址："
echo "   前端 API: http://8.136.41.211:3395/api/"
echo "   管理后台：http://8.136.41.211:3395/admin/"
echo ""
