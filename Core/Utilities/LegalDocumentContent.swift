//
//  LegalDocumentContent.swift
//  终活
//
//  App 内法律文档内容
//

import Foundation

enum LegalDocumentType: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }
}

enum LegalDocumentContent {
    static func html(for type: LegalDocumentType) -> String {
        switch type {
        case .privacy:
            return privacyHTML()
        case .terms:
            return termsHTML()
        }
    }

    private static func privacyHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>隐私政策</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.8; color: #333; background: #f5f5f7; margin: 0; padding: 16px; }
                .card { max-width: 820px; margin: 0 auto; background: #fff; border-radius: 16px; padding: 28px 24px; box-shadow: 0 8px 30px rgba(0,0,0,.08); }
                h1 { font-size: 28px; margin: 0 0 12px; color: #111; }
                h2 { font-size: 18px; margin: 24px 0 12px; color: #111; }
                p, li { font-size: 15px; }
                ul { padding-left: 22px; }
                .meta { color: #666; font-size: 13px; margin-bottom: 18px; }
                .note { background: #f3f5ff; border-left: 4px solid #6366F1; padding: 14px 16px; border-radius: 10px; }
            </style>
        </head>
        <body>
        <div class="card">
            <h1>隐私政策</h1>
            <div class="meta">更新时间：2026年4月24日 · 生效日期：2026年4月24日</div>
            <div class="note">
                本应用（简称「我们」）非常重视您的隐私和个人信息保护。本隐私政策旨在向您说明我们如何收集、使用、存储、共享和保护您的个人信息，以及您享有的相关权利。
            </div>
            <h2>一、信息收集</h2>
            <p><strong>1. 您主动提供的信息</strong></p>
            <ul>
                <li>账户信息：手机号码、昵称、头像</li>
                <li>留言内容：您主动创建的视频、语音或文字</li>
                <li>重要事项：您主动填写的个人事项记录</li>
                <li>添加用户信息：经双方确认后建立的添加关系信息</li>
            </ul>
            <p><strong>2. 您使用服务时自动收集的信息</strong></p>
            <ul>
                <li>设备信息：设备型号、操作系统版本</li>
                <li>位置信息：本版本不启用定位功能</li>
                <li>使用日志：功能使用记录、操作时间</li>
            </ul>
            <h2>二、信息使用</h2>
            <ul>
                <li>提供文字、语音、视频留言的录制、存储和手动发送服务</li>
                <li>提供重要事项记录和同步服务</li>
                <li>提供定期签到记录及本机提醒服务</li>
                <li>在您授权并双方确认后，同步展示最近一次签到时间</li>
                <li>建立和管理已确认的共享关系</li>
            </ul>
            <p><strong>重要说明：</strong>我们不会根据未签到、未操作、定位状态或其他条件自动触发外部通知、定位发送或内容发送。留言内容必须由用户主动点击发送后，添加用户才可能在 App 内查看。</p>
            <h2>三、信息存储</h2>
            <ul>
                <li>账户信息：您注销账户后，我们将删除您的个人信息</li>
                <li>留言内容：在您主动删除前保存</li>
                <li>重要事项：在您主动删除前保存</li>
            </ul>
            <h2>四、信息共享</h2>
            <ul>
                <li>添加查看：经双方确认绑定后，向对方展示最近一次同步的签到时间和已手动发送的留言内容</li>
                <li>法律要求：遵守法律法规、司法机关或监管机构的要求</li>
            </ul>
            <h2>五、您的权利</h2>
            <ul>
                <li>访问和查看您的个人信息</li>
                <li>更正不准确的个人信息</li>
                <li>删除您的个人信息</li>
                <li>撤回同意</li>
                <li>注销账户</li>
            </ul>
        </div>
        </body>
        </html>
        """
    }

    private static func termsHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>服务条款</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.8; color: #333; background: #f5f5f7; margin: 0; padding: 16px; }
                .card { max-width: 820px; margin: 0 auto; background: #fff; border-radius: 16px; padding: 28px 24px; box-shadow: 0 8px 30px rgba(0,0,0,.08); }
                h1 { font-size: 28px; margin: 0 0 12px; color: #111; }
                h2 { font-size: 18px; margin: 24px 0 12px; color: #111; }
                p, li { font-size: 15px; }
                ul { padding-left: 22px; }
                .meta { color: #666; font-size: 13px; margin-bottom: 18px; }
                .note { background: #f3f5ff; border-left: 4px solid #6366F1; padding: 14px 16px; border-radius: 10px; }
            </style>
        </head>
        <body>
        <div class="card">
            <h1>服务条款</h1>
            <div class="meta">更新时间：2026年4月24日 · 生效日期：2026年4月24日</div>
            <div class="note">
                本条款适用于本应用及其相关功能。使用本服务即表示您同意遵守本条款。
            </div>
            <h2>一、服务内容</h2>
            <ul>
                <li>文字、语音、视频留言的录制、保存与手动发送</li>
                <li>重要事项与资产信息整理</li>
                <li>签到记录、共享查看与订阅服务</li>
            </ul>
            <h2>二、使用规则</h2>
            <ul>
                <li>您应确保提交的信息真实、合法、有效</li>
                <li>您应妥善保管账号、密码、验证码与设备权限</li>
                <li>您不得利用本服务从事违法、侵权或破坏服务稳定性的行为</li>
            </ul>
            <h2>三、内容说明</h2>
            <ul>
                <li>App 内的留言、重要事项与共享内容均需由用户主动操作</li>
                <li>本服务不提供外部通知、定位发送或内容自动发送</li>
                <li>本服务仅用于个人记录与信息整理参考</li>
            </ul>
            <h2>四、订阅说明</h2>
            <ul>
                <li>订阅费用会根据 Apple 的规则进行扣费</li>
                <li>订阅会自动续期，您可在 App 内或 Apple 账户中管理订阅</li>
                <li>具体权益以 App 内展示与服务器配置为准</li>
            </ul>
            <h2>五、免责声明</h2>
            <p>在法律允许的范围内，对于因网络、设备、系统、第三方服务或不可抗力导致的服务中断、数据延迟、展示异常等情况，我们会尽力修复，但不对超出合理控制范围的后果承担责任。</p>
        </div>
        </body>
        </html>
        """
    }
}
