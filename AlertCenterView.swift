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
                
                Toggle(isOn: $alertSettings.pushEnabled) {
                    Label("推送通知", systemImage: "bell.badge.fill")
                }
                
                Toggle(isOn: $alertSettings.emailEnabled) {
                    Label("邮件通知", systemImage: "envelope.fill")
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
        // TODO: 从服务器加载告警历史
        print("📋 加载告警历史")
    }
    
    private func loadAlertSettings() {
        // TODO: 从服务器加载告警设置
        print("⚙️ 加载告警设置")
    }
    
    private func clearAlertHistory() {
        // TODO: 清除告警历史
        print("🗑️ 清除告警历史")
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

// MARK: - Preview

#Preview {
    NavigationView {
        AlertCenterView()
    }
}
