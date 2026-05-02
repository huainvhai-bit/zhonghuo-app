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
        <!doctype html>
        <html lang="zh-CN">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>终活 App - 隐私政策</title>
        <style>
        :root{--bg:#f7f8ff;--card:#fff;--text:#1d2433;--muted:#667085;--p:#4f46e5;--line:#e6e8f0;--soft:#eef2ff}
        *{box-sizing:border-box}
        body{margin:0;color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",Arial,sans-serif;line-height:1.78;background:linear-gradient(180deg,#fbfcff 0%,var(--bg) 42%,#fff 100%)}
        a{color:var(--p);text-decoration:none;font-weight:700}a:hover{text-decoration:underline}
        .container{width:min(920px,calc(100% - 28px));margin:0 auto;padding:18px 0 28px}
        .hero{padding:10px 0 6px}
        .badge{display:inline-block;padding:8px 14px;border-radius:999px;color:#3730a3;background:linear-gradient(135deg,rgba(79,70,229,.12),rgba(124,58,237,.10));border:1px solid rgba(79,70,229,.15);font-size:14px;font-weight:800}
        h1{margin:16px 0 10px;font-size:30px;line-height:1.1}
        .subtitle{margin:0;color:var(--muted);font-size:16px}
        .meta,.nav{display:flex;flex-wrap:wrap;gap:10px;margin-top:16px}
        .meta span{padding:8px 12px;border-radius:14px;background:#fff;border:1px solid var(--line);color:var(--muted);font-size:13px}
        .nav a{padding:10px 14px;border-radius:14px;background:#fff;border:1px solid var(--line)}
        .card{margin-top:18px;background:rgba(255,255,255,.95);border:1px solid var(--line);border-radius:22px;box-shadow:0 20px 56px rgba(38,42,86,.10);overflow:hidden}
        .notice{margin:18px;padding:16px 18px;border-radius:18px;background:linear-gradient(135deg,rgba(79,70,229,.10),rgba(124,58,237,.09));border:1px solid rgba(79,70,229,.18)}
        .content{padding:0 18px 22px}
        section{padding:20px 0;border-top:1px solid var(--line)}section:first-child{border-top:0}
        h2{margin:0 0 10px;font-size:20px;line-height:1.35}
        p{margin:8px 0;font-size:15px}
        ul{padding-left:20px;margin:8px 0}li{margin:6px 0;font-size:15px}
        .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px;margin-top:12px}
        .feature{padding:14px;border-radius:18px;background:linear-gradient(135deg,#fff,var(--soft));border:1px solid var(--line)}
        .feature b{display:block;margin-bottom:5px;color:#312e81;font-size:15px}
        .timeline{display:grid;gap:12px;margin-top:12px}
        .timeline-item{padding:14px 16px;border-radius:18px;background:#fff;border:1px solid var(--line)}
        .timeline-item strong{display:block;margin-bottom:5px;color:#312e81}
        .footer{text-align:center;color:var(--muted);font-size:13px;padding:18px 0 10px}
        @media (max-width:720px){.grid{grid-template-columns:1fr}.content{padding:0 14px 18px}.notice{margin:14px}h1{font-size:26px}}
        </style>
        </head>
        <body>
        <main class="container">
        <header class="hero">
        <div class="badge">终活 App · 隐私政策</div>
        <h1>隐私政策</h1>
        <p class="subtitle">了解终活如何收集、使用、存储和保护你的个人信息。</p>
        <div class="meta"><span>生效日期：<strong>2026年5月2日</strong></span><span>最近更新：<strong>2026年5月2日</strong></span><span>提供方：<strong>终活项目团队</strong></span></div>
        <nav class="nav"><a href="https://zhonghuo.zhonghuo.xyz/docs/index.html">技术支持</a><a href="https://zhonghuo.zhonghuo.xyz/docs/terms.html">服务条款</a><a href="mailto:support@zhonghuo.app">联系我们</a></nav>
        </header>
        <article class="card">
        <div class="notice"><strong>重要提示：</strong>终活重视你的隐私与数据安全。请在使用本 App 前仔细阅读本隐私政策。若你不同意本政策的任何内容，请停止使用本 App。</div>
        <div class="content">
        <section><h2>一、产品与适用范围</h2><p>终活是一款个人记录管理平台，帮助你整理重要信息、时光留言和本机签到提醒。</p><p>本隐私政策适用于你使用终活 App 及相关服务的全过程。</p></section>
        <section><h2>二、我们是谁</h2><p>终活 App 由<strong>终活项目团队</strong>提供。本政策中的“我们”指终活 App 及其提供方；“你”指注册、登录或使用本 App 的用户。</p><p>联系邮箱：<a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a><br>备用邮箱：<a href="mailto:huainvhai2@gmail.com">huainvhai2@gmail.com</a><br>官方网站：<a href="https://zhonghuo.zhonghuo.xyz">https://zhonghuo.zhonghuo.xyz</a></p></section>
        <section><h2>三、我们收集的信息</h2><p>为实现个人记录、手动留言、本机提醒、会员订阅和账号安全等功能，我们可能收集以下信息：</p><div class="grid">
          <div class="feature"><b>账号信息</b>手机号、账号、昵称、头像、用户 ID、登录方式。</div>
          <div class="feature"><b>内容信息</b>文字、语音、视频、图片、重要事项、资产记录等。</div>
          <div class="feature"><b>状态信息</b>签到周期、签到时间、状态记录。</div>
          <div class="feature"><b>设备与日志</b>设备型号、系统版本、App 版本、IP 地址、崩溃日志。</div>
        </div><p>当前版本不启用定位功能，也不会持续上传位置。</p></section>
        <section><h2>四、我们如何使用信息</h2><ul><li>提供、维护和改进终活 App 的基础功能与会员订阅服务；</li><li>帮助你管理时光留言、重要事项和本机签到提醒；</li><li>仅在你主动点击发送后，向你指定的用户展示已发送内容；</li><li>验证订阅状态、处理恢复购买、管理会员权益；</li><li>进行账号安全保护、异常行为排查、客服支持和故障修复；</li><li>遵守法律法规、监管要求和平台规则。</li></ul></section>
        <section><h2>五、时光留言与签到说明</h2><p>时光留言必须由用户手动创建并手动发送。系统不会因为未签到、未操作、超时或其他条件自动向任何人发送提醒、定位或内容。</p><p>本机签到提醒仅用于你自己的设备，不会自动通知任何联系人。</p></section>
        <section><h2>六、信息提供与展示</h2><p>在你明确操作或双方确认后，我们才会向你指定的用户展示最近一次签到记录或你手动发送的内容。</p><p>未经你的明确操作，我们不会自动向任何联系人发送通知、状态或位置信息。</p></section>
        <section><h2>七、会员订阅与支付</h2><p>终活可能提供自动续期订阅会员服务，例如月度会员和年度会员。会员权益、价格、周期和具体内容以 App 内展示及 App Store 购买页面为准。</p><div class="timeline">
          <div class="timeline-item"><strong>订阅与续费</strong><p>订阅将通过你的 Apple ID 账户确认并扣款；自动续期订阅会在当前周期结束时自动续订，除非你在当前周期结束前至少 24 小时取消。</p></div>
          <div class="timeline-item"><strong>取消订阅与恢复购买</strong><p>你可以在 iPhone 设置或 App Store 的订阅管理页面取消自动续费；如需同步会员状态，可使用 App 内“恢复购买”功能。</p></div>
        </div></section>
        <section><h2>八、信息存储与保护</h2><p>我们会采取合理可行的安全措施保护你的个人信息，包括访问控制、加密传输、权限管理、日志审计和安全监控。</p><p>信息存储地点：中国大陆。若涉及跨境传输，我们会根据适用法律要求采取必要保护措施。</p></section>
        <section><h2>九、信息保存期限</h2><ul><li>账号信息：通常保存至账号注销后，根据法律要求保留必要期限；</li><li>时光留言、重要事项、资产记录等用户内容：保存至你主动删除、账号注销或服务规则触发删除；</li><li>交易与订阅记录：根据支付、审计、财务和法律要求保存；</li><li>日志信息：通常仅保存排障和安全所需的合理期限。</li></ul></section>
        <section><h2>十、你的权利</h2><p>在适用法律允许的范围内，你可以访问、更正、删除、导出个人信息，撤回部分授权，注销账号，或通过 Apple 系统管理或取消订阅。</p><p>如需行使相关权利，请通过 <a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a> 或 <a href="mailto:huainvhai2@gmail.com">huainvhai2@gmail.com</a> 联系我们。我们可能需要验证你的身份后再处理请求。</p></section>
        <section><h2>十一、未成年人保护</h2><p>终活主要面向具备相应民事行为能力的成年人使用。若你是未成年人，请在监护人同意和指导下使用本 App。若我们发现未在监护人同意下收集了未成年人的个人信息，我们会依法尽快删除或采取其他必要措施。</p></section>
        <section><h2>十二、账号注销与数据删除</h2><p>你可以在 App 内通过 <span style="padding:2px 8px;border-radius:10px;background:#fff7ed;color:#9a3412;border:1px solid #fed7aa;font-weight:700;">我的 → 设置 → 注销账号</span> 申请注销账号。</p><p>账号注销后，我们将停止为该账号提供服务，并根据法律法规和本政策删除或匿名化处理相关个人信息。请注意，注销账号可能导致时光留言、记录内容和会员权益无法继续使用。</p></section>
        <section><h2>十三、本政策的更新</h2><p>我们可能根据产品功能、法律法规或运营需要更新本隐私政策。重大变更时，我们会通过 App 内通知、弹窗、站内消息或页面公告等方式提醒你。</p></section>
        <section><h2>十四、联系我们</h2><p>提供方：终活项目团队<br>客服邮箱：<a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a><br>备用邮箱：<a href="mailto:huainvhai2@gmail.com">huainvhai2@gmail.com</a><br>官方网站：<a href="https://zhonghuo.zhonghuo.xyz">https://zhonghuo.zhonghuo.xyz</a></p></section>
        </div></article>
        </main>
        <footer class="footer">© 2026 终活. All rights reserved. ｜ <a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a></footer>
        </body>
        </html>
        """
    }

    private static func termsHTML() -> String {
        """
        <!doctype html>
        <html lang="zh-CN">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>终活 App - 服务条款</title>
        <style>
        :root{--bg:#f7f8ff;--card:#fff;--text:#1d2433;--muted:#667085;--p:#4f46e5;--line:#e6e8f0;--soft:#eef2ff}
        *{box-sizing:border-box}
        body{margin:0;color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",Arial,sans-serif;line-height:1.78;background:linear-gradient(180deg,#fbfcff 0%,var(--bg) 42%,#fff 100%)}
        a{color:var(--p);text-decoration:none;font-weight:700}a:hover{text-decoration:underline}
        .container{width:min(920px,calc(100% - 28px));margin:0 auto;padding:18px 0 28px}
        .badge{display:inline-block;padding:8px 14px;border-radius:999px;color:#3730a3;background:linear-gradient(135deg,rgba(79,70,229,.12),rgba(124,58,237,.10));border:1px solid rgba(79,70,229,.15);font-size:14px;font-weight:800}
        h1{margin:16px 0 10px;font-size:30px;line-height:1.1}
        .subtitle{margin:0;color:var(--muted);font-size:16px}
        .meta,.nav{display:flex;flex-wrap:wrap;gap:10px;margin-top:16px}
        .meta span{padding:8px 12px;border-radius:14px;background:#fff;border:1px solid var(--line);color:var(--muted);font-size:13px}
        .nav a{padding:10px 14px;border-radius:14px;background:#fff;border:1px solid var(--line)}
        .card{margin-top:18px;background:rgba(255,255,255,.95);border:1px solid var(--line);border-radius:22px;box-shadow:0 20px 56px rgba(38,42,86,.10);overflow:hidden}
        .notice{margin:18px;padding:16px 18px;border-radius:18px;background:linear-gradient(135deg,rgba(79,70,229,.10),rgba(124,58,237,.09));border:1px solid rgba(79,70,229,.18)}
        .content{padding:0 18px 22px}
        section{padding:20px 0;border-top:1px solid var(--line)}section:first-child{border-top:0}
        h2{margin:0 0 10px;font-size:20px;line-height:1.35}
        h3{margin:16px 0 8px;font-size:17px}
        p{margin:8px 0;font-size:15px}
        ul{padding-left:20px;margin:8px 0}li{margin:6px 0;font-size:15px}
        .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px;margin-top:12px}
        .feature{padding:14px;border-radius:18px;background:linear-gradient(135deg,#fff,var(--soft));border:1px solid var(--line)}
        .feature b{display:block;margin-bottom:5px;color:#312e81;font-size:15px}
        .footer{text-align:center;color:var(--muted);font-size:13px;padding:18px 0 10px}
        @media (max-width:720px){.grid{grid-template-columns:1fr}.content{padding:0 14px 18px}.notice{margin:14px}h1{font-size:26px}}
        </style>
        </head>
        <body>
        <main class="container">
        <header class="hero">
        <div class="badge">终活 App · 服务条款</div>
        <h1>服务条款</h1>
        <p class="subtitle">使用终活前，请阅读并理解本服务条款及相关重要说明。</p>
        <div class="meta"><span>生效日期：<strong>2026年5月2日</strong></span><span>最近更新：<strong>2026年5月2日</strong></span><span>提供方：<strong>终活项目团队</strong></span></div>
        <nav class="nav"><a href="https://zhonghuo.zhonghuo.xyz/docs/index.html">技术支持</a><a href="https://zhonghuo.zhonghuo.xyz/docs/privacy.html">隐私政策</a><a href="mailto:support@zhonghuo.app">联系我们</a></nav>
        </header>
        <article class="card">
        <div class="notice"><strong>重要提示：</strong>终活提供的是数字化记录、提醒和手动分享工具。涉及重要事项、资产记录、医疗意愿或其他专业事项时，法律效力可能因地区和形式要求不同而不同。请在必要时咨询律师、公证机构、医疗机构或其他专业人士。</div>
        <div class="content">
        <section><h2>一、接受条款</h2><p>你下载、安装、注册、登录或使用终活 App，即表示你已阅读、理解并同意遵守本服务条款及《隐私政策》。若你不同意本条款，请停止使用本 App。</p><p>终活 App 由<strong>终活项目团队</strong>提供。联系邮箱：<a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a>。</p></section>
        <section><h2>二、服务内容</h2><p>终活是一款个人记录管理平台，帮助你整理重要信息并手动分享。</p><div class="grid">
          <div class="feature"><b>时光留言</b>录制视频、语音或文字，由你手动发送给指定用户。</div>
          <div class="feature"><b>重要事项</b>便捷编写和管理重要信息，作为个人整理参考。</div>
          <div class="feature"><b>定期签到</b>每 1-7 天自主选择签到，仅用于本机提醒。</div>
          <div class="feature"><b>添加用户</b>通过邀请码建立添加关系，双方确认后可查看已同步信息。</div>
        </div><p>实际可用功能以 App 内展示为准。我们可能根据运营、技术、安全或合规需要调整、暂停或优化部分功能。</p></section>
        <section><h2>三、账号注册与安全</h2><ul><li>你应提供真实、准确、完整的注册信息，并及时更新；</li><li>你应妥善保管账号、密码、验证码、设备和登录凭证；</li><li>因你主动泄露、转让、借用账号或设备保管不当造成的损失，由你自行承担；</li><li>发现账号异常、未经授权使用或安全风险时，请及时联系我们。</li></ul></section>
        <section><h2>四、用户内容与授权</h2><p>你在终活 App 中创建、上传或保存的时光留言、重要事项、资产记录、文字、图片、音频、视频及其他内容，仍归你或原权利人所有。</p><p>为向你提供保存、展示、发送、提醒和协作等服务，你授权我们在必要范围内存储、处理、传输和展示相关内容。</p><p>你承诺你上传或设置发送的内容不侵犯他人合法权益，且你已获得接收人或其他相关人员的必要授权。</p></section>
        <section><h2>五、重要事项与说明</h2><p>终活提供的重要事项、资产管理和个人偏好记录功能，主要用于帮助用户记录和整理信息。</p><p>我们不提供法律、医疗、财务、税务、公证或投资建议。本 App 内生成或保存的文档、记录或模板，不必然具备法律效力。</p><p>若你希望相关安排具有正式法律效力，请根据所在地法律要求咨询律师、公证机构、医疗机构或其他专业人士，并完成必要的签署、见证、公证或备案程序。</p></section>
        <section><h2>六、定期签到</h2><p>定期签到功能仅用于辅助本机提醒，并不能替代医疗救助、紧急救援或专业安全服务。</p><p>你可根据实际需要在 1-7 天范围内自主选择签到周期。系统不会因为未签到自动向任何联系人发送通知。你应确保接收对象真实、有效，并已获得相关人员同意。</p><p>当前版本不启用定位功能，也不会因为签到状态自动发送位置信息。</p></section>
        <section><h2>七、会员订阅服务</h2><p>终活可能提供自动续期订阅会员服务，例如月度会员和年度会员。会员权益、价格、周期和具体内容以 App 内展示及 App Store 购买页面为准。</p><h3>1. 订阅与续费</h3><ul><li>订阅将通过你的 Apple ID 账户确认并扣款；</li><li>自动续期订阅会在当前订阅周期结束时自动续订，除非你在当前周期结束前至少 24 小时取消；</li><li>续费费用通常会在当前周期结束前 24 小时内从 Apple ID 账户扣除；</li><li>你可以在 iOS 系统的 Apple ID 订阅管理页面管理或取消订阅。</li></ul><h3>2. 取消订阅</h3><p>你可以前往 iPhone 设置或 App Store 的订阅管理页面取消自动续费。取消后，你仍可在当前已付费周期内继续使用会员权益，到期后会员权益将停止。</p><h3>3. 恢复购买</h3><p>如你更换设备、重新安装 App 或需要同步会员状态，可以使用 App 内“恢复购买”功能。恢复购买用于向 Apple 同步你的订阅记录，不会重复扣费。</p><h3>4. 退款</h3><p>通过 Apple App Store 购买的订阅，退款通常由 Apple 根据其规则处理。你可以通过 Apple 官方渠道申请退款。我们会根据 Apple 返回的退款或订阅状态更新会员权益。</p></section>
        <section><h2>八、用户行为规范</h2><p>你在使用终活 App 时不得：</p><ul><li>上传违法、侵权、欺诈、骚扰、恶意或侵犯他人隐私的内容；</li><li>冒充他人、盗用他人账号或未经授权添加他人联系方式；</li><li>干扰、破坏、攻击 App、服务器、网络或其他用户的正常使用；</li><li>利用 App 从事违法活动、侵犯他人合法权益或规避平台规则；</li><li>对 App 进行反向工程、破解、恶意抓取或未经授权的商业使用。</li></ul></section>
        <section><h2>九、知识产权</h2><p>终活 App 的软件、界面、图标、商标、文字、图片、交互设计、技术架构及相关内容，除用户自行上传内容外，均由我们或相关权利人依法享有知识产权。</p></section>
        <section><h2>十、隐私保护</h2><p>我们重视你的隐私和个人信息保护。我们如何收集、使用、存储、处理和保护你的信息，请查看 <a href="https://zhonghuo.zhonghuo.xyz/docs/privacy.html">《隐私政策》</a>。</p></section>
        <section><h2>十一、免责声明</h2><ul><li>终活 App 是数字化记录、提醒和手动分享工具，不保证任何记录内容当然具备法律效力；</li><li>定期签到不构成紧急救援、医疗服务或安全保证；</li><li>因网络、设备、系统、第三方服务或不可抗力导致的服务中断、数据延迟、展示异常等情况，我们会尽力修复，但不对超出合理控制范围的后果承担责任；</li><li>你应自行判断并核实重要事项，必要时咨询专业人士。</li></ul></section>
        <section><h2>十二、责任限制</h2><p>在法律允许的最大范围内，我们对因使用或无法使用终活 App 所产生的间接损失、预期利益损失、数据损失、业务中断或第三方索赔不承担责任。</p><p>如法律不允许完全排除责任，我们的责任将限于法律允许的最低范围。</p></section>
        <section><h2>十三、账号注销与服务终止</h2><p>你可以根据 App 内提供的入口申请注销账号：我的 → 设置 → 注销账号。</p><p>账号注销可能导致你无法继续访问账号内容、添加信息、时光留言、记录内容和会员权益。注销前请谨慎备份重要信息。</p><p>如你严重违反本条款或法律法规，我们有权暂停或终止向你提供服务。</p></section>
        <section><h2>十四、适用法律与争议解决</h2><p>本条款的订立、生效、履行、解释及争议解决，适用 <strong>中华人民共和国法律</strong>。</p><p>因本条款或终活 App 产生的争议，双方应先友好协商解决；协商不成的，提交终活团队所在地法院处理。</p></section>
        <section><h2>十五、条款更新</h2><p>我们可能根据产品功能、法律法规或运营需要更新本服务条款。重大变更时，我们会通过 App 内通知、弹窗、站内消息或页面公告等方式提醒你。</p><p>条款更新后，若你继续使用终活 App，即表示你接受更新后的条款。</p></section>
        <section><h2>十六、联系我们</h2><p>提供方：终活项目团队<br>客服邮箱：<a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a><br>备用邮箱：<a href="mailto:huainvhai2@gmail.com">huainvhai2@gmail.com</a><br>官方网站：<a href="https://zhonghuo.zhonghuo.xyz">https://zhonghuo.zhonghuo.xyz</a></p></section>
        </div></article>
        </main>
        <footer class="footer">© 2026 终活. All rights reserved. ｜ <a href="mailto:support@zhonghuo.app">support@zhonghuo.app</a></footer>
        </body>
        </html>
        """
    }
}
