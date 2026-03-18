#!/bin/bash

echo "======================================"
echo "🧪 终活 App 自动签到测试流程"
echo "======================================"
echo ""
echo "步骤 1: 打开模拟器"
open -a Simulator
sleep 2

echo ""
echo "步骤 2: 打开终活 App"
xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app
sleep 2

echo ""
echo "步骤 3: 查看日志"
LOG_FILE=$(find ~/Library/Developer/CoreSimulator/Devices/7FDF5A3A-0994-4742-9831-4DAE2D832B30/data/Containers/Data/Application -name "checkin_log.txt" 2>/dev/null | head -1)

if [ -n "$LOG_FILE" ]; then
    echo ""
    echo "📋 日志内容："
    echo "======================================"
    cat "$LOG_FILE" | tail -20
    echo "======================================"
    echo ""
    
    # 检查是否登录
    if grep -q "isLoggedIn: true" "$LOG_FILE"; then
        echo "✅ 用户已登录"
        
        # 检查签到状态
        if grep -q "签到已过期" "$LOG_FILE"; then
            echo "⚠️  签到已过期！需要通知紧急联系人"
        elif grep -q "剩余时间少于 12 小时" "$LOG_FILE"; then
            echo "⚠️  需要推送签到提醒"
        elif grep -q "签到状态正常" "$LOG_FILE"; then
            echo "✅ 签到状态正常（倒计时持续运行）"
        fi
    else
        echo "❌ 用户未登录"
        echo ""
        echo "请在模拟器中登录："
        echo "  手机号：13800138006"
        echo "  密码：test123456"
        echo ""
        echo "登录后，按 Home 键，再重新打开 App"
    fi
else
    echo "❌ 日志文件未找到"
fi

echo ""
echo "======================================"
echo "💡 提示："
echo "- 登录后关闭 App 再重新打开，查看签到日志"
echo "- 日志文件：$LOG_FILE"
echo "======================================"
