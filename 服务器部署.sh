#!/bin/bash
# =====================================================
# 终活后端 - 服务器部署脚本
# 从 GitHub 拉取最新修复代码
# =====================================================

set -e

echo "🚀 开始部署后端代码..."
echo ""

# 网站根目录
WEB_ROOT="/www/wwwroot/zhonghuo.cn"

echo "📂 部署目录：$WEB_ROOT"
echo ""

# 检查目录
if [ ! -d "$WEB_ROOT" ]; then
    echo "❌ 错误：目录不存在 $WEB_ROOT"
    exit 1
fi

cd "$WEB_ROOT"

# ========================================
# 步骤 1: 备份当前配置
# ========================================
echo "📦 步骤 1/5: 备份当前配置..."

if [ -f "config.php" ]; then
    cp config.php "config.php.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   ✅ 已备份 config.php"
fi

# ========================================
# 步骤 2: 检查部署方式
# ========================================
echo ""
echo "📦 步骤 2/5: 检查部署方式..."

if [ -d ".git" ]; then
    echo "   ✅ 发现 Git 仓库，使用 git pull 更新"
    DEPLOY_MODE="git"
elif [ -d "backend/.git" ]; then
    echo "   ✅ 发现 backend 子目录 Git 仓库"
    DEPLOY_MODE="backend_subdir"
else
    echo "   ⚠️  未发现 Git 仓库，将重新克隆"
    DEPLOY_MODE="clone"
fi

# ========================================
# 步骤 3: 拉取代码
# ========================================
echo ""
echo "📦 步骤 3/5: 拉取最新代码..."

if [ "$DEPLOY_MODE" = "git" ]; then
    # 根目录是 Git 仓库
    git fetch origin
    git reset --hard origin/main
    echo "   ✅ 已拉取最新代码（根目录部署）"
    
elif [ "$DEPLOY_MODE" = "backend_subdir" ]; then
    # backend 子目录是 Git 仓库
    cd backend
    git fetch origin
    git reset --hard origin/main
    cd ..
    echo "   ✅ 已拉取最新代码（backend 子目录部署）"
    
elif [ "$DEPLOY_MODE" = "clone" ]; then
    # 重新克隆
    rm -rf backend
    git clone https://github.com/huainvhai-bit/zhonghuo-backend-php.git backend
    echo "   ✅ 已重新克隆代码"
fi

# ========================================
# 步骤 4: 恢复配置
# ========================================
echo ""
echo "📦 步骤 4/5: 恢复数据库配置..."

# 确保 config.php 存在且配置正确
if [ ! -f "config.php" ]; then
    cat > config.php << 'EOF'
<?php
$GLOBALS['db_host'] = 'localhost';
$GLOBALS['db_name'] = 'zhonghuo_db';
$GLOBALS['db_user'] = 'zhonghuo_user';
$GLOBALS['db_pass'] = 'Zhonghuo@2026';
$GLOBALS['app_name'] = '终活 App';
$GLOBALS['app_version'] = '2.0.0';
EOF
    echo "   ✅ 已创建 config.php"
fi

# 如果是 backend 子目录部署，也要确保 backend/config.php 存在
if [ -d "backend" ] && [ ! -f "backend/config.php" ]; then
    cat > backend/config.php << 'EOF'
<?php
$GLOBALS['db_host'] = 'localhost';
$GLOBALS['db_name'] = 'zhonghuo_db';
$GLOBALS['db_user'] = 'zhonghuo_user';
$GLOBALS['db_pass'] = 'Zhonghuo@2026';
$GLOBALS['app_name'] = '终活 App';
$GLOBALS['app_version'] = '2.0.0';
EOF
    echo "   ✅ 已创建 backend/config.php"
fi

# ========================================
# 步骤 5: 设置权限
# ========================================
echo ""
echo "📦 步骤 5/5: 设置文件权限..."

chown -R www:www .
chmod 644 config.php 2>/dev/null || true
chmod 644 backend/config.php 2>/dev/null || true
chmod 644 api/users.php 2>/dev/null || true
chmod 644 backend/api/users.php 2>/dev/null || true

echo "   ✅ 权限设置完成"

# ========================================
# 验证
# ========================================
echo ""
echo "🔍 验证部署..."

# 检查 users.php 文件大小
if [ -f "backend/api/users.php" ]; then
    USERS_FILE="backend/api/users.php"
elif [ -f "api/users.php" ]; then
    USERS_FILE="api/users.php"
else
    echo "   ❌ 找不到 users.php"
    exit 1
fi

FILE_SIZE=$(ls -lh "$USERS_FILE" | awk '{print $5}')
echo "   📄 $USERS_FILE 大小：$FILE_SIZE"

if [[ "$FILE_SIZE" =~ "7" ]]; then
    echo "   ✅ 文件大小正确（约 7KB）"
else
    echo "   ❌ 文件大小异常（应该是 7KB 左右）"
    exit 1
fi

# 测试 PHP 语法
if php -l "$USERS_FILE" > /dev/null 2>&1; then
    echo "   ✅ PHP 语法正确"
else
    echo "   ❌ PHP 语法错误"
    exit 1
fi

# ========================================
# 完成
# ========================================
echo ""
echo "========================================="
echo "✅ 部署完成！"
echo "========================================="
echo ""
echo "🧪 测试命令："
echo "   # 测试注册"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"register\",\"phone\":\"13800138099\",\"name\":\"部署测试\",\"password\":\"test123\"}'"
echo ""
echo "   # 测试登录"
echo "   curl -X POST 'http://8.136.41.211:3395/api/users.php' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"action\":\"login\",\"phone\":\"13800138006\",\"password\":\"test123456\"}'"
echo ""
echo "   # 查看数据库"
echo "   mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db \\"
echo "     -e 'SELECT id, name, phone, created_at FROM users ORDER BY created_at DESC LIMIT 5;'"
echo ""
echo "🌐 访问地址："
echo "   前端 API: http://8.136.41.211:3395/api/"
echo "   管理后台：http://8.136.41.211:3395/admin/"
echo ""
