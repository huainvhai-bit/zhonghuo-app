#!/bin/bash

# 终活 App 日志查看脚本
# 实时查看模拟器的控制台输出

echo "📱 终活 App 日志查看器"
echo "======================================"
echo ""
echo "正在连接到 iPhone 17 Pro 模拟器..."
echo "按 Ctrl+C 停止"
echo ""

# 使用 log 命令查看 iOS 模拟器日志
log stream --predicate 'processImagePath contains "终活"' --info --debug 2>/dev/null | grep -E "登录 | 网络|login|network|error|请求 | 响应 |🔵|🔍|❌|✅"
