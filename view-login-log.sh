#!/bin/bash

echo "======================================"
echo "📋 终活 App 登录调试日志"
echo "======================================"
echo ""
echo "等待 3 秒让日志更新..."
sleep 3
echo ""
echo "🔍 最新日志（包含 API 调试信息）："
echo "======================================"
find ~/Library/Developer/CoreSimulator/Devices -name "checkin_log.txt" -exec tail -50 {} \; 2>/dev/null | grep -E "🔍|API|URL|404|登录" | head -30
echo "======================================"
echo ""
echo "💡 如果看到 API URL 为空或错误，请告诉我"
