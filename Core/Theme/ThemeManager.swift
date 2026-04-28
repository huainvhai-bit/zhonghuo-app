//
//  ThemeManager.swift
//  终活
//
//  主题管理器 - 简化版
//

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum Theme: String, CaseIterable, Codable {
        case auto    // 跟随系统（默认）
        case light   // 浅色模式
        case dark    // 深色模式
    }
    
    @Published var theme: Theme = .auto
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "theme"),
           let theme = Theme(rawValue: savedTheme) {
            self.theme = theme
        }
    }
    
    func setTheme(_ newTheme: Theme) {
        theme = newTheme
        UserDefaults.standard.set(newTheme.rawValue, forKey: "theme")
    }
    
    var isDarkMode: Bool {
        switch theme {
        case .auto:
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    /// 返回适合用于 .preferredColorScheme() 的 ColorScheme
    var preferredColorScheme: ColorScheme? {
        switch theme {
        case .auto:
            return nil  // 跟随系统
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - App Language
final class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()

    enum Language: String, CaseIterable, Codable {
        case chinese
        case english
        case japanese
        case korean

        var displayName: String {
            switch self {
            case .chinese: return "中文"
            case .english: return "English"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            }
        }

        var localeIdentifier: String {
            switch self {
            case .chinese: return "zh-Hans"
            case .english: return "en"
            case .japanese: return "ja"
            case .korean: return "ko"
            }
        }
    }

    @Published var language: Language
    private let storageKey = "appLanguage"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let language = Language(rawValue: saved) {
            self.language = language
        } else {
            self.language = Self.systemPreferredLanguage()
        }
    }

    func setLanguage(_ newLanguage: Language) {
        language = newLanguage
        UserDefaults.standard.set(newLanguage.rawValue, forKey: storageKey)
    }

    static func systemPreferredLanguage() -> Language {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        if preferred.hasPrefix("en") { return .english }
        if preferred.hasPrefix("ja") { return .japanese }
        if preferred.hasPrefix("ko") { return .korean }
        return .chinese
    }
}

enum AppText: String, CaseIterable {
    case appName
    case appTagline
    case loginTitle
    case loginSubtitle
    case identifierPlaceholder
    case passwordPlaceholder
    case captchaPlaceholder
    case captchaRefresh
    case loginButton
    case forgotPassword
    case noAccount
    case registerNow
    case registerTitle
    case registerName
    case registerAccount
    case registerPhoneOptional
    case registerPhoneHelp
    case registerCaptcha
    case registerPassword
    case registerConfirmPassword
    case securityQuestionTitle
    case securityQuestionHelp
    case securityQuestionPicker
    case securityAnswer
    case securityQuestion1
    case securityQuestion2
    case securityQuestion3
    case securityQuestion4
    case securityQuestion5
    case registerButton
    case alreadyHaveAccount
    case loginNow
    case settings
    case editProfile
    case languageSettings
    case appearance
    case themeSettings
    case followSystem
    case lightMode
    case darkMode
    case selectLanguage
    case chinese
    case english
    case japanese
    case korean
    case about
    case back
    case checkUpdate
    case currentVersion
    case officialSite
    case privacyPolicy
    case termsOfService
    case customerEmail
    case customerPhone
    case systemMaintenance
    case pleaseRetry
    case loading
    case tabHome
    case tabCapsule
    case tabWills
    case tabFamily
    case tabMe
    case locationService
    case enableLocation
    case locationDesc
    case signInInterval
    case silentMode
    case todaySteps
    case deviceBattery
    case birthdayLabel
    case birthdayPreview
    case languageSection
    case error
    case confirm
    case resetTitle
    case resetSubtitle
    case resetPasswordButton
    case returnLogin
    case resetSecurityTitle
    case resetSecurityHelp
    case onboardingSafeCheckIn
    case onboardingSafeCheckInDesc
    case onboardingCapsule
    case onboardingCapsuleDesc
    case onboardingWill
    case onboardingWillDesc
    case onboardingFamilyGuard
    case onboardingFamilyGuardDesc
    case onboardingCompanion
    case onboardingCompanionDesc
    case nextPage
    case skip
    case startUsing
    case versionUpdate
    case updateNow
    case later
    case newVersionFound
    case capsuleDetail
    case textContent
    case audioContent
    case videoContent
    case clickToPlay
    case dateInfo
    case sendDate
    case createdDate
    case sent
    case pendingSend
    case noContent
    case deleteCapsule
    case deleteCapsuleMessage
    case playFailed
    case editCapsule
    case deleteAction
    case willDocumentPreview
    case generatedAt
    case lawNotice
    case exportSuccess
    case exportSuccessMessage
    case exportFailed
    case exportFailedMessage
    case done
    case willAndAssets
    case myWills
    case assetManagement
    case addCustomWill
    case previewWill
    case addAsset
    case fillingProgress
    case progressHint
    case completedItems
    case totalItems
    case deleteAsset
    case deleteAssetMessage
    case deleteWill
    case deleteWillMessage
    case familyGuard
    case loadingFamilyList
    case linkedFamily
    case noFamilyBound
    case familyGuardHint
    case shareInviteCode
    case refreshQRCode
    case inviteCode
    case fetching
    case manualInviteHint
    case copyInviteCode
    case close
    case lastCheckIn
    case noRecord
    case pendingAcceptance
    case removeRelation
    case removeRelationMessage
    case manualInvite
    case binding
    case bindNow
    case bindSuccess
    case bindFailed
    case homeWithYou
    case familyProtected
    case familyCheckStatus
    case autoCheckIn
    case safeCheckIn
    case familyGuarding
    case notificationsMuted
    case notificationsMuteHelp
    case phoneBoundLocked
    case phoneBindingHint
    case phoneFormatError
    case firstBindPhoneRequired
    case saveProfile
    case profileSaved
    case restartRequired
    case automaticFetchRecommended
    case leaveBlankAuto
    case testSuccess
    case testFailed
    case appCopyright
    case maleGender
    case femaleGender
    case monitorNormalTitle
    case monitorNormalDesc
    case monitorWarningTitle
    case monitorWarningDesc
    case monitorDangerTitle
    case monitorDangerDesc
    case scanFamilyTitle
    case scanFamilySubtitle
    case scanFamilyButton
    case shareQRCodeTitle
    case shareQRCodeSubtitle
    case shareQRCodeButton
    case manualInviteTitle
    case manualInviteSubtitle
    case manualInviteButton
    case familyLimitReached
    case invalidQRCode
    case loadingFamilyListTitle
    case noFamilyBoundTitle
    case noFamilyBoundHint
    case familyCountSuffix
    case checkingNormal
    case checkingOverdue
    case checkingSevere
    case qrGenerating
    case qrFetching
    case closeButton
    case bindRelationTitle
    case bindRelationMessage
    case noRecordPrefix
    case inviteCodePlaceholder
    case familyLimitCurrent
    case familyLimitTarget
    case myTasks
    case viewAll
    case receivedCapsules
    case all
    case noReceivedCapsules
    case receivedCapsuleHint
    case from
    case unread
    case read
    case settingsTitle
    case notificationSettings
    case deviceInfo
    case avatar
    case name
    case phone
    /// 个人资料中「登录账号」只读标签（与「手机号」并列）
    case profileLoginAccount
    case identityInfo
    case serverAddress
    case testConnection
    case serverConfig
    case aboutApp
    case appInfo
    case contactUs
    case save
    case cancel
    case currentVersionTitle
    case currentVersionValue
    case openMembership
    case limitedOffer
    case membershipValid
    case locationPermission
    case goSettings
    case locationAlwaysHint
    case prompt
    case today
    case steps
    case updateTime
    case user
    case unboundPhone
    case unknown
    case backgroundLocationOn
    case whenInUseOnly
    case denied
    case notSet
    case gender
    case ethnicity
    case idCard
    case address
    case status
    case testing
    case notTested
    case saveAndRestart
    case appInformation
    case contactEmail
    case legalDisclosure
    case version
    case themeGuide
}

enum L10n {
    static func string(_ key: AppText) -> String {
        let language = AppLanguageManager.shared.language
        return translations[language.rawValue]?[key.rawValue]
            ?? translations[AppLanguageManager.Language.chinese.rawValue]?[key.rawValue]
            ?? key.rawValue
    }

    static func text(_ chinese: String, en: String, ja: String, ko: String) -> String {
        switch AppLanguageManager.shared.language {
        case .chinese: return chinese
        case .english: return en
        case .japanese: return ja
        case .korean: return ko
        }
    }

    private static let translations: [String: [String: String]] = [
        "chinese": [
            "appName": "终活",
            "appTagline": "让生命更有尊严，让告别更有温度",
            "loginTitle": "登录账号",
            "loginSubtitle": "账号或手机号 + 密码/验证码 登录",
            "identifierPlaceholder": "账号或手机号",
            "passwordPlaceholder": "密码",
            "captchaPlaceholder": "图形验证码",
            "captchaRefresh": "点击刷新",
            "loginButton": "登录",
            "forgotPassword": "忘记密码？",
            "noAccount": "还没有账号？",
            "registerNow": "立即注册",
            "registerTitle": "注册账号",
            "registerName": "姓名",
            "registerAccount": "账号（4-30 位）",
            "registerPhoneOptional": "手机号（选填，一旦绑定后不可修改）",
            "registerPhoneHelp": "不填写手机号也可以注册；如果填写，后续仅可作为登录方式绑定一次，不能再修改。",
            "registerCaptcha": "验证码",
            "registerPassword": "设置密码（8 位以上）",
            "registerConfirmPassword": "确认密码",
            "securityQuestionTitle": "找回密码唯一方式",
            "securityQuestionHelp": "注册时必须选择并牢记密保问题与答案。以后忘记密码，只能通过它找回。",
            "securityQuestionPicker": "密保问题",
            "securityAnswer": "密保答案",
            "securityQuestion1": "我的第一所学校名称是？",
            "securityQuestion2": "我最喜欢的城市是？",
            "securityQuestion3": "我母亲的姓氏是？",
            "securityQuestion4": "我最喜欢的电影是？",
            "securityQuestion5": "我童年最好的朋友名字是？",
            "registerButton": "立即注册",
            "alreadyHaveAccount": "已经有账号？",
            "loginNow": "立即登录",
            "settings": "设置",
            "editProfile": "编辑资料",
            "languageSettings": "语言设置",
            "appearance": "外观",
            "themeSettings": "主题设置",
            "followSystem": "跟随系统",
            "lightMode": "浅色模式",
            "darkMode": "深色模式",
            "selectLanguage": "选择语言",
            "chinese": "中文",
            "english": "英文",
            "japanese": "日语",
            "korean": "韩语",
            "about": "关于",
            "back": "返回",
            "checkUpdate": "检查更新",
            "currentVersion": "当前版本",
            "officialSite": "官方网站",
            "privacyPolicy": "隐私政策",
            "termsOfService": "服务条款",
            "customerEmail": "客服邮箱",
            "customerPhone": "客服电话",
            "systemMaintenance": "系统维护中",
            "pleaseRetry": "请稍后再试",
            "loading": "正在加载...",
            "tabHome": "首页",
            "tabCapsule": "时光胶囊",
            "tabWills": "嘱托与资产",
            "tabFamily": "家人守护",
            "tabMe": "我的",
            "locationService": "定位服务",
            "enableLocation": "启用定位服务",
            "locationDesc": "定位服务用于在签到时记录您的位置信息，证明您的人身安全。如果您不启用定位，将无法使用签到功能的位置记录。",
            "signInInterval": "签到间隔",
            "silentMode": "静默模式",
            "todaySteps": "今日步数",
            "deviceBattery": "设备电量",
            "birthdayLabel": "出生日期",
            "birthdayPreview": "当前选择",
            "languageSection": "语言",
            "error": "错误",
            "confirm": "确定",
            "resetTitle": "重置密码",
            "resetSubtitle": "找回密码",
            "resetPasswordButton": "重置密码",
            "returnLogin": "返回登录",
            "resetSecurityTitle": "忘记密码时的唯一找回方式",
            "resetSecurityHelp": "请输入注册时选择的密保问题和答案。请务必记住，这是找回密码的唯一方式。",
            "appMaintenance": "系统维护中，请稍后再试",
            "onboardingSafeCheckIn": "安全签到",
            "onboardingSafeCheckInDesc": "每 48 小时签到一次，让家人安心。如果忘记签到，家人守护会及时收到提醒。",
            "onboardingCapsule": "时光胶囊",
            "onboardingCapsuleDesc": "写下想说的话，设置未来的发送时间。让爱与关怀穿越时空，温暖每一个重要时刻。",
            "onboardingWill": "身后安排",
            "onboardingWillDesc": "提前规划财产分配、身后事项等内容。内置模板帮助你快速完成，让家人少一份负担。",
            "onboardingFamilyGuard": "家人守护",
            "onboardingFamilyGuardDesc": "绑定家人后，可互相查看签到状态和设备信息，让彼此安心守护。",
            "onboardingCompanion": "温暖陪伴",
            "onboardingCompanionDesc": "终活不是终点，而是对生命的尊重。我们陪你规划每一天，让爱没有遗憾。",
            "nextPage": "下一页",
            "skip": "跳过",
            "startUsing": "开始使用",
            "versionUpdate": "版本更新",
            "updateNow": "立即更新",
            "later": "稍后再说",
            "newVersionFound": "发现新版本",
            "capsuleDetail": "胶囊详情",
            "textContent": "文字内容",
            "audioContent": "语音内容",
            "videoContent": "视频内容",
            "clickToPlay": "点击播放",
            "dateInfo": "日期信息",
            "sendDate": "发送日期",
            "createdDate": "创建日期",
            "sent": "已发送",
            "pendingSend": "待发送",
            "noContent": "（无内容）",
            "deleteCapsule": "删除胶囊",
            "deleteCapsuleMessage": "确定要删除胶囊「%@」吗？此操作不可恢复。",
            "playFailed": "播放失败",
            "editCapsule": "编辑胶囊",
            "deleteAction": "删除",
            "done": "完成",
            "willAndAssets": "嘱托与资产",
            "myWills": "我的嘱托",
            "assetManagement": "资产管理",
            "addCustomWill": "新增自定义嘱托",
            "previewWill": "预览嘱托",
            "addAsset": "添加资产",
            "fillingProgress": "填写进度",
            "progressHint": "完成度越高，您的意愿就越清晰",
            "completedItems": "已完成 %@ 项",
            "totalItems": "共 %@ 项",
            "deleteAsset": "删除资产",
            "deleteAssetMessage": "确定要删除资产「%@」吗？此操作不可恢复。",
            "deleteWill": "删除嘱托",
            "deleteWillMessage": "确定要删除嘱托「%@」吗？此操作不可恢复。",
            "familyGuard": "家人守护",
            "loadingFamilyList": "正在加载家人列表...",
            "linkedFamily": "已关联的家人",
            "noFamilyBound": "暂时还没有绑定家人",
            "familyGuardHint": "使用上方功能绑定家人，互相关爱守护",
            "shareInviteCode": "分享我的邀请码",
            "refreshQRCode": "刷新二维码",
            "inviteCode": "邀请码",
            "fetching": "正在获取...",
            "manualInviteHint": "可手动输入邀请码绑定",
            "copyInviteCode": "复制邀请码",
            "close": "关闭",
            "lastCheckIn": "最后签到",
            "noRecord": "暂无记录",
            "pendingAcceptance": "待接受",
            "removeRelation": "解除关系",
            "removeRelationMessage": "确定要与 %@ 解除家人关系吗？此操作不可恢复。",
            "manualInvite": "手动输入邀请码",
            "binding": "绑定中...",
            "bindNow": "立即绑定",
            "bindSuccess": "绑定成功",
            "bindFailed": "绑定失败",
            "homeWithYou": "终活与您相伴",
            "familyProtected": "您正在守护家人的安全",
            "familyCheckStatus": "查看家人的签到状态",
            "autoCheckIn": "打开 App 即可自动签到",
            "safeCheckIn": "安全签到",
            "familyGuarding": "家人守护中",
            "notificationsMuted": "已关闭所有签到通知",
            "notificationsMuteHelp": "开启后不再推送任何签到通知",
            "phoneBoundLocked": "手机号已绑定，后续不可修改，可使用手机号作为账号登录",
            "phoneBindingHint": "绑定手机号后不可解绑，可使用手机号作为账号登录",
            "phoneFormatError": "手机号格式不正确，请输入 11 位手机号",
            "firstBindPhoneRequired": "请先绑定手机号，绑定后不可修改",
            "saveProfile": "保存资料",
            "profileSaved": "用户信息已保存，登录状态保持",
            "restartRequired": "修改后需要重启 App 生效",
            "automaticFetchRecommended": "自动获取（推荐）",
            "leaveBlankAuto": "留空表示自动从后端获取，深度绑定当前服务器地址",
            "testSuccess": "成功",
            "testFailed": "失败",
            "appCopyright": "© 2026 终活 App. All rights reserved.",
            "maleGender": "男",
            "femaleGender": "女",
            "monitorNormalTitle": "监测正常",
            "monitorNormalDesc": "一切安好，记得定期签到哦",
            "monitorWarningTitle": "警告：已超时",
            "monitorWarningDesc": "您已超过签到时间，请尽快签到",
            "monitorDangerTitle": "危险：离线超时",
            "monitorDangerDesc": "您已离线超时，请立即签到！",
            "scanFamilyTitle": "扫码关联家人",
            "scanFamilySubtitle": "扫描家人的邀请码，快速绑定关系",
            "scanFamilyButton": "开始扫码",
            "shareQRCodeTitle": "分享我的二维码",
            "shareQRCodeSubtitle": "家人扫描下方二维码绑定你",
            "shareQRCodeButton": "查看二维码",
            "manualInviteTitle": "手动输入邀请码",
            "manualInviteSubtitle": "如果无法扫码，可以手动输入 6 位邀请码",
            "manualInviteButton": "立即输入",
            "familyLimitReached": "家人数量已达上限，升级会员可绑定更多家人",
            "invalidQRCode": "无效的二维码",
            "loadingFamilyListTitle": "正在加载家人列表...",
            "noFamilyBoundTitle": "暂时还没有绑定家人",
            "noFamilyBoundHint": "使用上方功能绑定家人，互相关爱守护",
            "familyCountSuffix": "人",
            "checkingNormal": "签到正常",
            "checkingOverdue": "已超时，等待用户打开 App",
            "checkingSevere": "严重超时",
            "qrGenerating": "正在生成...",
            "qrFetching": "正在获取...",
            "closeButton": "关闭",
            "bindRelationTitle": "解除关系",
            "bindRelationMessage": "确定要与 %@ 解除家人关系吗？此操作不可恢复。",
            "noRecordPrefix": "最后签到：暂无记录",
            "inviteCodePlaceholder": "6 位邀请码",
            "familyLimitCurrent": "当前最多 %@ 位家人",
            "familyLimitTarget": "会员版可绑定更多家人",
            "myTasks": "我的事务",
            "viewAll": "查看全部",
            "receivedCapsules": "我收到的时光胶囊",
            "all": "全部",
            "noReceivedCapsules": "暂无收到的胶囊",
            "receivedCapsuleHint": "家人分享的胶囊会出现在这里",
            "from": "来自",
            "unread": "未读",
            "read": "已读",
            "settingsTitle": "设置",
            "notificationSettings": "通知设置",
            "deviceInfo": "设备信息",
            "avatar": "头像",
            "name": "姓名",
            "phone": "手机号",
            "profileLoginAccount": "登录账号",
            "identityInfo": "身份信息",
            "serverAddress": "服务器地址",
            "testConnection": "测试连接",
            "serverConfig": "服务器配置",
            "aboutApp": "关于",
            "appInfo": "应用信息",
            "contactUs": "联系我们",
            "save": "保存",
            "cancel": "取消",
            "currentVersionTitle": "当前版本",
            "currentVersionValue": "v%@",
            "openMembership": "开通会员",
            "limitedOffer": "限时特惠 >",
            "membershipValid": "会员有效",
            "locationPermission": "定位权限",
            "goSettings": "去设置",
            "locationAlwaysHint": "为了您的安全，建议开启“始终允许”定位权限，这样即使不打开 App 也能获取位置信息。",
            "prompt": "提示",
            "positionAlways": "始终允许",
            "today": "今日",
            "steps": "步",
            "updateTime": "最后更新",
            "user": "用户",
            "unboundPhone": "未绑定手机号",
            "unknown": "未知",
            "backgroundLocationOn": "后台定位已开启",
            "whenInUseOnly": "仅使用期间允许",
            "denied": "已拒绝",
            "notSet": "未设置",
            "gender": "性别",
            "ethnicity": "民族",
            "idCard": "身份证号码",
            "address": "住址",
            "status": "状态",
            "testing": "测试中...",
            "notTested": "未测试",
            "saveAndRestart": "保存并重启",
            "appInformation": "应用信息",
            "contactEmail": "客服邮箱",
            "legalDisclosure": "电子遗嘱效力说明",
            "version": "版本",
            "themeGuide": "主题设置会影响 App 的整体外观颜色。选择您喜欢的颜色方案。"
        ],
        "english": [
            "appName": "Zhonghuo",
            "appTagline": "Live with dignity, say goodbye with warmth",
            "loginTitle": "Sign In",
            "loginSubtitle": "Sign in with account or phone + password/code",
            "identifierPlaceholder": "Account or phone",
            "passwordPlaceholder": "Password",
            "captchaPlaceholder": "Captcha",
            "captchaRefresh": "Refresh",
            "loginButton": "Sign In",
            "forgotPassword": "Forgot password?",
            "noAccount": "No account yet?",
            "registerNow": "Register",
            "registerTitle": "Create Account",
            "registerName": "Name",
            "registerAccount": "Account (4-30 chars)",
            "registerPhoneOptional": "Phone (optional, locked after binding)",
            "registerPhoneHelp": "You can register without a phone. If you bind one, it becomes a one-time login binding and cannot be changed later.",
            "registerCaptcha": "Captcha",
            "registerPassword": "Set password (8+ chars)",
            "registerConfirmPassword": "Confirm password",
            "securityQuestionTitle": "Only password recovery method",
            "securityQuestionHelp": "Choose and remember your security question and answer during registration. Forgotten passwords can only be recovered through this.",
            "securityQuestionPicker": "Security question",
            "securityAnswer": "Security answer",
            "securityQuestion1": "What was the name of my first school?",
            "securityQuestion2": "What is my favorite city?",
            "securityQuestion3": "What is my mother's maiden name?",
            "securityQuestion4": "What is my favorite movie?",
            "securityQuestion5": "What is the name of my childhood best friend?",
            "registerButton": "Register",
            "alreadyHaveAccount": "Already have an account?",
            "loginNow": "Sign In",
            "settings": "Settings",
            "editProfile": "Edit Profile",
            "languageSettings": "Language",
            "appearance": "Appearance",
            "themeSettings": "Theme",
            "followSystem": "Follow system",
            "lightMode": "Light mode",
            "darkMode": "Dark mode",
            "selectLanguage": "Choose language",
            "chinese": "Chinese",
            "english": "English",
            "japanese": "Japanese",
            "korean": "Korean",
            "about": "About",
            "back": "Back",
            "checkUpdate": "Check for updates",
            "currentVersion": "Current version",
            "officialSite": "Official website",
            "privacyPolicy": "Privacy policy",
            "termsOfService": "Terms of service",
            "customerEmail": "Support email",
            "customerPhone": "Support phone",
            "systemMaintenance": "System maintenance",
            "pleaseRetry": "Please try again later",
            "loading": "Loading...",
            "tabHome": "Home",
            "tabCapsule": "Time Capsule",
            "tabWills": "Wills & Assets",
            "tabFamily": "Family",
            "tabMe": "Me",
            "locationService": "Location Service",
            "enableLocation": "Enable location service",
            "locationDesc": "Location is used when checking in to record your location and prove your safety. If you disable it, location recording for check-ins will be unavailable.",
            "signInInterval": "Check-in interval",
            "silentMode": "Silent mode",
            "todaySteps": "Today’s steps",
            "deviceBattery": "Device battery",
            "birthdayLabel": "Birthday",
            "birthdayPreview": "Selected",
            "languageSection": "Language",
            "error": "Error",
            "confirm": "OK",
            "resetTitle": "Reset Password",
            "resetSubtitle": "Recover password",
            "resetPasswordButton": "Reset Password",
            "returnLogin": "Back to Login",
            "resetSecurityTitle": "The only way to recover your password",
            "resetSecurityHelp": "Please enter the security question and answer you chose during registration. Keep them safe; this is the only way to recover your password.",
            "appMaintenance": "System maintenance, please try again later",
            "onboardingSafeCheckIn": "Safe check-in",
            "onboardingSafeCheckInDesc": "Check in every 48 hours so your family can rest easy. If you forget, family guardians will be notified.",
            "onboardingCapsule": "Time Capsule",
            "onboardingCapsuleDesc": "Write down what you want to say and schedule it for the future. Let care travel through time.",
            "onboardingWill": "Life arrangements",
            "onboardingWillDesc": "Plan asset distribution and other end-of-life arrangements ahead of time. Templates help you finish faster.",
            "onboardingFamilyGuard": "Family Care",
            "onboardingFamilyGuardDesc": "After binding family members, you can view each other's check-in status and device info.",
            "onboardingCompanion": "Warm companionship",
            "onboardingCompanionDesc": "We walk with you every day so love has no regrets.",
            "nextPage": "Next",
            "skip": "Skip",
            "startUsing": "Get Started",
            "versionUpdate": "Version Update",
            "updateNow": "Update Now",
            "later": "Later",
            "newVersionFound": "New version found",
            "capsuleDetail": "Capsule Details",
            "textContent": "Text Content",
            "audioContent": "Audio Content",
            "videoContent": "Video Content",
            "clickToPlay": "Tap to play",
            "dateInfo": "Date Info",
            "sendDate": "Send Date",
            "createdDate": "Created Date",
            "sent": "Sent",
            "pendingSend": "Pending",
            "noContent": "(No content)",
            "deleteCapsule": "Delete Capsule",
            "deleteCapsuleMessage": "Delete capsule \"%@\"? This cannot be undone.",
            "playFailed": "Playback failed",
            "editCapsule": "Edit Capsule",
            "deleteAction": "Delete",
            "done": "Done",
            "willAndAssets": "Wills & Assets",
            "myWills": "My Wills",
            "assetManagement": "Asset Management",
            "addCustomWill": "Add Custom Wish",
            "previewWill": "Preview Wills",
            "addAsset": "Add Asset",
            "fillingProgress": "Completion",
            "progressHint": "The more complete, the clearer your wishes become",
            "completedItems": "Completed %@",
            "totalItems": "Total %@",
            "deleteAsset": "Delete Asset",
            "deleteAssetMessage": "Delete asset \"%@\"? This cannot be undone.",
            "deleteWill": "Delete Wish",
            "deleteWillMessage": "Delete wish \"%@\"? This cannot be undone.",
            "familyGuard": "Family Care",
            "loadingFamilyList": "Loading family list...",
            "linkedFamily": "Linked family",
            "noFamilyBound": "No family bound yet",
            "familyGuardHint": "Use the options above to bind family and care for each other.",
            "shareInviteCode": "Share Invite Code",
            "refreshQRCode": "Refresh QR Code",
            "inviteCode": "Invite Code",
            "fetching": "Loading...",
            "manualInviteHint": "You can bind by entering an invite code manually.",
            "copyInviteCode": "Copy Invite Code",
            "close": "Close",
            "lastCheckIn": "Last check-in",
            "noRecord": "No record",
            "pendingAcceptance": "Pending",
            "removeRelation": "Unbind",
            "removeRelationMessage": "Unbind family relationship with %@? This cannot be undone.",
            "manualInvite": "Enter Invite Code",
            "binding": "Binding...",
            "bindNow": "Bind Now",
            "bindSuccess": "Bound successfully",
            "bindFailed": "Binding failed",
            "homeWithYou": "Zhonghuo with you",
            "familyProtected": "You are protecting your family",
            "familyCheckStatus": "Check family check-in status",
            "autoCheckIn": "Open the app to check in automatically",
            "safeCheckIn": "Safe check-in",
            "familyGuarding": "Family care mode",
            "notificationsMuted": "All check-in notifications are muted",
            "notificationsMuteHelp": "No check-in notifications will be pushed while this is on",
            "phoneBoundLocked": "Phone number is already bound and cannot be changed. You can use it to log in.",
            "phoneBindingHint": "Binding a phone number is one-time only and cannot be undone.",
            "phoneFormatError": "Invalid phone number. Please enter an 11-digit phone number.",
            "firstBindPhoneRequired": "Please bind a phone number first; it cannot be changed later.",
            "saveProfile": "Save Profile",
            "profileSaved": "Profile saved and login state kept",
            "restartRequired": "Changes take effect after restarting the app",
            "automaticFetchRecommended": "Auto fetch (recommended)",
            "leaveBlankAuto": "Leave blank to auto-fetch from the backend and stay tied to this server.",
            "testSuccess": "Success",
            "testFailed": "Failed",
            "appCopyright": "© 2026 Zhonghuo App. All rights reserved.",
            "maleGender": "Male",
            "femaleGender": "Female",
            "monitorNormalTitle": "Monitoring normal",
            "monitorNormalDesc": "Everything is fine. Remember to check in regularly.",
            "monitorWarningTitle": "Warning: overdue",
            "monitorWarningDesc": "You are past the check-in time. Please check in soon.",
            "monitorDangerTitle": "Danger: offline overdue",
            "monitorDangerDesc": "You are offline and overdue. Please check in now!",
            "scanFamilyTitle": "Scan to bind family",
            "scanFamilySubtitle": "Scan your family member's invite code to bind quickly",
            "scanFamilyButton": "Start scan",
            "shareQRCodeTitle": "Share my QR code",
            "shareQRCodeSubtitle": "Family members can scan the QR code below to bind with you",
            "shareQRCodeButton": "View QR code",
            "manualInviteTitle": "Enter invite code manually",
            "manualInviteSubtitle": "If you can't scan, you can type the 6-digit invite code",
            "manualInviteButton": "Enter now",
            "familyLimitReached": "You have reached the family limit. Upgrade to bind more family members.",
            "invalidQRCode": "Invalid QR code",
            "loadingFamilyListTitle": "Loading family list...",
            "noFamilyBoundTitle": "No family bound yet",
            "noFamilyBoundHint": "Use the options above to bind family and care for each other.",
            "familyCountSuffix": "members",
            "checkingNormal": "Check-in normal",
            "checkingOverdue": "Overdue, waiting for the user to open the app",
            "checkingSevere": "Severely overdue",
            "qrGenerating": "Generating...",
            "qrFetching": "Loading...",
            "closeButton": "Close",
            "bindRelationTitle": "Unbind relationship",
            "bindRelationMessage": "Unbind family relationship with %@? This cannot be undone.",
            "noRecordPrefix": "Last check-in: no record",
            "inviteCodePlaceholder": "6-digit invite code",
            "familyLimitCurrent": "Up to %@ family members",
            "familyLimitTarget": "Premium allows more family members",
            "myTasks": "My items",
            "viewAll": "View all",
            "receivedCapsules": "Received Capsules",
            "all": "All",
            "noReceivedCapsules": "No received capsules yet",
            "receivedCapsuleHint": "Capsules shared by family will appear here.",
            "from": "From",
            "unread": "Unread",
            "read": "Read",
            "settingsTitle": "Settings",
            "notificationSettings": "Notifications",
            "deviceInfo": "Device Info",
            "avatar": "Avatar",
            "name": "Name",
            "phone": "Phone",
            "profileLoginAccount": "Login account",
            "identityInfo": "Identity Info",
            "serverAddress": "Server URL",
            "testConnection": "Test Connection",
            "serverConfig": "Server Config",
            "aboutApp": "About",
            "appInfo": "App Info",
            "contactUs": "Contact Us",
            "save": "Save",
            "cancel": "Cancel",
            "currentVersionTitle": "Current version",
            "currentVersionValue": "v%@",
            "openMembership": "Go Premium",
            "limitedOffer": "Limited offer >",
            "membershipValid": "Premium active",
            "locationPermission": "Location Permission",
            "goSettings": "Go to Settings",
            "locationAlwaysHint": "For your safety, we recommend enabling \"Always\" location access so location can be recorded even when the app is closed.",
            "prompt": "Notice",
            "positionAlways": "Always",
            "today": "Today",
            "steps": "steps",
            "updateTime": "Last updated",
            "user": "User",
            "unboundPhone": "Phone not bound",
            "unknown": "Unknown",
            "backgroundLocationOn": "Background location on",
            "whenInUseOnly": "When in use only",
            "denied": "Denied",
            "notSet": "Not set",
            "gender": "Gender",
            "ethnicity": "Ethnicity",
            "idCard": "ID number",
            "address": "Address",
            "status": "Status",
            "testing": "Testing...",
            "notTested": "Not tested",
            "saveAndRestart": "Save and restart",
            "appInformation": "App information",
            "contactEmail": "Support email",
            "legalDisclosure": "Electronic will effectiveness",
            "version": "Version",
            "themeGuide": "Theme settings affect the app's overall appearance. Choose the color scheme you like."
        ],
        "japanese": [
            "appName": "終活",
            "appTagline": "尊厳ある人生を、温かい別れを",
            "loginTitle": "ログイン",
            "loginSubtitle": "アカウントまたは電話番号 + パスワード/コードでログイン",
            "identifierPlaceholder": "アカウントまたは電話番号",
            "passwordPlaceholder": "パスワード",
            "captchaPlaceholder": "画像認証",
            "captchaRefresh": "更新",
            "loginButton": "ログイン",
            "forgotPassword": "パスワードを忘れた？",
            "noAccount": "アカウントをお持ちでないですか？",
            "registerNow": "新規登録",
            "registerTitle": "アカウント作成",
            "registerName": "氏名",
            "registerAccount": "アカウント（4〜30文字）",
            "registerPhoneOptional": "電話番号（任意、登録後は変更不可）",
            "registerPhoneHelp": "電話番号なしでも登録できます。設定した場合は一度だけ紐付けでき、その後は変更できません。",
            "registerCaptcha": "画像認証",
            "registerPassword": "パスワード設定（8文字以上）",
            "registerConfirmPassword": "パスワード確認",
            "securityQuestionTitle": "唯一のパスワード再設定方法",
            "securityQuestionHelp": "登録時に秘密の質問と答えを必ず選び、忘れないでください。パスワードを忘れた場合はこれだけが復旧手段です。",
            "securityQuestionPicker": "秘密の質問",
            "securityAnswer": "答え",
            "securityQuestion1": "最初の学校の名前は？",
            "securityQuestion2": "一番好きな都市は？",
            "securityQuestion3": "母の旧姓は？",
            "securityQuestion4": "一番好きな映画は？",
            "securityQuestion5": "子どもの頃の親友の名前は？",
            "registerButton": "新規登録",
            "alreadyHaveAccount": "すでにアカウントがありますか？",
            "loginNow": "ログイン",
            "settings": "設定",
            "editProfile": "プロフィール編集",
            "languageSettings": "言語",
            "appearance": "外観",
            "themeSettings": "テーマ設定",
            "followSystem": "システムに従う",
            "lightMode": "ライトモード",
            "darkMode": "ダークモード",
            "selectLanguage": "言語を選択",
            "chinese": "中国語",
            "english": "英語",
            "japanese": "日本語",
            "korean": "韓国語",
            "about": "情報",
            "back": "戻る",
            "checkUpdate": "更新を確認",
            "currentVersion": "現在のバージョン",
            "officialSite": "公式サイト",
            "privacyPolicy": "プライバシーポリシー",
            "termsOfService": "利用規約",
            "customerEmail": "サポートメール",
            "customerPhone": "サポート電話",
            "systemMaintenance": "システムメンテナンス中",
            "pleaseRetry": "後でもう一度お試しください",
            "loading": "読み込み中...",
            "tabHome": "ホーム",
            "tabCapsule": "タイムカプセル",
            "tabWills": "遺言と資産",
            "tabFamily": "家族",
            "tabMe": "マイページ",
            "locationService": "位置情報サービス",
            "enableLocation": "位置情報サービスを有効にする",
            "locationDesc": "チェックイン時に位置情報を記録して安全を証明します。無効にするとチェックインの位置記録は使えません。",
            "signInInterval": "チェックイン間隔",
            "silentMode": "サイレントモード",
            "todaySteps": "今日の歩数",
            "deviceBattery": "バッテリー",
            "birthdayLabel": "生年月日",
            "birthdayPreview": "選択中",
            "languageSection": "言語",
            "error": "エラー",
            "confirm": "OK",
            "resetTitle": "パスワードをリセット",
            "resetSubtitle": "パスワードの再設定",
            "resetPasswordButton": "パスワードをリセット",
            "returnLogin": "ログインに戻る",
            "resetSecurityTitle": "パスワード再設定の唯一の方法",
            "resetSecurityHelp": "登録時に選んだ秘密の質問と答えを入力してください。必ず覚えておいてください。これが唯一の復旧方法です。",
            "appMaintenance": "システムメンテナンス中です。しばらくしてから再度お試しください",
            "onboardingSafeCheckIn": "安全なチェックイン",
            "onboardingSafeCheckInDesc": "48時間ごとにチェックインして、家族に安心を届けましょう。忘れた場合は家族見守りに通知されます。",
            "onboardingCapsule": "タイムカプセル",
            "onboardingCapsuleDesc": "伝えたいことを書いて、未来の送信日時を設定できます。",
            "onboardingWill": "身後の準備",
            "onboardingWillDesc": "財産分配や身後の準備を事前に整理できます。",
            "onboardingFamilyGuard": "家族見守り",
            "onboardingFamilyGuardDesc": "家族を連携すると、お互いのチェックイン状況や端末情報を確認できます。",
            "onboardingCompanion": "温かな伴走",
            "onboardingCompanionDesc": "毎日を一緒に歩み、後悔のない愛を残しましょう。",
            "nextPage": "次へ",
            "skip": "スキップ",
            "startUsing": "始める",
            "versionUpdate": "バージョン更新",
            "updateNow": "今すぐ更新",
            "later": "後で",
            "newVersionFound": "新しいバージョンがあります",
            "capsuleDetail": "カプセル詳細",
            "textContent": "テキスト内容",
            "audioContent": "音声内容",
            "videoContent": "動画内容",
            "clickToPlay": "タップして再生",
            "dateInfo": "日付情報",
            "sendDate": "送信日",
            "createdDate": "作成日",
            "sent": "送信済み",
            "pendingSend": "送信待ち",
            "noContent": "（内容なし）",
            "deleteCapsule": "カプセルを削除",
            "deleteCapsuleMessage": "カプセル「%@」を削除しますか？この操作は元に戻せません。",
            "playFailed": "再生に失敗しました",
            "editCapsule": "カプセルを編集",
            "deleteAction": "削除",
            "done": "完了",
            "willAndAssets": "遺言と資産",
            "myWills": "私の遺言",
            "assetManagement": "資産管理",
            "addCustomWill": "カスタム遺言を追加",
            "previewWill": "遺言をプレビュー",
            "addAsset": "資産を追加",
            "fillingProgress": "入力進捗",
            "progressHint": "完成度が高いほど、思いがより明確になります",
            "completedItems": "完了 %@ 件",
            "totalItems": "合計 %@ 件",
            "deleteAsset": "資産を削除",
            "deleteAssetMessage": "資産「%@」を削除しますか？この操作は元に戻せません。",
            "deleteWill": "遺言を削除",
            "deleteWillMessage": "遺言「%@」を削除しますか？この操作は元に戻せません。",
            "familyGuard": "家族見守り",
            "loadingFamilyList": "家族一覧を読み込み中...",
            "linkedFamily": "紐付け済みの家族",
            "noFamilyBound": "まだ家族が紐付けられていません",
            "familyGuardHint": "上の機能で家族を追加して、お互いに見守りましょう。",
            "shareInviteCode": "招待コードを共有",
            "refreshQRCode": "QRコードを更新",
            "inviteCode": "招待コード",
            "fetching": "取得中...",
            "manualInviteHint": "招待コードを手入力して紐付けできます。",
            "copyInviteCode": "招待コードをコピー",
            "close": "閉じる",
            "lastCheckIn": "最終チェックイン",
            "noRecord": "記録なし",
            "pendingAcceptance": "承認待ち",
            "removeRelation": "関係を解除",
            "removeRelationMessage": "%@ との家族関係を解除しますか？この操作は元に戻せません。",
            "manualInvite": "招待コードを手入力",
            "binding": "紐付け中...",
            "bindNow": "今すぐ紐付け",
            "bindSuccess": "紐付け成功",
            "bindFailed": "紐付け失敗",
            "homeWithYou": "終活とともに",
            "familyProtected": "家族を見守っています",
            "familyCheckStatus": "家族のチェックイン状態を確認",
            "autoCheckIn": "アプリを開くと自動チェックインします",
            "safeCheckIn": "安全なチェックイン",
            "familyGuarding": "家族見守り中",
            "notificationsMuted": "すべてのチェックイン通知を停止しました",
            "notificationsMuteHelp": "有効にするとチェックイン通知は送信されません",
            "phoneBoundLocked": "電話番号はすでに登録されており、変更できません。ログインに使用できます。",
            "phoneBindingHint": "電話番号の登録は一度だけです。後から変更はできません。",
            "phoneFormatError": "電話番号の形式が正しくありません。11桁で入力してください。",
            "firstBindPhoneRequired": "先に電話番号を登録してください。後から変更はできません。",
            "saveProfile": "プロフィールを保存",
            "profileSaved": "プロフィールを保存しました。ログイン状態は維持されます",
            "restartRequired": "変更はアプリを再起動すると反映されます",
            "automaticFetchRecommended": "自動取得（推奨）",
            "leaveBlankAuto": "空欄にするとバックエンドから自動取得します。現在のサーバーに紐づきます。",
            "testSuccess": "成功",
            "testFailed": "失敗",
            "appCopyright": "© 2026 終活 App. All rights reserved.",
            "maleGender": "男性",
            "femaleGender": "女性",
            "monitorNormalTitle": "監視は正常です",
            "monitorNormalDesc": "すべて順調です。定期的にチェックインしてください。",
            "monitorWarningTitle": "警告：期限超過",
            "monitorWarningDesc": "チェックイン時間を過ぎています。できるだけ早くチェックインしてください。",
            "monitorDangerTitle": "危険：オフライン超過",
            "monitorDangerDesc": "オフライン状態で期限超過です。すぐにチェックインしてください！",
            "scanFamilyTitle": "家族をスキャンして連携",
            "scanFamilySubtitle": "家族の招待コードをスキャンしてすばやく連携します",
            "scanFamilyButton": "スキャン開始",
            "shareQRCodeTitle": "自分のQRコードを共有",
            "shareQRCodeSubtitle": "家族が下のQRコードを読み取って連携できます",
            "shareQRCodeButton": "QRコードを見る",
            "manualInviteTitle": "招待コードを手動入力",
            "manualInviteSubtitle": "スキャンできない場合は6桁の招待コードを手入力できます",
            "manualInviteButton": "今すぐ入力",
            "familyLimitReached": "家族の上限に達しました。会員プランでさらに登録できます。",
            "invalidQRCode": "無効なQRコード",
            "loadingFamilyListTitle": "家族リストを読み込み中...",
            "noFamilyBoundTitle": "まだ家族は登録されていません",
            "noFamilyBoundHint": "上の機能で家族を登録し、お互いを見守りましょう。",
            "familyCountSuffix": "人",
            "checkingNormal": "チェックイン正常",
            "checkingOverdue": "期限超過、ユーザーのアプリ起動を待機中",
            "checkingSevere": "深刻な期限超過",
            "qrGenerating": "生成中...",
            "qrFetching": "取得中...",
            "closeButton": "閉じる",
            "bindRelationTitle": "関係を解除",
            "bindRelationMessage": "本当に %@ さんとの家族関係を解除しますか？この操作は元に戻せません。",
            "noRecordPrefix": "最終チェックイン：記録なし",
            "inviteCodePlaceholder": "6桁の招待コード",
            "familyLimitCurrent": "最大 %@ 人の家族",
            "familyLimitTarget": "会員プランでより多く登録できます",
            "myTasks": "私の項目",
            "viewAll": "すべて見る",
            "receivedCapsules": "受け取ったタイムカプセル",
            "all": "すべて",
            "noReceivedCapsules": "まだ受信したカプセルはありません",
            "receivedCapsuleHint": "家族から共有されたカプセルがここに表示されます。",
            "from": "送信元",
            "unread": "未読",
            "read": "既読",
            "settingsTitle": "設定",
            "notificationSettings": "通知設定",
            "deviceInfo": "端末情報",
            "avatar": "アバター",
            "name": "名前",
            "phone": "電話番号",
            "profileLoginAccount": "ログインID",
            "identityInfo": "身分情報",
            "serverAddress": "サーバーアドレス",
            "testConnection": "接続をテスト",
            "serverConfig": "サーバー設定",
            "aboutApp": "このアプリについて",
            "appInfo": "アプリ情報",
            "contactUs": "お問い合わせ",
            "save": "保存",
            "cancel": "キャンセル",
            "currentVersionTitle": "現在のバージョン",
            "currentVersionValue": "v%@",
            "openMembership": "会員登録",
            "limitedOffer": "期間限定 >",
            "membershipValid": "会員有効",
            "locationPermission": "位置情報権限",
            "goSettings": "設定へ",
            "locationAlwaysHint": "安全のため、「常に許可」の位置情報を有効にすることをおすすめします。アプリを閉じていても位置を取得できます。",
            "prompt": "ヒント",
            "positionAlways": "常に許可",
            "today": "今日",
            "steps": "歩",
            "updateTime": "最終更新",
            "user": "ユーザー",
            "unboundPhone": "未登録の電話番号",
            "unknown": "不明",
            "backgroundLocationOn": "バックグラウンド位置情報オン",
            "whenInUseOnly": "使用中のみ許可",
            "denied": "拒否済み",
            "notSet": "未設定",
            "gender": "性別",
            "ethnicity": "民族",
            "idCard": "身分證號",
            "address": "住所",
            "status": "状態",
            "testing": "テスト中...",
            "notTested": "未テスト",
            "saveAndRestart": "保存して再起動",
            "appInformation": "アプリ情報",
            "contactEmail": "サポートメール",
            "legalDisclosure": "電子遺言の効力",
            "version": "バージョン",
            "themeGuide": "テーマ設定はアプリ全体の外観に影響します。お好みの配色を選んでください。"
        ],
        "korean": [
            "appName": "종활",
            "appTagline": "삶에는 품격을, 작별에는 온기를",
            "loginTitle": "로그인",
            "loginSubtitle": "계정 또는 휴대폰 + 비밀번호/인증코드로 로그인",
            "identifierPlaceholder": "계정 또는 휴대폰",
            "passwordPlaceholder": "비밀번호",
            "captchaPlaceholder": "이미지 인증",
            "captchaRefresh": "새로고침",
            "loginButton": "로그인",
            "forgotPassword": "비밀번호를 잊으셨나요?",
            "noAccount": "계정이 없으신가요?",
            "registerNow": "지금 등록",
            "registerTitle": "계정 등록",
            "registerName": "이름",
            "registerAccount": "계정 (4-30자)",
            "registerPhoneOptional": "휴대폰 번호(선택, 등록 후 변경 불가)",
            "registerPhoneHelp": "휴대폰 없이도 등록할 수 있습니다. 입력하면 이후 한 번만 로그인 연결용으로 사용할 수 있으며 변경할 수 없습니다.",
            "registerCaptcha": "인증 코드",
            "registerPassword": "비밀번호 설정 (8자 이상)",
            "registerConfirmPassword": "비밀번호 확인",
            "securityQuestionTitle": "비밀번호 복구 유일한 방법",
            "securityQuestionHelp": "등록 시 보안 질문과 답변을 반드시 선택하고 기억하세요. 비밀번호를 잊으면 이것만으로 복구할 수 있습니다.",
            "securityQuestionPicker": "보안 질문",
            "securityAnswer": "보안 답변",
            "securityQuestion1": "내 첫 번째 학교 이름은?",
            "securityQuestion2": "내가 가장 좋아하는 도시는?",
            "securityQuestion3": "어머니의 성은?",
            "securityQuestion4": "내가 가장 좋아하는 영화는?",
            "securityQuestion5": "어릴 때 가장 친했던 친구의 이름은?",
            "registerButton": "지금 등록",
            "alreadyHaveAccount": "이미 계정이 있나요?",
            "loginNow": "지금 로그인",
            "settings": "설정",
            "editProfile": "프로필 수정",
            "languageSettings": "언어",
            "appearance": "외관",
            "themeSettings": "테마",
            "followSystem": "시스템 따르기",
            "lightMode": "라이트 모드",
            "darkMode": "다크 모드",
            "selectLanguage": "언어 선택",
            "chinese": "중국어",
            "english": "영어",
            "japanese": "일본어",
            "korean": "한국어",
            "about": "정보",
            "back": "뒤로",
            "checkUpdate": "업데이트 확인",
            "currentVersion": "현재 버전",
            "officialSite": "공식 사이트",
            "privacyPolicy": "개인정보 처리방침",
            "termsOfService": "이용 약관",
            "customerEmail": "고객 이메일",
            "customerPhone": "고객 전화",
            "systemMaintenance": "시스템 점검 중",
            "pleaseRetry": "잠시 후 다시 시도하세요",
            "loading": "불러오는 중...",
            "tabHome": "홈",
            "tabCapsule": "타임 캡슐",
            "tabWills": "유언과 자산",
            "tabFamily": "가족 보호",
            "tabMe": "내 정보",
            "locationService": "위치 서비스",
            "enableLocation": "위치 서비스 사용",
            "locationDesc": "체크인 시 위치를 기록해 안전을 증명합니다. 비활성화하면 체크인 위치 기록을 사용할 수 없습니다.",
            "signInInterval": "체크인 간격",
            "silentMode": "무음 모드",
            "todaySteps": "오늘 걸음 수",
            "deviceBattery": "기기 배터리",
            "birthdayLabel": "생년월일",
            "birthdayPreview": "선택됨",
            "languageSection": "언어",
            "error": "오류",
            "confirm": "확인",
            "resetTitle": "비밀번호 재설정",
            "resetSubtitle": "비밀번호 찾기",
            "resetPasswordButton": "비밀번호 재설정",
            "returnLogin": "로그인으로 돌아가기",
            "resetSecurityTitle": "비밀번호 복구 유일한 방법",
            "resetSecurityHelp": "등록 시 선택한 보안 질문과 답변을 입력하세요. 반드시 기억하세요. 이것이 유일한 복구 방법입니다.",
            "appMaintenance": "시스템 점검 중입니다. 잠시 후 다시 시도하세요",
            "onboardingSafeCheckIn": "안전 체크인",
            "onboardingSafeCheckInDesc": "48시간마다 체크인하여 가족에게 안심을 주세요. 잊은 경우 가족 보호에 알림이 전달됩니다.",
            "onboardingCapsule": "타임 캡슐",
            "onboardingCapsuleDesc": "하고 싶은 말을 적고 미래에 보낼 시간을 설정하세요.",
            "onboardingWill": "사후 준비",
            "onboardingWillDesc": "재산 분배와 사후 준비 사항을 미리 정리할 수 있습니다.",
            "onboardingFamilyGuard": "가족 보호",
            "onboardingFamilyGuardDesc": "가족을 연결하면 서로의 체크인 상태와 기기 정보를 확인할 수 있습니다.",
            "onboardingCompanion": "따뜻한 동행",
            "onboardingCompanionDesc": "매일 함께 걸으며 후회 없는 사랑을 남기세요.",
            "nextPage": "다음",
            "skip": "건너뛰기",
            "startUsing": "시작하기",
            "versionUpdate": "버전 업데이트",
            "updateNow": "지금 업데이트",
            "later": "나중에",
            "newVersionFound": "새 버전 발견",
            "capsuleDetail": "캡슐 상세",
            "textContent": "텍스트 내용",
            "audioContent": "음성 내용",
            "videoContent": "동영상 내용",
            "clickToPlay": "재생하려면 탭하세요",
            "dateInfo": "날짜 정보",
            "sendDate": "발송일",
            "createdDate": "생성일",
            "sent": "보냄",
            "pendingSend": "대기 중",
            "noContent": "(내용 없음)",
            "deleteCapsule": "캡슐 삭제",
            "deleteCapsuleMessage": "캡슐 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "playFailed": "재생 실패",
            "editCapsule": "캡슐 편집",
            "deleteAction": "삭제",
            "done": "완료",
            "willAndAssets": "유언과 자산",
            "myWills": "내 유언",
            "assetManagement": "자산 관리",
            "addCustomWill": "사용자 유언 추가",
            "previewWill": "유언 미리보기",
            "addAsset": "자산 추가",
            "fillingProgress": "작성 진행",
            "progressHint": "더 완성될수록 의도가 더 명확해집니다",
            "completedItems": "완료 %@ 개",
            "totalItems": "총 %@ 개",
            "deleteAsset": "자산 삭제",
            "deleteAssetMessage": "자산 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "deleteWill": "유언 삭제",
            "deleteWillMessage": "유언 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "familyGuard": "가족 보호",
            "loadingFamilyList": "가족 목록을 불러오는 중...",
            "linkedFamily": "연결된 가족",
            "noFamilyBound": "아직 연결된 가족이 없습니다",
            "familyGuardHint": "위 기능을 사용해 가족을 연결하고 서로 지켜보세요.",
            "shareInviteCode": "초대 코드 공유",
            "refreshQRCode": "QR 코드 새로고침",
            "inviteCode": "초대 코드",
            "fetching": "가져오는 중...",
            "manualInviteHint": "초대 코드를 직접 입력해 연결할 수 있습니다.",
            "copyInviteCode": "초대 코드 복사",
            "close": "닫기",
            "lastCheckIn": "마지막 체크인",
            "noRecord": "기록 없음",
            "pendingAcceptance": "대기 중",
            "removeRelation": "관계 해제",
            "removeRelationMessage": "%@ 과의 가족 관계를 해제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "manualInvite": "초대 코드 직접 입력",
            "binding": "연결 중...",
            "bindNow": "지금 연결",
            "bindSuccess": "연결 성공",
            "bindFailed": "연결 실패",
            "homeWithYou": "종활과 함께",
            "familyProtected": "가족을 지키고 있습니다",
            "familyCheckStatus": "가족 체크인 상태 보기",
            "autoCheckIn": "앱을 열면 자동 체크인됩니다",
            "safeCheckIn": "안전 체크인",
            "familyGuarding": "가족 보호 중",
            "notificationsMuted": "모든 체크인 알림이 꺼졌습니다",
            "notificationsMuteHelp": "켜두면 체크인 알림이 전송되지 않습니다",
            "phoneBoundLocked": "휴대폰 번호가 이미 등록되어 변경할 수 없습니다. 로그인에 사용할 수 있습니다.",
            "phoneBindingHint": "휴대폰 번호 등록은 한 번만 가능하며 이후 변경할 수 없습니다.",
            "phoneFormatError": "휴대폰 번호 형식이 올바르지 않습니다. 11자리 숫자를 입력하세요.",
            "firstBindPhoneRequired": "먼저 휴대폰 번호를 등록하세요. 이후에는 변경할 수 없습니다.",
            "saveProfile": "프로필 저장",
            "profileSaved": "프로필이 저장되었으며 로그인 상태가 유지됩니다",
            "restartRequired": "변경 사항은 앱을 다시 시작해야 적용됩니다",
            "automaticFetchRecommended": "자동 가져오기(권장)",
            "leaveBlankAuto": "비워두면 백엔드에서 자동으로 가져오며 현재 서버에 연결됩니다.",
            "testSuccess": "성공",
            "testFailed": "실패",
            "appCopyright": "© 2026 Zhonghuo App. All rights reserved.",
            "maleGender": "남성",
            "femaleGender": "여성",
            "monitorNormalTitle": "모니터링 정상",
            "monitorNormalDesc": "모든 것이 정상입니다. 정기적으로 체크인하세요.",
            "monitorWarningTitle": "경고: 시간 초과",
            "monitorWarningDesc": "체크인 시간이 지났습니다. 가능한 빨리 체크인하세요.",
            "monitorDangerTitle": "위험: 오프라인 초과",
            "monitorDangerDesc": "오프라인 상태로 시간 초과되었습니다. 지금 바로 체크인하세요!",
            "scanFamilyTitle": "가족 스캔하여 연결",
            "scanFamilySubtitle": "가족의 초대 코드를 스캔해 빠르게 연결합니다",
            "scanFamilyButton": "스캔 시작",
            "shareQRCodeTitle": "내 QR 코드 공유",
            "shareQRCodeSubtitle": "가족이 아래 QR 코드를 스캔해 연결할 수 있습니다",
            "shareQRCodeButton": "QR 코드 보기",
            "manualInviteTitle": "초대 코드 수동 입력",
            "manualInviteSubtitle": "스캔할 수 없으면 6자리 초대 코드를 입력할 수 있습니다",
            "manualInviteButton": "지금 입력",
            "familyLimitReached": "가족 수 한도에 도달했습니다. 멤버십을 업그레이드하여 더 추가할 수 있습니다.",
            "invalidQRCode": "유효하지 않은 QR 코드",
            "loadingFamilyListTitle": "가족 목록을 불러오는 중...",
            "noFamilyBoundTitle": "아직 연결된 가족이 없습니다",
            "noFamilyBoundHint": "위 기능을 사용해 가족을 연결하고 서로를 돌보세요.",
            "familyCountSuffix": "명",
            "checkingNormal": "체크인 정상",
            "checkingOverdue": "시간 초과, 사용자가 앱을 열기를 기다리는 중",
            "checkingSevere": "심각한 시간 초과",
            "qrGenerating": "생성 중...",
            "qrFetching": "불러오는 중...",
            "closeButton": "닫기",
            "bindRelationTitle": "관계 해제",
            "bindRelationMessage": "%@ 님과의 가족 관계를 해제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "noRecordPrefix": "마지막 체크인: 기록 없음",
            "inviteCodePlaceholder": "6자리 초대 코드",
            "familyLimitCurrent": "최대 %@명의 가족",
            "familyLimitTarget": "멤버십으로 더 많이 연결할 수 있습니다",
            "myTasks": "내 항목",
            "viewAll": "모두 보기",
            "receivedCapsules": "받은 타임 캡슐",
            "all": "전체",
            "noReceivedCapsules": "아직 받은 캡슐이 없습니다",
            "receivedCapsuleHint": "가족이 공유한 캡슐이 여기 표시됩니다.",
            "from": "발신",
            "unread": "읽지 않음",
            "read": "읽음",
            "settingsTitle": "설정",
            "notificationSettings": "알림 설정",
            "deviceInfo": "기기 정보",
            "avatar": "아바타",
            "name": "이름",
            "phone": "휴대폰 번호",
            "profileLoginAccount": "로그인 계정",
            "identityInfo": "신원 정보",
            "serverAddress": "서버 주소",
            "testConnection": "연결 테스트",
            "serverConfig": "서버 설정",
            "aboutApp": "정보",
            "appInfo": "앱 정보",
            "contactUs": "문의하기",
            "save": "저장",
            "cancel": "취소",
            "currentVersionTitle": "현재 버전",
            "currentVersionValue": "v%@",
            "openMembership": "멤버십 열기",
            "limitedOffer": "기간 한정 >",
            "membershipValid": "멤버십 활성",
            "locationPermission": "위치 권한",
            "goSettings": "설정으로 이동",
            "locationAlwaysHint": "안전을 위해 \"항상 허용\" 위치 권한을 켜는 것을 권장합니다. 앱을 열지 않아도 위치를 기록할 수 있습니다.",
            "prompt": "안내",
            "positionAlways": "항상 허용",
            "today": "오늘",
            "steps": "걸음",
            "updateTime": "마지막 업데이트",
            "user": "사용자",
            "unboundPhone": "연결되지 않은 전화번호",
            "unknown": "알 수 없음",
            "backgroundLocationOn": "백그라운드 위치 사용 중",
            "whenInUseOnly": "사용 중에만 허용",
            "denied": "거부됨",
            "notSet": "설정 안 됨",
            "gender": "성별",
            "ethnicity": "민족",
            "idCard": "신분증 번호",
            "address": "주소",
            "status": "상태",
            "testing": "테스트 중...",
            "notTested": "미테스트",
            "saveAndRestart": "저장 후 재시작",
            "appInformation": "앱 정보",
            "contactEmail": "고객 이메일",
            "legalDisclosure": "전자 유언 효력",
            "version": "버전",
            "themeGuide": "테마 설정은 앱 전체 외관 색상에 영향을 줍니다. 원하는 색 구성표를 선택하세요."
        ]
    ]
}

enum AppLocalization {
    static func dateString(for date: Date) -> String {
        switch AppLanguageManager.shared.language {
        case .chinese:
            return ChineseDateFormatter.dateFormatter.string(from: date)
        case .english:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        case .japanese:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        case .korean:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy년 MM월 dd일"
            return formatter.string(from: date)
        }
    }
}
