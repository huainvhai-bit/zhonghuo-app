//
//  ConfigManager.swift
//  终活
//
//  服务器配置管理器
//  职责：动态获取和管理服务器地址、系统配置
//

import Foundation

/// 服务器配置管理器
/// 职责：动态获取服务器地址、解析系统配置
@MainActor
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    private let apiClient = APIClient.shared
    private let defaultAPIURL = AppConfig.defaultAPIURL
    
    // MARK: - 配置状态
    @Published var serverConfig: ServerConfig?
    @Published var smsConfig: ServerConfig.ServerConfigData.SMSConfig?
    @Published var isBackendOnline: Bool = false
    @Published var systemConfig: SystemConfig = SystemConfig()
    
    // MARK: - API 地址
    static nonisolated(unsafe) var baseURL: String = ""
    static nonisolated(unsafe) var apiURL: String = ""
    
    /// 初始化时获取配置
    func initialize() async {
        // 尝试从 UserDefaults 读取已保存的 URL
        if let savedURL = UserDefaults.standard.string(forKey: "serverURL") {
            ConfigManager.apiURL = savedURL
            ConfigManager.baseURL = savedURL
            print("📍 使用已保存的服务器地址：\(savedURL)")
        } else {
            ConfigManager.apiURL = defaultAPIURL
            ConfigManager.baseURL = defaultAPIURL
            print("📍 使用默认服务器地址：\(defaultAPIURL)")
        }
        
        // 尝试获取配置
        await fetchServerConfigIfNeeded()
    }
    
    /// 服务器地址变更时的通知处理
    func handleServerURLChange(_ newURL: String) async {
        ConfigManager.apiURL = newURL
        ConfigManager.baseURL = newURL
        UserDefaults.standard.set(newURL, forKey: "serverURL")
        
        // 重新获取配置
        await fetchServerConfigIfNeeded()
    }
    
    /// 获取服务器配置（如果尚未获取）
    func fetchServerConfigIfNeeded() async {
        guard serverConfig == nil else {
            print("✅ 配置已存在，跳过获取")
            return
        }
        
        await fetchServerConfig(from: ConfigManager.apiURL)
    }
    
    /// 从服务器获取 API 配置
    func fetchServerConfig(from baseURL: String) async {
        if DebugConfig.enableNetworkLogs {
            print("🌐 请求配置（GraphQL）：\(baseURL)")
        }
        
        let query = """
        query {
            getConfig {
                checkinReminderThresholdHours
                checkinReminderIntervalHours
                overduePushIntervalHours
                maintenanceMode
                maintenanceMessage
                smsIsDevelopment
                memberPriceMonthly
                memberPriceYearly
                freeMaxCapsules
                freeMaxMediaCapsules
                freeMaxVideoMinutes
                freeMaxWillModules
                freeMaxFamily
                freeCloudBackup
                freeDataExport
                freeAiAssist
                premiumMaxCapsules
                premiumMaxMediaCapsules
                premiumMaxVideoMinutes
                premiumMaxWillModules
                premiumMaxFamily
                premiumCloudBackup
                premiumDataExport
                premiumAiAssist
            }
        }
        """
        
        let client = APIClient(baseURL: baseURL)
        let response = try? await client.query(query)
        
        guard let data = response?["data"] as? [String: Any],
              let configData = data["getConfig"] as? [String: Any] else {
            print("❌ 配置加载失败")
            return
        }
        
        await MainActor.run {
            // 解析配置（签到间隔由用户在 App 设置，后端不再控制）
            let reminderHours = configData["checkinReminderThresholdHours"] as? Int ?? 12
            let pushInterval = configData["checkinReminderIntervalHours"] as? Int ?? 2
            let overduePushInterval = configData["overduePushIntervalHours"] as? Int ?? 1
            _ = configData["smsIsDevelopment"] as? Int ?? 1
            
            // 会员价格配置
            let priceMonthly = configData["memberPriceMonthly"] as? Double ?? 8.0
            let priceYearly = configData["memberPriceYearly"] as? Double ?? 68.0
            
            // 免费版限制
            let freeMaxCapsules = configData["freeMaxCapsules"] as? Int ?? 5
            let freeMaxMediaCapsules = configData["freeMaxMediaCapsules"] as? Int ?? 2
            let freeMaxVideoMinutes = configData["freeMaxVideoMinutes"] as? Int ?? 2
            let freeMaxWillModules = configData["freeMaxWillModules"] as? Int ?? 3
            let freeMaxFamily = configData["freeMaxFamily"] as? Int ?? 1
            let freeCloudBackup = configData["freeCloudBackup"] as? Bool ?? false
            let freeDataExport = configData["freeDataExport"] as? Bool ?? false
            let freeAiAssist = configData["freeAiAssist"] as? Bool ?? false
            
            // 会员版限制
            let premiumMaxCapsules = configData["premiumMaxCapsules"] as? Int ?? 20
            let premiumMaxMediaCapsules = configData["premiumMaxMediaCapsules"] as? Int ?? 10
            let premiumMaxVideoMinutes = configData["premiumMaxVideoMinutes"] as? Int ?? 5
            let premiumMaxWillModules = configData["premiumMaxWillModules"] as? Int ?? 999
            let premiumMaxFamily = configData["premiumMaxFamily"] as? Int ?? 5
            let premiumCloudBackup = configData["premiumCloudBackup"] as? Bool ?? true
            let premiumDataExport = configData["premiumDataExport"] as? Bool ?? true
            let premiumAiAssist = configData["premiumAiAssist"] as? Bool ?? true
            
            // 维护模式配置
            let maintenanceMode = configData["maintenanceMode"] as? Bool ?? false
            let maintenanceMessage = configData["maintenanceMessage"] as? String ?? "系统维护中，请稍后再试"
            
            self.systemConfig = SystemConfig(
                checkinReminderThresholdHours: Double(reminderHours),
                checkinReminderIntervalHours: Double(pushInterval),
                overduePushIntervalHours: Double(overduePushInterval),
                minimumEmergencyContacts: 2,
                offlineTimeoutHours: 24.0,
                appVersionLatest: "2.0.0",
                appVersionForceUpdate: "1.0.0",
                appMaintenanceMode: maintenanceMode,
                appMaintenanceMessage: maintenanceMessage,
                // 会员价格
                memberPriceMonthly: priceMonthly,
                memberPriceYearly: priceYearly,
                // 免费版限制
                freeMaxCapsules: freeMaxCapsules,
                freeMaxMediaCapsules: freeMaxMediaCapsules,
                freeMaxVideoMinutes: freeMaxVideoMinutes,
                freeMaxWillModules: freeMaxWillModules,
                freeMaxFamily: freeMaxFamily,
                freeCloudBackup: freeCloudBackup,
                freeDataExport: freeDataExport,
                freeAiAssist: freeAiAssist,
                // 会员版限制
                premiumMaxCapsules: premiumMaxCapsules,
                premiumMaxMediaCapsules: premiumMaxMediaCapsules,
                premiumMaxVideoMinutes: premiumMaxVideoMinutes,
                premiumMaxWillModules: premiumMaxWillModules,
                premiumMaxFamily: premiumMaxFamily,
                premiumCloudBackup: premiumCloudBackup,
                premiumDataExport: premiumDataExport,
                premiumAiAssist: premiumAiAssist
            )
            
            // ✅ 应用会员限制到 MembershipManager（已迁移到 DataManager）
            // MembershipManager.shared.applyLimits(
            //     freeMaxCapsules: freeMaxCapsules,
            //     freeMaxMediaCapsules: freeMaxMediaCapsules,
            //     freeMaxVideoMinutes: freeMaxVideoMinutes,
            //     premiumMaxCapsules: premiumMaxCapsules,
            //     premiumMaxMediaCapsules: premiumMaxMediaCapsules,
            //     premiumMaxVideoMinutes: premiumMaxVideoMinutes
            // )
            
            // 检查后端是否在线
            self.isBackendOnline = true
            print("✅ 服务器配置已更新（会员限制已应用）")
        }
    }
}
