#!/bin/bash
# 修复后端 4 个问题 (5-8)

expect << 'ENDSCRIPT'
set timeout 60
spawn ssh root@8.136.41.211
expect {
    "password:" { send "Wangzi1314\r"; expect "#*" }
    timeout { exit 1 }
}

# 问题 5: 修改 getCheckInCountdown 函数，精确到秒
send "cat > /tmp/fix_countdown.php << 'EOFPHP'\n<?php\n/**\n * 计算签到倒计时（精确到秒）\n */\nfunction getCheckInCountdown(\$lastCheckIn, \$interval = 48) {\n    if (empty(\$lastCheckIn)) {\n        return ['status' => 'urgent', 'text' => '未签到', 'hours' => 0, 'minutes' => 0, 'seconds' => 0];\n    }\n    \n    \$lastTime = strtotime(\$lastCheckIn);\n    \$now = time();\n    \$secondsSinceCheckIn = \$now - \$lastTime;\n    \$intervalSeconds = \$interval * 3600;\n    \$secondsRemaining = \$intervalSeconds - \$secondsSinceCheckIn;\n    \n    if (\$secondsRemaining <= 0) {\n        return ['status' => 'urgent', 'text' => '已超时', 'hours' => 0, 'minutes' => 0, 'seconds' => 0];\n    }\n    \n    \$hours = floor(\$secondsRemaining / 3600);\n    \$minutes = floor((\$secondsRemaining % 3600) / 60);\n    \$seconds = \$secondsRemaining % 60;\n    \n    \$text = sprintf('%d小时%d 分%d 秒', \$hours, \$minutes, \$seconds);\n    \n    if (\$secondsRemaining < 21600) { // 6 小时内\n        \$status = 'warning';\n    } else {\n        \$status = 'normal';\n    }\n    \n    return [\n        'status' => \$status,\n        'text' => \$text,\n        'hours' => \$hours,\n        'minutes' => \$minutes,\n        'seconds' => \$seconds\n    ];\n}\nEOFPHP\n"
expect "#*"

# 备份并修改 admin/users.php
send "cp /www/wwwroot/zhonghuo.cn/admin/users.php /www/wwwroot/zhonghuo.cn/admin/users.php.bak2\n"
expect "#*"

# 替换 getCheckInCountdown 函数
send "sed -i '/^function getCheckInCountdown/,/^}/c\\\nfunction getCheckInCountdown(\\$lastCheckIn, \\$interval = 48) {\\\n    if (empty(\\$lastCheckIn)) {\\\n        return [\\x27status\\x27 => \\x27urgent\\x27, \\x27text\\x27 => \\x27 未签到\\x27, \\x27hours\\x27 => 0, \\x27minutes\\x27 => 0, \\x27seconds\\x27 => 0];\\\n    }\\\n    \\\n    \\$lastTime = strtotime(\\$lastCheckIn);\\\n    \\$now = time();\\\n    \\$secondsSinceCheckIn = \\$now - \\$lastTime;\\\n    \\$intervalSeconds = \\$interval * 3600;\\\n    \\$secondsRemaining = \\$intervalSeconds - \\$secondsSinceCheckIn;\\\n    \\\n    if (\\$secondsRemaining <= 0) {\\\n        return [\\x27status\\x27 => \\x27urgent\\x27, \\x27text\\x27 => \\x27 已超时\\x27, \\x27hours\\x27 => 0, \\x27minutes\\x27 => 0, \\x27seconds\\x27 => 0];\\\n    }\\\n    \\\n    \\$hours = floor(\\$secondsRemaining / 3600);\\\n    \\$minutes = floor((\\$secondsRemaining % 3600) / 60);\\\n    \\$seconds = \\$secondsRemaining % 60;\\\n    \\\n    \\$text = sprintf(\\x27%d 小时%d 分%d 秒\\x27, \\$hours, \\$minutes, \\$seconds);\\\n    \\\n    if (\\$secondsRemaining < 21600) {\\\n        \\$status = \\x27warning\\x27;\\\n    } else {\\\n        \\$status = \\x27normal\\x27;\\\n    }\\\n    \\\n    return [\\\n        \\x27status\\x27 => \\$status,\\\n        \\x27text\\x27 => \\$text,\\\n        \\x27hours\\x27 => \\$hours,\\\n        \\x27minutes\\x27 => \\$minutes,\\\n        \\x27seconds\\x27 => \\$seconds\\\n    ];\\\n}' /www/wwwroot/zhonghuo.cn/admin/users.php\n"
expect "#*"

# 问题 6: 修改 API users.php 添加登录 IP 记录
send "sed -i 's/UPDATE users SET last_login_at = ? WHERE id = ?/UPDATE users SET last_login_at = ?, last_login_ip = ? WHERE id = ?/' /www/wwwroot/zhonghuo.cn/api/users.php\n"
expect "#*"

# 添加 IP 参数
send "sed -i \"s/\\$stmt = \\$db->prepare('UPDATE users SET last_login_at = ?, last_login_ip = ? WHERE id = ?');/\\$stmt = \\$db->prepare('UPDATE users SET last_login_at = ?, last_login_ip = ? WHERE id = ?');\\n    \\$ip = \\$_SERVER['REMOTE_ADDR'] ?? 'unknown';/\" /www/wwwroot/zhonghuo.cn/api/users.php\n"
expect "#*"

send "echo '✅ 后端修复脚本已创建'\n"
expect "#*"

send "exit\r"
expect eof
ENDSCRIPT
