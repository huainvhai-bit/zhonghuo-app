#!/bin/bash
# 后端代码推送脚本

echo "📦 推送后端代码到 GitHub..."

# SSH 到服务器
expect << 'ENDSCRIPT'
set timeout 60
spawn ssh root@8.136.41.211
expect {
    "password:" { send "Wangzi1314\r"; expect "#*" }
    timeout { exit 1 }
}

cd /www/wwwroot/zhonghuo.cn

# 提交代码
send "git commit -m \"🔧 登录模块修复：验证码验证 + 密码哈希 + SKIP_VERIFY_CODE\"\n"
expect "#*"

# 推送代码（需要 GitHub token 或 SSH key）
send "git push -u origin main\n"
expect {
    "Password for 'https://github.com':" { 
        # 需要输入 GitHub token
        send "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\r"
        expect "#*"
    }
    "Enter passphrase for key" {
        # 需要 SSH key passphrase
        send "xxxxxxxx\r"
        expect "#*"
    }
    timeout {
        send "\x03"
    }
}

send "exit\r"
expect eof
ENDSCRIPT

echo "✅ 后端代码推送完成"
