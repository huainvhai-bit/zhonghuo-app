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
                checkinIntervalHours
                notificationReminderThresholdHours
                notificationPushIntervalHours
                smsIsDevelopment
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
            // 解析配置
            let checkinHours = configData["checkinIntervalHours"] as? Int ?? 48
            let reminderHours = configData["notificationReminderThresholdHours"] as? Int ?? 12
            let pushInterval = configData["notificationPushIntervalHours"] as? Int ?? 2
            _ = configData["smsIsDevelopment"] as? Int ?? 1
            
            self.systemConfig = SystemConfig(
                checkinReminderThresholdHours: Double(reminderHours),
                checkinReminderIntervalHours: Double(pushInterval),
                minimumEmergencyContacts: 2,
                checkinIntervalHours: Double(checkinHours),
                offlineTimeoutHours: 24.0,
                appVersionLatest: "2.0.0",
                appVersionForceUpdate: "1.0.0",
                appMaintenanceMode: false,
                appMaintenanceMessage: "系统维护中，请稍后再试"
            )
            
            // 检查后端是否在线
            self.isBackendOnline = true
            print("✅ 服务器配置已更新")
        }
    }
}
