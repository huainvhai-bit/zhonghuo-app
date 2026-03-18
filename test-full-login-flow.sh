#!/bin/bash

# 终活 App 完整登录流程测试

API_URL="http://8.136.41.211:3395/api/users.php"

echo "======================================"
echo "终活 App 完整登录流程测试"
echo "======================================"
echo ""

# 测试 1: 密码登录（主流程）
echo "📡 测试 1: 密码登录（主流程）"
echo "------------------------------------"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"action":"login","phone":"13800138006","login_type":"password","password":"test123456"}')

echo "请求：POST $API_URL"
echo "Body: {\"action\":\"login\",\"phone\":\"13800138006\",\"login_type\":\"password\",\"password\":\"test123456\"}"
echo "响应：$RESPONSE"
echo ""

# 检查是否成功
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ 密码登录成功！"
else
    echo "❌ 密码登录失败"
fi
echo ""

# 测试 2: 验证码登录
echo "📡 测试 2: 验证码登录"
echo "------------------------------------"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"action":"login","phone":"13800138006","login_type":"verify_code","verify_code":"123456"}')

echo "请求：POST $API_URL"
echo "Body: {\"action\":\"login\",\"phone\":\"13800138006\",\"login_type\":\"verify_code\",\"verify_code\":\"123456\"}"
echo "响应：$RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ 验证码登录成功！"
else
    echo "❌ 验证码登录失败"
fi
echo ""

# 测试 3: 发送验证码
echo "📡 测试 3: 发送验证码"
echo "------------------------------------"
SMS_URL="http://8.136.41.211:3395/api/sms.php"
RESPONSE=$(curl -s -X POST "$SMS_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"action":"send","phone":"13800138006","type":"login"}')

echo "请求：POST $SMS_URL"
echo "Body: {\"action\":\"send\",\"phone\":\"13800138006\",\"type\":\"login\"}"
echo "响应：$RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ 发送验证码成功！"
else
    echo "❌ 发送验证码失败"
fi
echo ""

# 测试 4: 注册
echo "📡 测试 4: 注册新用户"
echo "------------------------------------"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"action":"register","name":"测试用户","phone":"13800138009","password":"test123"}')

echo "请求：POST $API_URL"
echo "Body: {\"action\":\"register\",\"name\":\"测试用户\",\"phone\":\"13800138009\",\"password\":\"test123\"}"
echo "响应：$RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ 注册成功！"
else
    echo "❌ 注册失败"
fi
echo ""

echo "======================================"
echo "测试完成"
echo "======================================"
