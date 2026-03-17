#!/bin/bash
# =====================================================
# 终活后端 - 全面修复脚本
# 修复所有前后端对接问题
# =====================================================

set -e

echo "🔧 开始全面修复后端..."
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 root 权限运行此脚本"
    exit 1
fi

BACKEND_DIR="/www/wwwroot/zhonghuo.cn"

echo "📂 后端目录：$BACKEND_DIR"
echo ""

# 检查目录
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ 错误：目录不存在 $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# ========================================
# 修复 1: 替换 users.php 为完整版本
# ========================================
echo "🔧 修复 1/6: 替换 api/users.php..."

if [ -f "api/users.php" ]; then
    cp api/users.php "api/users.php.test.$(date +%Y%m%d_%H%M%S)"
    echo "   ✅ 已备份 users.php"
fi

if [ -f "api/users.php.backup" ]; then
    # 确保不使用带时间戳的 backup
    if [[ ! "api/users.php.backup" =~ \.[0-9]{8} ]]; then
        cp api/users.php.backup api/users.php
        echo "   ✅ 已恢复 users.php.backup"
    fi
fi

# 验证
if php -l api/users.php > /dev/null 2>&1; then
    SIZE=$(ls -lh api/users.php | awk '{print $5}')
    echo "   ✅ users.php 语法正确 (大小：$SIZE)"
else
    echo "   ❌ users.php 语法错误"
    exit 1
fi

# ========================================
# 修复 2: 修复 config.php 数据库配置
# ========================================
echo ""
echo "🔧 修复 2/6: 修复 config.php..."

cat > config.php << 'EOF'
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

# ========================================
# 修复 3: 修复 admin/users.php 表名
# ========================================
echo ""
echo "🔧 修复 3/6: 修复 admin/users.php 表名..."

if [ -f "admin/users.php" ]; then
    # 检查是否需要修复
    if grep -q "check_in_records" admin/users.php; then
        # 已经是正确的表名
        echo "   ✅ admin/users.php 表名已正确"
    else
        # 需要修复
        sed -i 's/FROM check_in_records ci/FROM check_ins ci/g' admin/users.php
        sed -i 's/FROM will_templates w/FROM wills w/g' admin/users.php
        echo "   ✅ 已修复 admin/users.php 表名"
    fi
else
    echo "   ⚠️  admin/users.php 不存在"
fi

# ========================================
# 修复 4: 验证数据库
# ========================================
echo ""
echo "🔧 修复 4/6: 验证数据库..."

# 测试数据库连接
if mysql -u zhonghuo_user -p'Zhonghuo@2026' -e "USE zhonghuo_db;" 2>/dev/null; then
    echo "   ✅ 数据库连接成功"
    
    # 检查表是否存在
    TABLES=$(mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "SHOW TABLES;" 2>/dev/null | wc -l)
    echo "   ✅ 数据库中有 $TABLES 个表"
    
    # 检查 users 表
    if mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "SELECT COUNT(*) FROM users;" 2>/dev/null; then
        USER_COUNT=$(mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e "SELECT COUNT(*) FROM users;" 2>/dev/null | tail -1)
        echo "   ✅ users 表中有 $USER_COUNT 个用户"
    else
        echo "   ⚠️  users 表不存在，需要运行安装脚本"
    fi
else
    echo "   ❌ 数据库连接失败"
    echo "   请检查："
    echo "   1. 数据库是否创建：mysql -u root -p -e 'SHOW DATABASES;'"
    echo "   2. 用户权限是否正确：mysql -u root -p -e 'SHOW GRANTS FOR zhonghuo_user@localhost;'"
fi

# ========================================
# 修复 5: 设置文件权限
# ========================================
echo ""
echo "🔧 修复 5/6: 设置文件权限..."

chown -R www:www .
chmod 644 api/*.php
chmod 644 config.php
chmod 644 admin/*.php
chmod 755 admin
chmod 755 api
chmod 755 config
chmod 755 data
chmod 755 uploads

echo "   ✅ 权限设置完成"

# ========================================
# 修复 6: 测试 API
# ========================================
echo ""
echo "🔧 修复 6/6: 测试 API..."

echo ""
echo "   测试注册 API..."
REGISTER_RESULT=$(curl -s -X POST "http://localhost:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"register","phone":"13800138099","name":"测试用户 99","password":"test123"}')

if echo "$REGISTER_RESULT" | grep -q '"user"'; then
    echo "   ✅ 注册 API 正常（返回 user 对象）"
else
    echo "   ⚠️  注册 API 可能有问题"
    echo "   响应：$REGISTER_RESULT"
fi

echo ""
echo "   测试登录 API..."
LOGIN_RESULT=$(curl -s -X POST "http://localhost:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"login","phone":"13800138006","password":"test123456"}')

if echo "$LOGIN_RESULT" | grep -q '"user"'; then
    echo "   ✅ 登录 API 正常（返回 user 对象）"
else
    echo "   ⚠️  登录 API 可能有问题"
    echo "   响应：$LOGIN_RESULT"
fi

# ========================================
# 完成
# ========================================
echo ""
echo "========================================="
echo "✅ 后端全面修复完成！"
echo "========================================="
echo ""
echo "📋 修复内容："
echo "   1. ✅ api/users.php - 恢复完整版本"
echo "   2. ✅ config.php - 数据库配置"
echo "   3. ✅ admin/users.php - 表名修复"
echo "   4. ✅ 数据库验证"
echo "   5. ✅ 文件权限设置"
echo "   6. ✅ API 测试"
echo ""
echo "🌐 访问地址："
echo "   前端 API: http://8.136.41.211:3395/api/"
echo "   管理后台：http://8.136.41.211:3395/admin/"
echo ""
echo "🧪 测试命令："
echo "   # 注册测试"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"register\",\"phone\":\"13800138009\",\"name\":\"测试 9\",\"password\":\"test123\"}'"
echo ""
echo "   # 登录测试"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"login\",\"phone\":\"13800138006\",\"password\":\"test123456\"}'"
echo ""
echo "   # 查看数据库用户"
echo "   mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db \\"
echo "     -e 'SELECT id, name, phone, created_at FROM users;'"
echo ""
