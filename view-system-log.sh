#!/bin/bash

echo "======================================"
echo "📋 终活 App 登录调试日志"
echo "======================================"
echo ""
echo "请在模拟器中点击登录按钮..."
echo "等待 5 秒后查看日志..."
echo ""
sleep 5

echo "🔍 系统日志（包含 API 调试信息）："
echo "======================================"
# 查看最近 2 分钟的日志，过滤 终活 App 的日志
log show --predicate 'processImagePath contains "终活" OR processImagePath contains "com.zhonghuo"' --last 2m --info 2>/dev/null | grep -E "🔍|📤|📥|❌|✅|API|URL|404" | tail -30

echo "======================================"
echo ""
echo "💡 如果看不到日志，请打开 Xcode → Window → Devices and Simulators → 选择模拟器 → 查看设备日志"
