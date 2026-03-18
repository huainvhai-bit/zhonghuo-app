#!/bin/bash

# 终活 App 登录测试 - 完全模拟 App 请求

API_URL="http://8.136.41.211:3395/api/users.php"

echo "======================================"
echo "终活 App 登录测试 - 模拟真实 App 请求"
echo "======================================"
echo ""

# 测试登录（完全模拟 App 的请求）
echo "📡 测试登录请求..."
echo "URL: $API_URL"
echo "Method: POST"
echo "Headers: Content-Type=application/json, Accept=application/json"
echo "Body: {\"action\":\"login\",\"phone\":\"13800138006\",\"login_type\":\"password\",\"password\":\"test123456\"}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "action": "login",
    "phone": "13800138006",
    "login_type": "password",
    "password": "test123456"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "📥 响应结果:"
echo "HTTP 状态码：$HTTP_CODE"
echo "响应内容:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 登录 API 正常！"
    echo ""
    echo "如果 App 显示网络错误，问题可能在:"
    echo "1. 模拟器网络配置"
    echo "2. App 的 URLSession 配置"
    echo "3. 防火墙或网络代理"
    echo "4. iOS 的 ATS (App Transport Security) 设置"
else
    echo "❌ 登录 API 异常！"
fi

echo ""
echo "======================================"
