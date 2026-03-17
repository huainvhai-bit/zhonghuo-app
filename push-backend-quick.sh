#!/bin/bash
# 后端代码推送脚本 - 需要 GitHub Token
# 用法：./push-backend-quick.sh

echo "🚀 开始推送后端代码到 GitHub..."
echo ""

# 提示输入 GitHub Token
read -p "请输入 GitHub Token: " -s GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Token 不能为空"
    echo ""
    echo "💡 如何获取 GitHub Token:"
    echo "   1. 访问 https://github.com/settings/tokens"
    echo "   2. 点击 'Generate new token (classic)'"
    echo "   3. 选择权限：repo (Full control)"
    echo "   4. 生成并复制 token"
    exit 1
fi

# SSH 到服务器并推送
expect << ENDSCRIPT
set timeout 120
spawn ssh root@8.136.41.211
expect {
    "password:" { send "Wangzi1314\r"; expect "#*" }
    timeout { puts "SSH 连接失败"; exit 1 }
}

send "cd /www/wwwroot/zhonghuo.cn\n"
expect "#*"

# 配置 git
send "git config user.email \"lishimin@example.com\"\n"
expect "#*"

send "git config user.name \"李世民的服务器\"\n"
expect "#*"

# 确保在 main 分支
send "git branch -M main 2>/dev/null\n"
expect "#*"

# 提交
send "git add -A\n"
expect "#*"

send "git commit -m \"🔧 登录模块完整修复 - 验证码 + 密码哈希\"\n"
expect {
    "nothing to commit" { }
    "#*" { }
}

# 推送
send "git push -u origin main\n"
expect {
    "Username for" {
        send "huainvhai-bit\r"
        expect "Password for"
        send "$GITHUB_TOKEN\r"
        expect {
            "Enumerating" { puts "\n📦 正在推送..." }
            "Authentication failed" { puts "\n❌ Token 无效"; exit 1 }
            timeout { puts "\n⏱️  推送超时" }
        }
    }
    "Everything up-to-date" { puts "\n✅ 代码已是最新" }
}

send "git log --oneline -1\n"
expect "#*"

send "exit\r"
expect eof
ENDSCRIPT

echo ""
echo "✅ 推送完成！"
