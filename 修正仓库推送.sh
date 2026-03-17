#!/usr/bin/env bash
#
# 修正仓库推送 - 清理前端，推送到后端
#

set -euo pipefail

echo "🔧 修正仓库推送"
echo ""

# ========== 1. 清理前端仓库（zhonghuo-app）==========
echo "📤 步骤 1：强制推送前端仓库（清理错误提交）..."
cd /Users/lishimin/Documents/zhonghuo-app

# 强制推送
git push origin main --force

echo "✅ 前端仓库已清理"
echo ""

# ========== 2. 推送到后端仓库（zhonghuo-backend-php）==========
echo "📤 步骤 2：推送到后端仓库..."

# 检查后端目录
BACKEND_DIR="/Users/lishimin/Documents/zhonghuo-backend-php"
if [[ ! -d "$BACKEND_DIR" ]]; then
    echo "   克隆后端仓库..."
    cd /Users/lishimin/Documents
    git clone https://github.com/huainvhai-bit/zhonghuo-backend-php.git
fi

cd "$BACKEND_DIR"

# 复制后端文件
echo "   复制后端文件..."
cp /Users/lishimin/Documents/zhonghuo-app/install.php . 2>/dev/null || true
cp /Users/lishimin/Documents/zhonghuo-app/config.php . 2>/dev/null || true
cp /Users/lishimin/Documents/zhonghuo-app/database.sql . 2>/dev/null || true

if [[ -d /Users/lishimin/Documents/zhonghuo-app/api ]]; then
    cp -r /Users/lishimin/Documents/zhonghuo-app/api/* . 2>/dev/null || true
fi

# 添加并提交
echo "   提交文件..."
git add -A
git commit -m "🔧 修复配置保存问题：install.php 正确保存到 config.php

- 修复 install.php 保存位置：config.php (根目录)
- 删除已废弃的 config/database.php
- 添加完整的 API 文件 (users.php, checkin.php 等)
- 添加数据库初始化脚本 database.sql
- 添加配置检查页面 api/check-config.php

问题根源：
- 旧版 install.php 保存到 config/database.php
- API 文件读取 config.php
- 导致配置不匹配，App 无法连接数据库

修复后：
- install.php 保存到 config.php (唯一配置文件)
- API 文件正确读取 config.php
- 配置一致，连接正常"

# 推送
echo "   推送到 GitHub..."
git push origin main

echo ""
echo "✅ 完成！"
echo ""
echo "📊 推送结果："
echo "   - 前端仓库（zhonghuo-app）：已清理错误提交"
echo "   - 后端仓库（zhonghuo-backend-php）：已推送修复文件"
echo ""
echo "📋 服务器部署："
echo ""
echo "```bash"
echo "# 1. SSH 登录服务器"
echo "ssh root@8.136.41.211"
echo ""
echo "# 2. 进入应用目录"
echo "cd /www/wwwroot/zhonghuo.cn"
echo ""
echo "# 3. 拉取最新后端代码"
echo "git pull origin main"
echo ""
echo "# 4. 重新运行安装"
echo "# 访问：http://8.136.41.211:3395/install.php"
echo "```"
echo ""
