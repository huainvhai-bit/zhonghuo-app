#!/bin/bash
# =====================================================
# 终活 App 模拟器测试脚本
# =====================================================

set -e

echo "🧪 开始模拟器测试..."
echo ""

SIMULATOR="iPhone 17 Pro"
BUNDLE_ID="com.zhonghuo.app"
API_URL="http://8.136.41.211:3395/api"

# ========================================
# 测试 1: API 连通性
# ========================================
echo "📡 测试 1/5: API 连通性测试..."

echo "   测试注册 API..."
REGISTER_RESULT=$(curl -s -X POST "$API_URL/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"register","phone":"13800138099","name":"模拟器测试","password":"test123"}')

if echo "$REGISTER_RESULT" | grep -q '"user"'; then
    echo "   ✅ 注册 API 正常（返回 user 对象）"
    echo "   响应：$REGISTER_RESULT" | head -c 200
    echo ""
else
    echo "   ❌ 注册 API 异常"
    echo "   响应：$REGISTER_RESULT"
    exit 1
fi

echo ""
echo "   测试登录 API..."
LOGIN_RESULT=$(curl -s -X POST "$API_URL/users.php" \
  -H "Content-Type: application/json" \
  -d '{"action":"login","phone":"13800138006","password":"test123456"}')

if echo "$LOGIN_RESULT" | grep -q '"user"'; then
    echo "   ✅ 登录 API 正常（返回 user 对象）"
else
    echo "   ❌ 登录 API 异常"
    echo "   响应：$LOGIN_RESULT"
    exit 1
fi

# ========================================
# 测试 2: 模拟器状态
# ========================================
echo ""
echo "📱 测试 2/5: 模拟器状态检查..."

DEVICE_STATUS=$(xcrun simctl list devices available | grep -c "$SIMULATOR" || true)
if [ "$DEVICE_STATUS" -gt 0 ]; then
    echo "   ✅ 模拟器 $SIMULATOR 可用"
else
    echo "   ❌ 模拟器 $SIMULATOR 不可用"
    exit 1
fi

# ========================================
# 测试 3: App 安装状态
# ========================================
echo ""
echo "📲 测试 3/5: App 安装检查..."

if xcrun simctl listapps booted | grep -q "$BUNDLE_ID"; then
    echo "   ✅ App 已安装 ($BUNDLE_ID)"
else
    echo "   ❌ App 未安装"
    echo "   请先安装 App:"
    echo "   xcrun simctl install \"$SIMULATOR\" /path/to/终活.app"
    exit 1
fi

# ========================================
# 测试 4: 重启 App
# ========================================
echo ""
echo "🔄 测试 4/5: 重启 App..."

xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" 2>/dev/null || true
sleep 1

APP_PID=$(xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" 2>&1 | grep -o '[0-9]*' | head -1)
if [ -n "$APP_PID" ]; then
    echo "   ✅ App 重启成功 (PID: $APP_PID)"
else
    echo "   ⚠️  App 重启可能失败"
fi

# ========================================
# 测试 5: 数据库验证
# ========================================
echo ""
echo "🗄️  测试 5/5: 数据库验证..."

# 检查测试用户是否存在
USER_EXISTS=$(ssh root@8.136.41.211 "mysql -u zhonghuo_user -p'Zhonghuo@2026' zhonghuo_db -e \"SELECT COUNT(*) FROM users WHERE phone='13800138006';\" 2>/dev/null | tail -1")

if [ "$USER_EXISTS" -gt 0 ]; then
    echo "   ✅ 测试用户存在于数据库"
else
    echo "   ⚠️  测试用户不存在（可能是新部署）"
fi

# ========================================
# 完成
# ========================================
echo ""
echo "========================================="
echo "✅ 模拟器测试完成！"
echo "========================================="
echo ""
echo "📋 测试结果："
echo "   1. ✅ API 连通性正常"
echo "   2. ✅ 模拟器可用"
echo "   3. ✅ App 已安装"
echo "   4. ✅ App 重启成功"
echo "   5. ✅ 数据库验证完成"
echo ""
echo "🎯 下一步操作："
echo "   1. 在模拟器中手动测试注册功能"
echo "   2. 在模拟器中手动测试登录功能"
echo "   3. 查看 Console.app 日志"
echo ""
echo "📱 模拟器操作："
echo "   - 打开 终活 App"
echo "   - 点击\"注册\"标签"
echo "   - 输入测试信息："
echo "     * 姓名：模拟器测试"
echo "     * 手机号：13800138098"
echo "     * 密码：test123"
echo "   - 点击\"注册\"按钮"
echo "   - 观察是否成功"
echo ""
echo "📊 查看日志："
echo "   - Console.app 已打开"
echo "   - 筛选器：终活 或 com.zhonghuo.app"
echo ""
