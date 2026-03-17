#!/bin/bash
# 终活 App 全面诊断脚本

echo "=========================================="
echo "🔍 终活 App 全面诊断"
echo "=========================================="

# 1. 后端 API 测试
echo -e "\n📡 1. 后端 API 测试"
echo "----------------------------------------"

# 测试 config.php
echo -n "   config.php: "
curl -s http://8.136.41.211:3395/api/config.php | grep -q "success" && echo "✅" || echo "❌"

# 测试注册
echo -n "   注册 API: "
curl -s -X POST http://8.136.41.211:3395/api/users.php -d 'action=register&name=测试+诊断&phone=13800138008&password=test123' | grep -q "success" && echo "✅" || echo "❌"

# 测试登录
echo -n "   登录 API: "
curl -s -X POST http://8.136.41.211:3395/api/users.php -d 'action=login&phone=13800138008&password=test123' | grep -q "success" && echo "✅" || echo "❌"

# 2. 数据库检查
echo -e "\n🗄️  2. 数据库检查"
echo "----------------------------------------"
expect << 'EOF'
set timeout 10
spawn ssh root@8.136.41.211
expect {
    "password:" { send "Wangzi1314\r"; expect "#*" }
    timeout { exit 1 }
}
send "mysql -u zhonghuo -p'wangzi1314' zhonghuo -e \"SELECT COUNT(*) as count FROM users\" 2>&1 | grep -E 'count|[0-9]+'\n"
expect "#*"
send "exit\r"
expect eof
EOF

# 3. 前端编译检查
echo -e "\n📱 3. 前端编译检查"
echo "----------------------------------------"
cd /Users/lishimin/Documents/zhonghuo-app
if [ -f "AuthView.swift" ] && [ -f "SettingsView.swift" ]; then
    echo "   源文件：✅"
else
    echo "   源文件：❌"
fi

# 4. 模拟器状态
echo -e "\n📲 4. 模拟器状态"
echo "----------------------------------------"
xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1

echo -e "\n=========================================="
echo "✅ 诊断完成"
echo "=========================================="
