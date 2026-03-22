//
//  AlertCenterView.swift
//  终活 - 告警中心（已合并到系统设置）
//

import SwiftUI

struct AlertCenterView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var alertHistory: [AlertRecord] = []
    @State private var alertSettings: AlertSettings = AlertSettings()
    @State private var showingSettings = false
    
    var body: some View {
        List {
            // 告警统计
            Section(header: Text("告警统计")) {
                HStack {
                    StatCard(title: "今日告警", value: "\(todayAlertCount)", icon: "bell.fill", color: .red)
                    StatCard(title: "本周告警", value: "\(weekAlertCount)", icon: "bell", color: .orange)
                    StatCard(title: "已处理", value: "\(handledCount)", icon: "checkmark.circle.fill", color: .green)
                }
                .padding(.vertical, 8)
            }
            
            // 告警设置
            Section(header: Text("告警设置")) {
                Toggle(isOn: $alertSettings.smsEnabled) {
                    Label("短信通知", systemImage: "message.fill")
                }
                .onChange(of: alertSettings.smsEnabled) { _ in
                    saveAlertSettings()
                }
                
                Toggle(isOn: $alertSettings.pushEnabled) {
                    Label("推送通知", systemImage: "bell.badge.fill")
                }
                .onChange(of: alertSettings.pushEnabled) { _ in
                    saveAlertSettings()
                }
                
                Toggle(isOn: $alertSettings.emailEnabled) {
                    Label("邮件通知", systemImage: "envelope.fill")
                }
                .onChange(of: alertSettings.emailEnabled) { _ in
                    saveAlertSettings()
                }
                
                NavigationLink(destination: AlertThresholdSettingsView()) {
                    Label("告警阈值", systemImage: "gauge")
                }
            }
            
            // 告警历史
            Section(header: Text("告警历史")) {
                if alertHistory.isEmpty {
                    Text("暂无告警记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(alertHistory) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
            
            // 操作
            Section {
                Button(action: clearAlertHistory) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("清除告警历史")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("告警中心")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadAlertHistory()
            loadAlertSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayAlertCount: Int {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        return alertHistory.filter { $0.createdAt >= startOfDay }.count
    }
    
    private var weekAlertCount: Int {
        let now = Date()
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        return alertHistory.filter { $0.createdAt >= startOfWeek }.count
    }
    
    private var handledCount: Int {
        return alertHistory.filter { $0.isHandled }.count
    }
    
    // MARK: - Methods
    
    private func loadAlertHistory() {
        Task {
            do {
                guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
                    print("⚠️ 加载失败：无 token")
                    return
                }
                
                let url = URL(string: "\(DataManager.apiURL)/api/alert.php?action=list&token=\(token)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 告警列表响应：\(httpResponse.statusCode)")
                }
                
                let result = try JSONDecoder().decode(AlertListResponse.self, from: data)
                
                if result.success {
                    alertHistory = result.data.map { apiAlert in
                        AlertRecord(
                            id: String(apiAlert.id),
                            type: AlertType(rawValue: apiAlert.type) ?? .checkinOverdue,
                            title: alertTitleForType(apiAlert.type),
                            message: apiAlert.message,
                            isHandled: apiAlert.isHandled == 1,
                            createdAt: Self.dateFormatter.date(from: apiAlert.createdAt) ?? Date()
                        )
                    }
                    print("✅ 加载告警历史成功，共 \(alertHistory.count) 条")
                } else {
                    print("❌ 加载失败：\(result.error ?? "未知错误")")
                }
            } catch {
                print("❌ 加载告警历史失败：\(error)")
            }
        }
    }
    
    private func loadAlertSettings() {
        Task {
            do {
                guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
                    print("⚠️ 加载失败：无 token")
                    return
                }
                
                let url = URL(string: "\(DataManager.apiURL)/api/alert.php?action=get_settings&token=\(token)")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 告警设置响应：\(httpResponse.statusCode)")
                }
                
                let result = try JSONDecoder().decode(AlertSettingsResponse.self, from: data)
                
                if result.success {
                    alertSettings = AlertSettings(
                        smsEnabled: result.data.smsEnabled == 1,
                        pushEnabled: result.data.pushEnabled == 1,
                        emailEnabled: result.data.emailEnabled == 1
                    )
                    print("✅ 加载告警设置成功")
                } else {
                    print("❌ 加载失败：\(result.error ?? "未知错误")")
                }
            } catch {
                print("❌ 加载告警设置失败：\(error)")
            }
        }
    }
    
    func saveAlertSettings() {
        Task {
            do {
                guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
                    print("⚠️ 保存失败：无 token")
                    return
                }
                
                var url = URL(string: "\(DataManager.apiURL)/api/alert.php?action=update_settings&token=\(token)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let body: [String: Any] = [
                    "sms_enabled": alertSettings.smsEnabled ? 1 : 0,
                    "push_enabled": alertSettings.pushEnabled ? 1 : 0,
                    "email_enabled": alertSettings.emailEnabled ? 1 : 0
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 保存告警设置响应：\(httpResponse.statusCode)")
                }
                
                let result = try JSONDecoder().decode(BaseResponse.self, from: data)
                
                if result.success {
                    print("✅ 保存告警设置成功")
                } else {
                    print("❌ 保存失败：\(result.error ?? "未知错误")")
                }
            } catch {
                print("❌ 保存告警设置失败：\(error)")
            }
        }
    }
    
    func handleAlert(alertId: String) {
        Task {
            do {
                guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
                    print("⚠️ 处理失败：无 token")
                    return
                }
                
                var url = URL(string: "\(DataManager.apiURL)/api/alert.php?action=handle&token=\(token)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let body: [String: Any] = ["alert_id": alertId]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 处理告警响应：\(httpResponse.statusCode)")
                }
                
                let result = try JSONDecoder().decode(BaseResponse.self, from: data)
                
                if result.success {
                    print("✅ 处理告警成功")
                    // 重新加载列表
                    loadAlertHistory()
                } else {
                    print("❌ 处理失败：\(result.error ?? "未知错误")")
                }
            } catch {
                print("❌ 处理告警失败：\(error)")
            }
        }
    }
    
    private func clearAlertHistory() {
        // TODO: 清除本地告警历史
        alertHistory.removeAll()
        print("🗑️ 清除告警历史成功")
    }
    
    // MARK: - Helper Methods
    
    private func alertTitleForType(_ type: String) -> String {
        switch type {
        case "checkin_timeout": return "签到超时"
        case "battery_low": return "电量过低"
        case "location_abnormal": return "位置异常"
        case "emergency_contact": return "紧急联系"
        default: return "系统告警"
        }
    }
}

// MARK: - Models

struct AlertRecord: Identifiable, Codable {
    let id: String
    let type: AlertType
    let title: String
    let message: String
    let isHandled: Bool
    let createdAt: Date
}

enum AlertType: String, Codable {
    case checkinOverdue = "签到超时"
    case lowBattery = "电量过低"
    case locationException = "位置异常"
    case emergencyContact = "紧急联系"
}

struct AlertSettings {
    var smsEnabled = true
    var pushEnabled = true
    var emailEnabled = false
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlertRow: View {
    let alert: AlertRecord
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: alert.createdAt)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType(alert.type))
                .font(.system(size: 20))
                .foregroundColor(colorForType(alert.type))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 15, weight: .medium))
                
                Text(alert.message)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if alert.isHandled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: AlertType) -> String {
        switch type {
        case .checkinOverdue: return "clock.fill"
        case .lowBattery: return "battery.25"
        case .locationException: return "location.fill"
        case .emergencyContact: return "person.fill"
        }
    }
    
    private func colorForType(_ type: AlertType) -> Color {
        switch type {
        case .checkinOverdue: return .red
        case .lowBattery: return .orange
        case .locationException: return .blue
        case .emergencyContact: return .purple
        }
    }
}

struct AlertThresholdSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var checkinThresholdHours = 12
    @State private var batteryThresholdPercent = 20
    
    var body: some View {
        Form {
            Section(header: Text("签到阈值")) {
                Stepper("超时阈值：\(checkinThresholdHours) 小时", value: $checkinThresholdHours, in: 1...24)
                Text("超过设定时间未签到将触发告警")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("电量阈值")) {
                Stepper("低电量阈值：\(batteryThresholdPercent)%", value: $batteryThresholdPercent, in: 5...50)
                Text("电量低于设定值将触发告警")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text("保存设置")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("告警阈值")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveSettings() {
        // TODO: 保存设置到服务器
        print("⚙️ 保存告警阈值设置")
        dismiss()
    }
}

// MARK: - API Response Models

struct BaseResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct AlertListResponse: Codable {
    let success: Bool
    let data: [ApiAlertRecord]
    let count: Int?
    let error: String?
}

struct AlertSettingsResponse: Codable {
    let success: Bool
    let data: AlertSettingsData
    let error: String?
}

struct AlertSettingsData: Codable {
    let smsEnabled: Int
    let pushEnabled: Int
    let emailEnabled: Int
    let checkinTimeoutHours: Int?
    let batteryLowPercent: Int?
    let locationAbnormalRadiusKm: Int?
    let emergencyContactEnabled: Int?
    
    enum CodingKeys: String, CodingKey {
        case smsEnabled = "sms_enabled"
        case pushEnabled = "push_enabled"
        case emailEnabled = "email_enabled"
        case checkinTimeoutHours = "checkin_timeout_hours"
        case batteryLowPercent = "battery_low_percent"
        case locationAbnormalRadiusKm = "location_abnormal_radius_km"
        case emergencyContactEnabled = "emergency_contact_enabled"
    }
}

struct ApiAlertRecord: Codable {
    let id: Int
    let type: String
    let message: String
    let level: String?
    let isHandled: Int
    let handledAt: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, message, level
        case isHandled = "is_handled"
        case handledAt = "handled_at"
        case createdAt = "created_at"
    }
}

// MARK: - Date Formatter

extension AlertCenterView {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    NavigationView {
        AlertCenterView()
    }
}
