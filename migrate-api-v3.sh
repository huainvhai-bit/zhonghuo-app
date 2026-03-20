#!/bin/bash
# 终活 App - API 路径最终修复脚本 v3
# 修复所有剩余的特殊 API 调用

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 开始修复特殊 API 调用..."

# location.php (已经在 UserManager.swift 中)
# 这个已经是独立文件，保持不变

# checkin.php (UserManager.swift 中的独立调用)
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/checkin\.php"|/api.php?action=checkin_record"|g' {} \;

# users.php (AuthView.swift 中的登录注册)
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/users\.php"|/api.php?action=user_login"|g' {} \;

# will.php?resource=asset&action=update
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/will\.php?resource=asset&action=update|/api.php?action=will_update_asset|g' {} \;

# api/upload.php
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/upload\.php|/api.php?action=upload_file|g' {} \;

echo "✅ 特殊 API 调用修复完成！"
echo ""
echo "📊 统计修改："
git diff --stat
