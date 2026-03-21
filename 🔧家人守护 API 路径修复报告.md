# 🔧 家人守护 API 路径修复报告

**修复时间**: 2026-03-22 00:33  
**问题**: 家人守护功能无法获取二维码和邀请码  
**状态**: ✅ 已修复并推送

---

## 问题原因

前端代码中家人守护相关的 API 调用路径错误：

**错误路径**: `/api.php?action=family_xxx`  
**正确路径**: `/api/family.php?action=xxx`

### Action 名称映射

| 前端错误 action | 后端正确 action |
|----------------|----------------|
| `family_bind` | `bind_family` |
| `family_list` | `list_family` |
| `family_get_invite_code` | `get_invite_code` |
| `family_accept` | `accept_invite` |
| `family_reject` | `reject_invite` |
| `family_remove` | `remove_family` |

---

## 修复内容

### 修复文件（4 个文件，10 处错误）

1. **BindFamilyView.swift** (2 处)
   - ✅ `api.php?action=family_bind` → `api/family.php?action=bind_family`
   - ✅ `api.php?action=family_list` → `api/family.php?action=list_family`

2. **FamilyGuardView.swift** (4 处)
   - ✅ `api.php?action=family_list` → `api/family.php?action=list_family`
   - ✅ `api.php?action=get_invite_code` → `api/family.php?action=get_invite_code` (已修复)
   - ✅ `api.php?action=family_bind` → `api/family.php?action=bind_family` (2 处)
   - ✅ `api.php?action=family_remove` → `api/family.php?action=remove_family`

3. **FamilyMemberDetailView.swift** (3 处)
   - ✅ `api.php?action=family_accept` → `api/family.php?action=accept_invite`
   - ✅ `api.php?action=family_reject` → `api/family.php?action=reject_invite`
   - ✅ `api.php?action=family_remove` → `api/family.php?action=remove_family`

4. **InviteCodeView.swift** (1 处)
   - ✅ `api.php?action=family_get_invite_code` → `api/family.php?action=get_invite_code`

---

## 测试验证

### 编译测试
```bash
xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
**结果**: ✅ BUILD SUCCEEDED

### 代码推送
```bash
git add -A && git commit -m "🔧 家人守护 API 路径修复" && git push origin main
```
**结果**: ✅ 已推送 (提交 498d26b)

---

## 服务器部署

### 部署命令
```bash
ssh root@8.136.41.211
cd /www/wwwroot/zhonghuo.cn
git pull origin main
```

### 验证测试
```bash
# 测试获取邀请码 API
curl -X GET "http://8.136.41.211:3395/api/family.php?action=get_invite_code" \
  -H "Authorization: Bearer <your_token>"

# 测试家人列表 API
curl -X GET "http://8.136.41.211:3395/api/family.php?action=list_family" \
  -H "Authorization: Bearer <your_token>"
```

---

## 功能测试清单

部署后需要测试以下功能：

- [ ] 获取我的邀请码（二维码显示）
- [ ] 手动输入邀请码绑定家人
- [ ] 查看家人列表
- [ ] 接受家人邀请
- [ ] 拒绝家人邀请
- [ ] 移除家人关系

---

## 相关文档

- 后端 API 文件：`/Users/lishimin/Documents/zhonghuo-backend-php/api/family.php`
- 前端修复文件：`BindFamilyView.swift`, `FamilyGuardView.swift`, `FamilyMemberDetailView.swift`, `InviteCodeView.swift`

---

**修复完成**: ✅ 所有家人守护 API 路径已修复并推送  
**下一步**: 部署到服务器并测试验证
