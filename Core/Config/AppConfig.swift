//
//  AppConfig.swift
//  终活
//
//  应用配置文件 - 集中管理所有配置项
//

import Foundation

struct AppConfig {
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
    
    // MARK: - 位置服务配置
    
    /// 位置更新距离过滤器（米）- 移动多少米才更新
    static let locationDistanceFilter: Double = 10
    
    /// 持续定位时的距离过滤器（米）
    static let continuousLocationDistanceFilter: Double = 5
    
    /// 位置上传间隔（秒）
    static let locationUploadInterval: TimeInterval = 3
    
    /// 位置数据最大年龄（秒）- 超过这个时间的数据不使用
    static let maxLocationAge: TimeInterval = 120
    
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
