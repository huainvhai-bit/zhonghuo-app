#!/bin/bash
# 终活 App - API 路径迁移脚本
# 将旧 API 路径替换为新的统一入口

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔄 开始迁移 API 路径..."

# 用户认证
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/users\.php?action=login|/api.php?action=user_login|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/users\.php?action=register|/api.php?action=user_register|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/users\.php?action=validate|/api.php?action=user_validate|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/users\.php?action=get_user_info|/api.php?action=user_info|g' {} \;

# 家人守护
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=get_invite_code|/api.php?action=family_get_invite_code|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=bind_family|/api.php?action=family_bind|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=list_family|/api.php?action=family_list|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=accept_invite|/api.php?action=family_accept|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=reject_invite|/api.php?action=family_reject|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/family\.php?action=remove_family|/api.php?action=family_remove|g' {} \;

# 位置服务
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/location\.php?action=upload|/api.php?action=location_upload|g' {} \;

# 胶囊
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/capsules\.php?action=list|/api.php?action=capsule_list|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/capsules\.php?action=batch_sync|/api.php?action=capsule_batch_sync|g' {} \;

# 遗嘱
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/will\.php?action=batch_sync|/api.php?action=will_batch_sync|g' {} \;

# 紧急联系人
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/emergency_contacts\.php?action=list|/api.php?action=emergency_list|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/emergency_contacts\.php?action=batch_sync|/api.php?action=emergency_batch_sync|g' {} \;

# 见证人
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/witness\.php?action=batch_sync|/api.php?action=witness_batch_sync|g' {} \;

# 签到
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/checkin\.php?action=record|/api.php?action=checkin_record|g' {} \;

# 配置
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/config\.php|/api.php?action=config_get|g' {} \;

# 设备信息
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/device_info\.php?action=upload|/api.php?action=device_upload|g' {} \;
find . -name "*.swift" -type f ! -path "./DerivedData/*" -exec sed -i '' \
    's|/api/device_info\.php?action=get|/api.php?action=device_get|g' {} \;

echo "✅ API 路径迁移完成！"
echo ""
echo "📊 统计修改："
git diff --stat
