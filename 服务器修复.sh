#!/bin/bash
# 终活后端 - 紧急修复脚本
# 在服务器上执行

set -e

echo "🔧 开始修复后端..."

cd /www/wwwroot/zhonghuo.cn

# 1. 检查当前 users.php 大小
echo ""
echo "📄 当前 api/users.php 大小："
ls -lh api/users.php

# 2. 备份
echo ""
echo "📦 备份当前文件..."
cp api/users.php api/users.php.old.$(date +%Y%m%d_%H%M%S)

# 3. Git 拉取
echo ""
echo "📥 从 GitHub 拉取最新代码..."
git fetch origin
git reset --hard origin/main

# 4. 验证
echo ""
echo "✅ 验证修复..."
ls -lh api/users.php

# 5. 设置权限
chown -R www:www .

# 6. 测试
echo ""
echo "🧪 测试 API..."
curl -X POST "http://localhost:3395/api/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"register","phone":"13800138099","name":"修复测试","password":"test123"}'

echo ""
echo "✅ 修复完成！"
