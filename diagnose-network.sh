#!/bin/bash

# 终活 App 网络问题诊断脚本

echo "======================================"
echo "终活 App 网络问题诊断"
echo "======================================"
echo ""

# 1. 检查服务器连通性
echo "1️⃣ 检查服务器连通性..."
ping -c 2 8.136.41.211 | grep -E "rtt|from"
echo ""

# 2. 检查端口是否开放
echo "2️⃣ 检查端口 3395..."
nc -zv 8.136.41.211 3395 2>&1 | head -3
echo ""

# 3. 测试 HTTP 请求
echo "3️⃣ 测试 HTTP 请求..."
curl -I http://8.136.41.211:3395/api/users.php 2>&1 | head -10
echo ""

# 4. 检查模拟器状态
echo "4️⃣ 检查模拟器状态..."
xcrun simctl list devices | grep -E "iPhone 17 Pro|Booted"
echo ""

# 5. 检查 App 是否安装
echo "5️⃣ 检查 App 安装状态..."
xcrun simctl listapps "iPhone 17 Pro" | grep -A 5 "zhonghuo" | head -10
echo ""

# 6. 测试 DNS 解析
echo "6️⃣ 测试 DNS 解析..."
scutil --dns | grep -A 5 "nameserver" | head -10
echo ""

# 7. 检查本地网络接口
echo "7️⃣ 检查网络接口..."
ifconfig | grep -E "inet |status" | head -10
echo ""

echo "======================================"
echo "诊断完成"
echo "======================================"
