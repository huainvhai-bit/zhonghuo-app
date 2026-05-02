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
    case closeCheckIn
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
            "appTagline": "记录重要时光，安心整理生活",
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
            "tabCapsule": "时光留言",
            "tabWills": "事项与资产",
            "tabFamily": "亲友共享",
            "tabMe": "我的",
            "locationService": "状态显示",
            "enableLocation": "状态显示已关闭",
            "locationDesc": "本版本不使用状态显示相关功能，不再记录或发送信息。",
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
            "onboardingSafeCheckIn": "签到记录",
            "onboardingSafeCheckInDesc": "打开 App 即可更新签到记录。本机提醒只会提醒您本人，不会自动通知任何联系人。",
            "onboardingCapsule": "时光留言",
            "onboardingCapsuleDesc": "写下想说的话，保存文字、语音或视频。留言只有在您主动点击发送后，已添加的用户才可查看。",
            "onboardingWill": "重要事项",
            "onboardingWillDesc": "记录资产、个人事务和安排。内置模板帮助您把重要事项整理清楚。",
            "onboardingFamilyGuard": "亲友共享",
            "onboardingFamilyGuardDesc": "添加并确认后，可查看彼此的最新签到记录。",
            "onboardingCompanion": "温暖陪伴",
            "onboardingCompanionDesc": "终活帮助您记录重要时光和个人事项，让整理更清楚、更安心。",
            "nextPage": "下一页",
            "skip": "跳过",
            "startUsing": "开始使用",
            "versionUpdate": "版本更新",
            "updateNow": "立即更新",
            "later": "稍后再说",
            "newVersionFound": "发现新版本",
            "capsuleDetail": "留言详情",
            "textContent": "文字内容",
            "audioContent": "语音内容",
            "videoContent": "视频内容",
            "clickToPlay": "点击播放",
            "dateInfo": "日期信息",
            "sendDate": "记录日期",
            "createdDate": "创建日期",
            "sent": "已手动发送",
            "pendingSend": "草稿",
            "noContent": "（无内容）",
            "deleteCapsule": "删除留言",
            "deleteCapsuleMessage": "确定要删除留言「%@」吗？此操作不可恢复。",
            "playFailed": "播放失败",
            "editCapsule": "编辑留言",
            "deleteAction": "删除",
            "done": "完成",
            "willAndAssets": "事项与资产",
            "myWills": "重要事项",
            "assetManagement": "资产管理",
            "addCustomWill": "新增自定义事项",
            "previewWill": "预览事项",
            "addAsset": "添加资产",
            "fillingProgress": "填写进度",
            "progressHint": "完成度越高，您的意愿就越清晰",
            "completedItems": "已完成 %@ 项",
            "totalItems": "共 %@ 项",
            "deleteAsset": "删除资产",
            "deleteAssetMessage": "确定要删除资产「%@」吗？此操作不可恢复。",
            "deleteWill": "删除事项",
            "deleteWillMessage": "确定要删除事项「%@」吗？此操作不可恢复。",
            "familyGuard": "亲友共享",
            "loadingFamilyList": "正在加载添加列表...",
            "linkedFamily": "已添加的用户",
            "noFamilyBound": "暂时还没有添加用户",
            "familyGuardHint": "开启后首页显示无需签到，仅保留本机状态展示",
            "closeCheckIn": "关闭签到",
            "shareInviteCode": "展示我的邀请码",
            "refreshQRCode": "刷新二维码",
            "inviteCode": "邀请码",
            "fetching": "正在获取...",
            "manualInviteHint": "可手动输入邀请码添加",
            "copyInviteCode": "复制邀请码",
            "close": "关闭",
            "lastCheckIn": "最近签到",
            "noRecord": "暂无记录",
            "pendingAcceptance": "待接受",
            "removeRelation": "解除关系",
            "removeRelationMessage": "确定要与 %@ 解除添加关系吗？此操作不可恢复。",
            "manualInvite": "手动输入邀请码",
            "binding": "绑定中...",
            "bindNow": "立即绑定",
            "bindSuccess": "绑定成功",
            "bindFailed": "绑定失败",
            "homeWithYou": "终活记录重要时光",
            "familyProtected": "当前无需签到",
            "familyCheckStatus": "首页已切换为无需签到",
            "autoCheckIn": "打开 App 即可自动更新记录",
            "safeCheckIn": "签到记录",
            "familyGuarding": "无需签到",
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
            "monitorWarningTitle": "签到记录待更新",
            "monitorWarningDesc": "签到记录已到提醒时间，请打开 App 更新",
            "monitorDangerTitle": "记录长时间未更新",
            "monitorDangerDesc": "请打开 App 更新签到记录",
            "scanFamilyTitle": "扫码添加用户",
            "scanFamilySubtitle": "扫描对方的邀请码，双方确认后建立添加关系",
            "scanFamilyButton": "开始扫码",
            "shareQRCodeTitle": "展示我的二维码",
            "shareQRCodeSubtitle": "对方扫描下方二维码后，需要双方确认才会添加",
            "shareQRCodeButton": "查看二维码",
            "manualInviteTitle": "手动输入邀请码",
            "manualInviteSubtitle": "如果无法扫码，可以手动输入 6 位邀请码",
            "manualInviteButton": "立即输入",
            "familyLimitReached": "添加人数已达上限，升级会员可添加更多用户",
            "invalidQRCode": "无效的二维码",
            "loadingFamilyListTitle": "正在加载添加列表...",
            "noFamilyBoundTitle": "暂时还没有添加用户",
            "noFamilyBoundHint": "使用上方功能添加用户，双方确认后可查看最近同步记录",
            "familyCountSuffix": "人",
            "checkingNormal": "记录正常",
            "checkingOverdue": "记录待更新",
            "checkingSevere": "长时间未更新",
            "qrGenerating": "正在生成...",
            "qrFetching": "正在获取...",
            "closeButton": "关闭",
            "bindRelationTitle": "解除关系",
            "bindRelationMessage": "确定要与 %@ 解除添加关系吗？此操作不可恢复。",
            "noRecordPrefix": "最近签到：暂无记录",
            "inviteCodePlaceholder": "6 位邀请码",
            "familyLimitCurrent": "当前最多 %@ 位添加用户",
            "familyLimitTarget": "会员版可添加更多用户",
            "myTasks": "我的事务",
            "viewAll": "查看全部",
            "receivedCapsules": "我收到的时光留言",
            "all": "全部",
            "noReceivedCapsules": "暂无收到的留言",
            "receivedCapsuleHint": "对方手动发送的留言会出现在这里",
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
            "locationPermission": "状态显示",
            "goSettings": "去设置",
            "locationAlwaysHint": "本版本不使用定位功能，可保持状态显示关闭。",
            "prompt": "提示",
            "positionAlways": "始终允许",
            "today": "今日",
            "steps": "步",
            "updateTime": "最后更新",
            "user": "用户",
            "unboundPhone": "未绑定手机号",
            "unknown": "未知",
            "backgroundLocationOn": "状态显示已关闭",
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
            "legalDisclosure": "重要事项说明",
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
            "tabCapsule": "Time Messages",
            "tabWills": "Notes & Assets",
            "tabFamily": "Family Sharing",
            "tabMe": "Me",
            "locationService": "Status Display",
            "enableLocation": "Enable status display",
            "locationDesc": "Location is disabled in this version and will not be recorded or sent.",
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
            "onboardingSafeCheckIn": "Check-in records",
            "onboardingSafeCheckInDesc": "Open the app to update your check-in record. Local reminders only remind you and do not automatically notify others.",
            "onboardingCapsule": "Time Messages",
            "onboardingCapsuleDesc": "Save text, audio, or video messages. Family can view them only after you manually send them.",
            "onboardingWill": "Important Notes",
            "onboardingWillDesc": "Record assets, important matters, and personal arrangements for personal organization.",
            "onboardingFamilyGuard": "Family Sharing",
            "onboardingFamilyGuardDesc": "After both sides confirm, you can view each other's latest check-in time.",
            "onboardingCompanion": "Warm companionship",
            "onboardingCompanionDesc": "We walk with you every day so love has no regrets.",
            "nextPage": "Next",
            "skip": "Skip",
            "startUsing": "Get Started",
            "versionUpdate": "Version Update",
            "updateNow": "Update Now",
            "later": "Later",
            "newVersionFound": "New version found",
            "capsuleDetail": "Message Details",
            "textContent": "Text Content",
            "audioContent": "Audio Content",
            "videoContent": "Video Content",
            "clickToPlay": "Tap to play",
            "dateInfo": "Date Info",
            "sendDate": "Record Date",
            "createdDate": "Created Date",
            "sent": "Manually sent",
            "pendingSend": "Draft",
            "noContent": "(No content)",
            "deleteCapsule": "Delete Message",
            "deleteCapsuleMessage": "Delete message \"%@\"? This cannot be undone.",
            "playFailed": "Playback failed",
            "editCapsule": "Edit Message",
            "deleteAction": "Delete",
            "done": "Done",
            "willAndAssets": "Notes & Assets",
            "myWills": "Important Notes",
            "assetManagement": "Asset Management",
            "addCustomWill": "Add Custom Note",
            "previewWill": "Preview Notes",
            "addAsset": "Add Asset",
            "fillingProgress": "Completion",
            "progressHint": "The more complete, the clearer your wishes become",
            "completedItems": "Completed %@",
            "totalItems": "Total %@",
            "deleteAsset": "Delete Asset",
            "deleteAssetMessage": "Delete asset \"%@\"? This cannot be undone.",
            "deleteWill": "Delete Note",
            "deleteWillMessage": "Delete note \"%@\"? This cannot be undone.",
            "familyGuard": "Family Sharing",
            "loadingFamilyList": "Loading add list...",
            "linkedFamily": "Added users",
            "noFamilyBound": "No added users yet",
            "familyGuardHint": "Enable this to show no check-in needed and keep local status only.",
            "closeCheckIn": "Close Check-in",
            "shareInviteCode": "Add Invite Code",
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
            "removeRelationMessage": "Remove %@ from added users? This cannot be undone.",
            "manualInvite": "Enter Invite Code",
            "binding": "Binding...",
            "bindNow": "Bind Now",
            "bindSuccess": "Bound successfully",
            "bindFailed": "Binding failed",
            "homeWithYou": "Anxinji keeps important moments",
            "familyProtected": "No check-in mode is enabled",
            "familyCheckStatus": "View the other side's latest check-in time",
            "autoCheckIn": "Open the app to refresh local records automatically",
            "safeCheckIn": "Check-in records",
            "familyGuarding": "No check-in",
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
            "appCopyright": "© 2026 Anxinji App. All rights reserved.",
            "maleGender": "Male",
            "femaleGender": "Female",
            "monitorNormalTitle": "Monitoring normal",
            "monitorNormalDesc": "Everything is fine. Remember to check in regularly.",
            "monitorWarningTitle": "Check-in record needs update",
            "monitorWarningDesc": "Please open the app to update your check-in record.",
            "monitorDangerTitle": "Record not updated for a while",
            "monitorDangerDesc": "Please open the app to update your check-in record.",
            "scanFamilyTitle": "Scan to add users",
            "scanFamilySubtitle": "Scan the other side's invite code to add quickly",
            "scanFamilyButton": "Start scan",
            "shareQRCodeTitle": "Show my QR code",
            "shareQRCodeSubtitle": "The other side can scan this QR code; both sides must confirm before adding starts",
            "shareQRCodeButton": "View QR code",
            "manualInviteTitle": "Enter invite code manually",
            "manualInviteSubtitle": "If you can't scan, you can type the 6-digit invite code",
            "manualInviteButton": "Enter now",
            "familyLimitReached": "You have reached the add limit. Upgrade to add more users.",
            "invalidQRCode": "Invalid QR code",
            "loadingFamilyListTitle": "Loading add list...",
            "noFamilyBoundTitle": "No added users yet",
            "noFamilyBoundHint": "Use the options above to add users and view each other's latest check-in time.",
            "familyCountSuffix": "users",
            "checkingNormal": "Check-in normal",
            "checkingOverdue": "Record needs update",
            "checkingSevere": "Record not updated for a while",
            "qrGenerating": "Generating...",
            "qrFetching": "Loading...",
            "closeButton": "Close",
            "bindRelationTitle": "Remove added user",
            "bindRelationMessage": "Remove %@ from added users? This cannot be undone.",
            "noRecordPrefix": "Last check-in: no record",
            "inviteCodePlaceholder": "6-digit invite code",
            "familyLimitCurrent": "Up to %@ added users",
            "familyLimitTarget": "Premium allows more users",
            "myTasks": "My items",
            "viewAll": "View all",
            "receivedCapsules": "Received Messages",
            "all": "All",
            "noReceivedCapsules": "No received messages yet",
            "receivedCapsuleHint": "Messages manually sent by the other side will appear here.",
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
            "locationPermission": "Status Display",
            "goSettings": "Go to Settings",
            "locationAlwaysHint": "This version does not use location. You can keep status display disabled.",
            "prompt": "Notice",
            "positionAlways": "Always",
            "today": "Today",
            "steps": "steps",
            "updateTime": "Last updated",
            "user": "User",
            "unboundPhone": "Phone not bound",
            "unknown": "Unknown",
            "backgroundLocationOn": "Status display off",
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
            "legalDisclosure": "Important Notes Notice",
            "version": "Version",
            "themeGuide": "Theme settings affect the app's overall appearance. Choose the color scheme you like."
        ],
        "japanese": [
            "appName": "終活",
            "appTagline": "大切な時間を記録し、安心して整理する",
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
            "tabCapsule": "タイムメッセージ",
            "tabWills": "重要事項と資産",
            "tabFamily": "親友共有",
            "tabMe": "マイページ",
            "locationService": "状態表示",
            "enableLocation": "状態表示を有効にする",
            "locationDesc": "この版では状態表示のみを使用し、記録や送信は行いません。",
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
            "onboardingSafeCheckIn": "チェックイン記録",
            "onboardingSafeCheckInDesc": "アプリを開くとチェックイン記録を更新できます。本機通知は本人だけに届き、相手へ自動通知しません。",
            "onboardingCapsule": "タイムメッセージ",
            "onboardingCapsuleDesc": "テキスト、音声、動画メッセージを保存できます。相手が見られるのは、あなたが手動送信した後だけです。",
            "onboardingWill": "重要事項",
            "onboardingWillDesc": "資産、重要事項、個人メモを整理できます。",
            "onboardingFamilyGuard": "親友共有",
            "onboardingFamilyGuardDesc": "双方の確認後、お互いの最新チェックイン記録を確認できます。",
            "onboardingCompanion": "温かな伴走",
            "onboardingCompanionDesc": "毎日を一緒に歩み、後悔のない愛を残しましょう。",
            "nextPage": "次へ",
            "skip": "スキップ",
            "startUsing": "始める",
            "versionUpdate": "バージョン更新",
            "updateNow": "今すぐ更新",
            "later": "後で",
            "newVersionFound": "新しいバージョンがあります",
            "capsuleDetail": "メッセージ詳細",
            "textContent": "テキスト内容",
            "audioContent": "音声内容",
            "videoContent": "動画内容",
            "clickToPlay": "タップして再生",
            "dateInfo": "日付情報",
            "sendDate": "記録日",
            "createdDate": "作成日",
            "sent": "手動送信済み",
            "pendingSend": "下書き",
            "noContent": "（内容なし）",
            "deleteCapsule": "メッセージを削除",
            "deleteCapsuleMessage": "メッセージ「%@」を削除しますか？この操作は元に戻せません。",
            "playFailed": "再生に失敗しました",
            "editCapsule": "メッセージを編集",
            "deleteAction": "削除",
            "done": "完了",
            "willAndAssets": "重要事項と資産",
            "myWills": "重要事項",
            "assetManagement": "資産管理",
            "addCustomWill": "カスタム事項を追加",
            "previewWill": "事項をプレビュー",
            "addAsset": "資産を追加",
            "fillingProgress": "入力進捗",
            "progressHint": "完成度が高いほど、思いがより明確になります",
            "completedItems": "完了 %@ 件",
            "totalItems": "合計 %@ 件",
            "deleteAsset": "資産を削除",
            "deleteAssetMessage": "資産「%@」を削除しますか？この操作は元に戻せません。",
            "deleteWill": "事項を削除",
            "deleteWillMessage": "事項「%@」を削除しますか？この操作は元に戻せません。",
            "familyGuard": "親友共有",
            "loadingFamilyList": "追加一覧を読み込み中...",
            "linkedFamily": "追加済みユーザー",
            "noFamilyBound": "まだ追加されたユーザーはいません",
            "familyGuardHint": "有効にするとチェックイン不要を表示し、端末内の状態表示のみを残します。",
            "closeCheckIn": "チェックインを閉じる",
            "shareInviteCode": "招待コードを追加",
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
            "removeRelationMessage": "%@ を追加ユーザーから削除しますか？この操作は元に戻せません。",
            "manualInvite": "招待コードを手入力",
            "binding": "紐付け中...",
            "bindNow": "今すぐ紐付け",
            "bindSuccess": "紐付け成功",
            "bindFailed": "紐付け失敗",
            "homeWithYou": "大切な時間を記録します",
            "familyProtected": "チェックイン不要モードが有効です",
            "familyCheckStatus": "相手の最新チェックイン時刻を確認",
            "autoCheckIn": "アプリを開くとローカル記録が更新されます",
            "safeCheckIn": "チェックイン記録",
            "familyGuarding": "チェックイン不要",
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
            "appCopyright": "© 2026 终活 App. All rights reserved.",
            "maleGender": "男性",
            "femaleGender": "女性",
            "monitorNormalTitle": "監視は正常です",
            "monitorNormalDesc": "すべて順調です。定期的にチェックインしてください。",
            "monitorWarningTitle": "記録の更新が必要です",
            "monitorWarningDesc": "アプリを開いてチェックイン記録を更新してください。",
            "monitorDangerTitle": "記録が長時間更新されていません",
            "monitorDangerDesc": "アプリを開いてチェックイン記録を更新してください。",
            "scanFamilyTitle": "ユーザーを追加するためにスキャン",
            "scanFamilySubtitle": "相手の招待コードをスキャンしてすばやく追加します",
            "scanFamilyButton": "スキャン開始",
            "shareQRCodeTitle": "自分のQRコードを表示",
            "shareQRCodeSubtitle": "相手が下のQRコードを読み取り、双方確認後に追加を開始できます",
            "shareQRCodeButton": "QRコードを見る",
            "manualInviteTitle": "招待コードを手動入力",
            "manualInviteSubtitle": "スキャンできない場合は6桁の招待コードを手入力できます",
            "manualInviteButton": "今すぐ入力",
            "familyLimitReached": "追加上限に達しました。会員プランでさらに追加できます。",
            "invalidQRCode": "無効なQRコード",
            "loadingFamilyListTitle": "追加一覧を読み込み中...",
            "noFamilyBoundTitle": "まだ追加されたユーザーはいません",
            "noFamilyBoundHint": "上の機能でユーザーを追加し、お互いの最新チェックイン時刻を確認できます。",
            "familyCountSuffix": "ユーザー",
            "checkingNormal": "チェックイン正常",
            "checkingOverdue": "記録の更新が必要です",
            "checkingSevere": "記録が長時間更新されていません",
            "qrGenerating": "生成中...",
            "qrFetching": "取得中...",
            "closeButton": "閉じる",
            "bindRelationTitle": "追加ユーザーを削除",
            "bindRelationMessage": "本当に %@ さんを追加ユーザーから削除しますか？この操作は元に戻せません。",
            "noRecordPrefix": "最終チェックイン：記録なし",
            "inviteCodePlaceholder": "6桁の招待コード",
            "familyLimitCurrent": "最大 %@ 人の追加ユーザー",
            "familyLimitTarget": "会員プランでより多く追加できます",
            "myTasks": "私の項目",
            "viewAll": "すべて見る",
            "receivedCapsules": "受け取ったメッセージ",
            "all": "すべて",
            "noReceivedCapsules": "まだ受信したメッセージはありません",
            "receivedCapsuleHint": "相手が手動送信したメッセージがここに表示されます。",
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
            "locationPermission": "状態表示",
            "goSettings": "設定へ",
            "locationAlwaysHint": "この版では位置情報は使用しません。状態表示をオフのままにできます。",
            "prompt": "ヒント",
            "positionAlways": "常に許可",
            "today": "今日",
            "steps": "歩",
            "updateTime": "最終更新",
            "user": "ユーザー",
            "unboundPhone": "未登録の電話番号",
            "unknown": "不明",
            "backgroundLocationOn": "状態表示オフ",
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
            "legalDisclosure": "重要事項の説明",
            "version": "バージョン",
            "themeGuide": "テーマ設定はアプリ全体の外観に影響します。お好みの配色を選んでください。"
        ],
        "korean": [
            "appName": "终活",
            "appTagline": "중요한 시간을 기록하고 안심하게 정리",
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
            "tabCapsule": "타임 메시지",
            "tabWills": "중요 사항과 자산",
            "tabFamily": "친구 공유",
            "tabMe": "내 정보",
            "locationService": "상태 표시",
            "enableLocation": "상태 표시 사용",
            "locationDesc": "이 버전에서는 상태 표시만 사용하며 기록이나 전송도 하지 않습니다.",
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
            "onboardingSafeCheckIn": "체크인 기록",
            "onboardingSafeCheckInDesc": "앱을 열면 체크인 기록을 업데이트할 수 있습니다. 로컬 알림은 본인에게만 표시되며 가족에게 자동 알림을 보내지 않습니다.",
            "onboardingCapsule": "타임 메시지",
            "onboardingCapsuleDesc": "텍스트, 음성, 영상 메시지를 저장할 수 있습니다. 직접 보낸 후에만 가족이 볼 수 있습니다.",
            "onboardingWill": "중요 사항",
            "onboardingWillDesc": "자산, 가족 사항, 개인 메모를 정리할 수 있습니다.",
            "onboardingFamilyGuard": "친구 공유",
            "onboardingFamilyGuardDesc": "양쪽이 확인한 후 서로의 최신 체크인 기록을 볼 수 있습니다.",
            "onboardingCompanion": "따뜻한 동행",
            "onboardingCompanionDesc": "매일 함께 걸으며 후회 없는 사랑을 남기세요.",
            "nextPage": "다음",
            "skip": "건너뛰기",
            "startUsing": "시작하기",
            "versionUpdate": "버전 업데이트",
            "updateNow": "지금 업데이트",
            "later": "나중에",
            "newVersionFound": "새 버전 발견",
            "capsuleDetail": "메시지 상세",
            "textContent": "텍스트 내용",
            "audioContent": "음성 내용",
            "videoContent": "동영상 내용",
            "clickToPlay": "재생하려면 탭하세요",
            "dateInfo": "날짜 정보",
            "sendDate": "기록일",
            "createdDate": "생성일",
            "sent": "직접 보냄",
            "pendingSend": "초안",
            "noContent": "(내용 없음)",
            "deleteCapsule": "메시지 삭제",
            "deleteCapsuleMessage": "메시지 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "playFailed": "재생 실패",
            "editCapsule": "메시지 편집",
            "deleteAction": "삭제",
            "done": "완료",
            "willAndAssets": "중요 사항과 자산",
            "myWills": "중요 사항",
            "assetManagement": "자산 관리",
            "addCustomWill": "사용자 사항 추가",
            "previewWill": "사항 미리보기",
            "addAsset": "자산 추가",
            "fillingProgress": "작성 진행",
            "progressHint": "더 완성될수록 의도가 더 명확해집니다",
            "completedItems": "완료 %@ 개",
            "totalItems": "총 %@ 개",
            "deleteAsset": "자산 삭제",
            "deleteAssetMessage": "자산 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "deleteWill": "사항 삭제",
            "deleteWillMessage": "사항 \"%@\"을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "familyGuard": "친구 공유",
            "loadingFamilyList": "추가 목록을 불러오는 중...",
            "linkedFamily": "추가된 사용자",
            "noFamilyBound": "아직 추가된 사용자가 없습니다",
            "familyGuardHint": "켜면 체크인 불필요를 표시하고 기기 내 상태 표시만 남깁니다.",
            "closeCheckIn": "체크인 닫기",
            "shareInviteCode": "초대 코드 추가",
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
            "removeRelationMessage": "%@ 을 추가 사용자에서 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "manualInvite": "초대 코드 직접 입력",
            "binding": "연결 중...",
            "bindNow": "지금 연결",
            "bindSuccess": "연결 성공",
            "bindFailed": "연결 실패",
            "homeWithYou": "중요한 시간을 기록합니다",
            "familyProtected": "체크인 불필요 모드가 활성화되었습니다",
            "familyCheckStatus": "상대의 최신 체크인 시간 보기",
            "autoCheckIn": "앱을 열면 로컬 기록이 갱신됩니다",
            "safeCheckIn": "체크인 기록",
            "familyGuarding": "체크인 불필요",
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
            "monitorWarningTitle": "기록 업데이트 필요",
            "monitorWarningDesc": "앱을 열어 체크인 기록을 업데이트하세요.",
            "monitorDangerTitle": "기록이 오랫동안 업데이트되지 않음",
            "monitorDangerDesc": "앱을 열어 체크인 기록을 업데이트하세요.",
            "scanFamilyTitle": "사용자를 추가하려면 스캔",
            "scanFamilySubtitle": "상대의 초대 코드를 스캔해 빠르게 추가합니다",
            "scanFamilyButton": "스캔 시작",
            "shareQRCodeTitle": "내 QR 코드 표시",
            "shareQRCodeSubtitle": "상대가 아래 QR 코드를 스캔하고 양쪽 확인 후 추가가 시작됩니다",
            "shareQRCodeButton": "QR 코드 보기",
            "manualInviteTitle": "초대 코드 수동 입력",
            "manualInviteSubtitle": "스캔할 수 없으면 6자리 초대 코드를 입력할 수 있습니다",
            "manualInviteButton": "지금 입력",
            "familyLimitReached": "추가 한도에 도달했습니다. 멤버십을 업그레이드하여 더 추가할 수 있습니다.",
            "invalidQRCode": "유효하지 않은 QR 코드",
            "loadingFamilyListTitle": "추가 목록을 불러오는 중...",
            "noFamilyBoundTitle": "아직 추가된 사용자가 없습니다",
            "noFamilyBoundHint": "위 기능을 사용해 사용자를 추가하고 서로의 최신 체크인 시간을 확인하세요.",
            "familyCountSuffix": "명",
            "checkingNormal": "체크인 정상",
            "checkingOverdue": "기록 업데이트 필요",
            "checkingSevere": "기록이 오랫동안 업데이트되지 않음",
            "qrGenerating": "생성 중...",
            "qrFetching": "불러오는 중...",
            "closeButton": "닫기",
            "bindRelationTitle": "추가 사용자 삭제",
            "bindRelationMessage": "%@ 님을 추가 사용자에서 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            "noRecordPrefix": "마지막 체크인: 기록 없음",
            "inviteCodePlaceholder": "6자리 초대 코드",
            "familyLimitCurrent": "최대 %@명의 추가 사용자",
            "familyLimitTarget": "멤버십으로 더 많이 추가할 수 있습니다",
            "myTasks": "내 항목",
            "viewAll": "모두 보기",
            "receivedCapsules": "받은 메시지",
            "all": "전체",
            "noReceivedCapsules": "아직 받은 메시지가 없습니다",
            "receivedCapsuleHint": "상대가 직접 보낸 메시지가 여기에 표시됩니다.",
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
            "locationPermission": "상태 표시",
            "goSettings": "설정으로 이동",
            "locationAlwaysHint": "이 버전에서는 위치 정보를 사용하지 않습니다. 상태 표시를 꺼둘 수 있습니다.",
            "prompt": "안내",
            "positionAlways": "항상 허용",
            "today": "오늘",
            "steps": "걸음",
            "updateTime": "마지막 업데이트",
            "user": "사용자",
            "unboundPhone": "연결되지 않은 전화번호",
            "unknown": "알 수 없음",
            "backgroundLocationOn": "상태 표시 꺼짐",
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
            "legalDisclosure": "중요 사항 안내",
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
