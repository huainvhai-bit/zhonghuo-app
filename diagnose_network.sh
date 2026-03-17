#!/bin/bash

echo "=== 终活 App 网络诊断 ==="
echo ""

# 1. 测试服务器连通性
echo "1. 测试服务器连通性..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://8.136.41.211:3395/api/config.php)
echo "   HTTP 状态码：$HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ 服务器连接正常"
else
    echo "   ❌ 服务器连接失败"
fi
echo ""

# 2. 测试登录 API
echo "2. 测试登录 API..."
RESPONSE=$(curl -s -X POST http://8.136.41.211:3395/api/users.php \
  -H "Content-Type: application/json" \
  -d '{"action":"login","phone":"13233323334","password":"test123456"}')
echo "$RESPONSE" | jq -r '.success' > /dev/null 2>&1
if [ $? = 0 ]; then
    echo "   ✅ 登录 API 正常"
    echo "   响应：$(echo "$RESPONSE" | jq -r '.message')"
else
    echo "   ❌ 登录 API 异常"
    echo "   原始响应：$RESPONSE"
fi
echo ""

# 3. 检查 Info.plist
echo "3. 检查 Info.plist ATS 配置..."
grep -A 5 "NSAppTransportSecurity" Info.plist > /dev/null 2>&1
if [ $? = 0 ]; then
    echo "   ✅ ATS 配置存在"
else
    echo "   ❌ 未找到 ATS 配置"
fi
echo ""

# 4. 检查后端状态
echo "4. SSH 检查后端状态..."
expect << 'ENDSSH'
set timeout 10
spawn ssh root@8.136.41.211
expect {
    "password:" { send "Wangzi1314\r"; exp_continue }
    timeout { puts "❌ SSH 连接超时"; exit 1 }
}
expect "#" { send "php -l /www/wwwroot/zhonghuo.cn/api/users.php && echo 'PHP_OK'\n" }
expect {
    "PHP_OK" { puts "✅ PHP 语法检查通过" }
    timeout { puts "❌ PHP 检查超时" }
}
expect "#" { send "exit\r" }
expect eof
ENDSSH

echo ""
echo "=== 诊断完成 ==="
