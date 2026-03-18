#!/bin/bash

# 查看终活 App 日志 - 实时输出

echo "🔍 正在监控终活 App 日志..."
echo "按 Ctrl+C 停止"
echo ""

log stream --predicate 'processImagePath contains "com.zhonghuo" OR eventMessage contains "终活"' --style compact --info 2>&1 | grep -E "🔵|🔑|👤|✅|❌|📝|💾|🎉|登录|Token|User"
