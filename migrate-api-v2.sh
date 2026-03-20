#!/bin/bash
# 终活 App - API 路径完整迁移脚本 v2
# 修复所有遗漏的 API 调用

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔄 开始完整迁移 API 路径..."

# 紧急联系人
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/emergency_contacts\.php?action=add|/api.php?action=emergency_add|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/emergency_contacts\.php?action=batch_sync|/api.php?action=emergency_batch_sync|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/emergency_contacts\.php?action=list|/api.php?action=emergency_list|g' {} \;

# 签到
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/checkin\.php?action=sync|/api.php?action=checkin_sync|g' {} \;

# 胶囊
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/capsules\.php?action=batch_sync|/api.php?action=capsule_batch_sync|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/capsules\.php?action=list|/api.php?action=capsule_list|g' {} \;

# 遗嘱
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/will\.php?action=list|/api.php?action=will_list|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/will\.php?action=list_witnesses|/api.php?action=will_list_witnesses|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/will\.php?action=sync_witnesses|/api.php?action=will_sync_witnesses|g' {} \;

# 管理员
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/admin\.php?action=update_checkin_interval|/api.php?action=admin_update_checkin_interval|g' {} \;

echo "✅ API 路径完整迁移完成！"
echo ""
echo "📊 统计修改："
git diff --stat
