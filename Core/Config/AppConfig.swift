//
//  AppConfig.swift
//  安心助手
//
//  应用配置文件 - 集中管理所有配置项
//

import Foundation

struct AppConfig {
    // MARK: - 合规模式

    /// 是否启用中国区送审收口模式
    /// 当前默认关闭，优先保留原有功能结构，仅通过具体开关弱化定位与自动同步。
    static let isChinaReviewMode = false

    /// 家人相关功能是否展示
    static var showsFamilyFeatures: Bool { true }

    /// 重要事项相关功能是否展示
    static var showsWillFeatures: Bool { true }

    /// 是否允许家人数据同步
    static var allowsFamilyDataSync: Bool { true }

    /// 是否允许重要事项数据同步
    static var allowsWillDataSync: Bool { true }

    // MARK: - API 配置
    
    /// 默认 API 服务器地址（HTTPS）
    static let defaultAPIURL = "https://zhonghuo.zhonghuo.xyz"
    
    /// API 请求超时时间（秒）
    static let apiRequestTimeout: TimeInterval = 15
    
    /// API 资源超时时间（秒）
    static let apiResourceTimeout: TimeInterval = 15
    
    /// Token 验证超时时间（秒）
    static let tokenValidationTimeout: TimeInterval = 5
    
    // MARK: - 签到配置
    
    /// 默认签到间隔（小时）
    static let defaultCheckInIntervalHours: Double = 48
    
    /// 签到提醒阈值（小时）- 剩余多少小时开始提醒
    static let checkInReminderThresholdHours: Double = 12
    
    /// 签到提醒间隔（小时）
    static let checkInReminderIntervalHours: Double = 2
    
    /// 离线超时阈值（小时）- 超过这个时间未签到会变成红色警告
    static let offlineTimeoutHours: Double = 24
    
    // MARK: - PDF 配置
    
    /// PDF 页面宽度（A4）
    static let pdfPageWidth: CGFloat = 595
    
    /// PDF 页面高度（A4）
    static let pdfPageHeight: CGFloat = 842
    
    /// PDF 内容边距
    static let pdfMargin: CGFloat = 50
    
    /// PDF 页脚高度
    static let pdfFooterHeight: CGFloat = 42
    
    /// PDF 分页阈值（距离页面底部多少像素开始新页）
    static let pdfPageBreakThreshold: CGFloat = 750
    
    // MARK: - UI 配置
    
    /// 动画默认持续时间
    static let defaultAnimationDuration: TimeInterval = 0.3
    
    /// 列表项最小高度
    static let minListItemHeight: CGFloat = 44
    
    // MARK: - 日志配置
    
    /// 生产环境是否启用日志
    static let enableLogsInProduction: Bool = false
    
    /// 是否启用详细日志
    static let enableVerboseLogs: Bool = false
    
    /// 是否启用网络请求日志
    static let enableNetworkLogs: Bool = false
}
