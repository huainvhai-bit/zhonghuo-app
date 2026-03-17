#!/bin/bash
# 在服务器上执行此脚本拉取最新代码

echo "🔄 正在拉取最新代码..."

# 进入网站目录
cd /www/wwwroot/zhonghuo.cn

# 检查是否是 git 仓库
if [ ! -d ".git" ]; then
    echo "❌ 错误：这不是一个 git 仓库"
    echo "请先执行：git init 或重新克隆仓库"
    exit 1
fi

# 拉取最新代码
git fetch origin
git reset --hard origin/main

echo "✅ 代码已更新到最新版本"
echo ""
echo "当前 commit:"
git log --oneline -1

echo ""
echo "backend 目录内容:"
ls -la backend/
