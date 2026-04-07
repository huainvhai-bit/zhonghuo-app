//
//  Settings/NotificationSettingsView.swift
//  终活
//
//  通知设置视图
//  职责：推送通知、签到提醒等设置
//

import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var userManager: UserManager = UserManager.shared
    @StateObject private var configManager = ConfigManager.shared
    @State private var showIntervalSelection = false
    @State private var showReminderSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知设置")) {
                    Toggle(isOn: $userManager.currentUser?.notificationsEnabled ?? true) {
                        Text("通知开关")
                    }
                    
                    Button(action: { showIntervalSelection = true }) {
                        HStack {
                            Text("签到提醒间隔")
                            Spacer()
                            Text(userManager.checkInInterval.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("提醒设置")) {
                    Toggle(isOn: $configManager.systemConfig.checkinReminderThresholdHours > 0) {
                        Text("提前提醒")
                    }
                    
                    Button(action: { showReminderSettings = true }) {
                        HStack {
                            Text("提醒提前时间")
                            Spacer()
                            Text("\(Int(configManager.systemConfig.checkinReminderThresholdHours)) 小时")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("静默模式")) {
                    Toggle(isWithLabel: true) {
                        Text("静默模式")
                    } label: {
                        Text("关闭所有通知推送")
                    }
                }
            }
            .navigationTitle("通知设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showIntervalSelection) {
                IntervalSelectionView()
            }
            .sheet(isPresented: $showReminderSettings) {
                ReminderSettingsView()
            }
        }
    }
}

struct IntervalSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userManager: UserManager = UserManager.shared
    @State private var selectedInterval: CheckInInterval
    
    init() {
        _selectedInterval = State(initialValue: CheckInInterval.allCases.first ?? .twoDays)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("签到间隔")) {
                    ForEach(CheckInInterval.allCases, id: \.self) { interval in
                        Button(action: {
                            userManager.checkInInterval = interval
                            userManager.currentUser?.checkInInterval = interval
                            dismiss()
                        }) {
                            HStack {
                                Text(interval.rawValue)
                                if userManager.checkInInterval == interval {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择签到间隔")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var configManager: ConfigManager = ConfigManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("提醒提前时间")) {
                    ForEach([0, 3, 6, 12, 24], id: \.self) { hours in
                        Button(action: {
                            configManager.systemConfig.checkinReminderThresholdHours = Double(hours)
                            dismiss()
                        }) {
                            HStack {
                                Text(hours == 0 ? "关闭提醒" : "\(hours) 小时")
                                if Int(configManager.systemConfig.checkinReminderThresholdHours) == hours {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("提醒提前时间")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NotificationSettingsView()
}
