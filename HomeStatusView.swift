//
//  HomeStatusView.swift
//  终活
//
//  首页 - 签到、状态、快捷操作
//

import SwiftUI
import MessageUI

struct HomeStatusView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject private var statusManager = LifeCheckStatusManager.shared
    @State private var showCheckInAnimation = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var secondsRemaining: Double = 0
    @State private var isSafe: Bool = true
    @State private var navigateToWillAssets = false
    @State private var navigateToTimeCapsule = false
    @State private var navigateToWitness = false
    @State private var showingWitnessSheet = false
    @State private var showingEmergencyContactAlert = false
    @State private var showingEmergencyContactsSheet = false  // 紧急联系人弹窗
    @State private var hasSentOverdueAlert = false  // 防止重复发送
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(hex: "F5F5F7")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        checkInCard
                        statusCard
                        progressCard
                        capsulePreview
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                
                // 隐藏的全局导航链接
                NavigationLink(destination: WillAssetsView(), isActive: $navigateToWillAssets) {
                    EmptyView()
                }
                .opacity(0)
                
                NavigationLink(destination: TimeCapsuleView(), isActive: $navigateToTimeCapsule) {
                    EmptyView()
                }
                .opacity(0)
                
                // 👥 紧急联系人不足提示
                if showingEmergencyContactAlert {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("紧急联系人不足")
                                .font(.headline)
                            
                            Text("为了您的安全，请至少添加 2 位紧急联系人。\n在紧急情况下，他们可以及时联系到您的家人朋友。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 12) {
                                Button("稍后再说") {
                                    showingEmergencyContactAlert = false
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                                
                                Button("去添加") {
                                    showingEmergencyContactAlert = false
                                    showingEmergencyContactsSheet = true  // 跳转到紧急联系人页面
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "6366F1"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 20)
                        .padding(40)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: showingEmergencyContactAlert)
                }
            }
            .navigationTitle("终活")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("终活")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onReceive(timer) { _ in
                // 每秒递减倒计时
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                    
                    // 检查是否刚进入危险状态（倒计时归零）
                    if secondsRemaining == 0 && !hasSentOverdueAlert {
                        // 倒计时结束，发送 iMessage 通知紧急联系人
                        sendOverdueAlertToEmergencyContacts()
                    }
                } else {
                    // 倒计时结束，检查是否需要签到
                    updateStatus()
                }
            }
            .onAppear {
                // 📥 加载系统配置（后端可配置）
                Task {
                    await DataManager.shared.loadSystemConfig()
                }
                
                // 🎯 打开 App 自动签到（延迟执行，确保用户数据已加载）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleAutoCheckIn()
                }
                
                // 👥 检查紧急联系人数量（使用后端配置）
                checkEmergencyContactsCount()
                
                // 📞 检查是否需要通知监护人
                checkGuardianNotification()
                
                // 然后更新倒计时显示
                updateStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerAutoCheckIn"))) { _ in
                print("🔔 收到自动签到通知（从后台进入前台）")
                handleAutoCheckIn()
                updateStatus()
            }
            // 🔴 不在这里处理 scenePhase！
            // ContentView 已经统一处理了，避免重复调用
            .sheet(isPresented: $showingWitnessSheet) {
                WitnessView()
            }
            .sheet(isPresented: $showingEmergencyContactsSheet) {
                EmergencyContactsView()
            }
        }
    }
    
    private func handleAutoCheckIn() {
        let userManager = UserManager.shared
        guard userManager.isLoggedIn else {
            print("⚠️ 自动签到：用户未登录")
            return
        }
        
        let now = Date()
        let lastCheckIn = userManager.lastCheckInDate
        let intervalSeconds = userManager.checkInInterval.hours * 3600
        
        // 🎯 核心逻辑：每次打开 App 都自动签到（重置倒计时，证明用户安全）
        // 不管是否过期，只要打开 App 就签到
        print("🔄 打开 App 自动签到（重置倒计时，证明用户安全）")
        print("   - 当前时间：\(now)")
        print("   - lastCheckIn: \(lastCheckIn ?? Date.distantPast)")
        print("   - interval: \(intervalSeconds)s (\(userManager.checkInInterval.rawValue) 小时)")
        
        if lastCheckIn == nil {
            print("⏰ 首次签到：没有签到记录")
        } else {
            let elapsed = now.timeIntervalSince(lastCheckIn!)
            let hoursElapsed = elapsed / 3600
            print("   - 距离上次签到：\(String(format: "%.1f", hoursElapsed)) 小时")
        }
        
        // ✅ 执行自动签到（isAuto: true 会自动上传位置和数据）
        print("✅ 执行自动签到")
        let result = userManager.recordCheckIn(isAuto: true)
        print("   - recordCheckIn 结果：\(result)")
        
        // 更新 DataManager 的 lastCheckInDate
        dataManager.lastCheckInDate = userManager.lastCheckInDate
        
        print("✅ 自动签到完成！倒计时已重置为 \(userManager.checkInInterval.rawValue) 小时")
        print("📍 位置和数据已自动上传到服务器")
    }
    
    /// 👥 检查紧急联系人数量（低于配置数量提示）
    private func checkEmergencyContactsCount() {
        guard let user = UserManager.shared.currentUser else {
            print("⚠️ 无法检查紧急联系人：无用户数据")
            return
        }
        
        // 📱 优先使用后端配置，其次使用默认值
        let minimumContacts = dataManager.systemConfig.minimumEmergencyContacts
        let contactCount = user.emergencyContacts.count
        print("👥 检查紧急联系人数量：\(contactCount) 人（要求：\(minimumContacts) 人）")
        
        if contactCount < minimumContacts {
            print("⚠️ 紧急联系人不足 \(minimumContacts) 人，显示提示")
            showingEmergencyContactAlert = true
        }
    }
    
    /// 📞 检查是否需要通知监护人
    private func checkGuardianNotification() {
        // 使用 statusManager 检查状态
        statusManager.updateStatus()
        
        if !statusManager.isSafe {
            print("⚠️ 用户已超时未签到，检查是否需要通知监护人")
            statusManager.notifyGuardianIfNeeded()
        }
    }
    
    /// 🆕 打开 App 时智能同步数据（双向同步：本地↔云端）
    private func forceUploadDataOnAppOpen() {
        print("🔄 ====== 打开 App 智能同步数据 ======")
        print("🎯 同步策略：比对本地和云端，保持数据一致")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            print("⚠️ 同步失败：无 token")
            return
        }
        
        Task {
            // 🎯 第一步：从云端下载数据（新设备或获取其他设备的数据）
            print("📥 1. 从云端下载数据...")
            await DataManager.shared.downloadAllData()
            
            // 🎯 第二步：上传本地新数据到云端
            print("📤 2. 上传本地新数据到云端...")
            
            // 上传位置信息
            print("📍 上传位置信息...")
            await uploadLocation()
            
            // 同步胶囊数据（本地→云端）
            print("📦 同步胶囊数据...")
            if let result = await DataManager.shared.batchSyncCapsules() {
                print("✅ 胶囊同步完成：\(result)")
            }
            
            // 同步遗嘱数据（本地→云端）
            print("📝 同步遗嘱数据...")
            if let result = await DataManager.shared.batchSyncWills() {
                print("✅ 遗嘱同步完成：\(result)")
            }
            
            // 同步紧急联系人（本地→云端）
            print("👥 同步紧急联系人...")
            if let result = await DataManager.shared.batchSyncEmergencyContacts() {
                print("✅ 紧急联系人同步完成：\(result)")
            }
            
            // 同步见证人（本地→云端）
            print("👤 同步见证人...")
            if let result = await DataManager.shared.batchSyncWitnesses() {
                print("✅ 见证人同步完成：\(result)")
            }
            
            print("🎉 所有数据同步完成！")
            print("📊 本地和云端数据已保持一致")
            print("🔄 ====== 同步完成 ======")
        }
    }
    
    /// 上传位置信息
    private func uploadLocation() async {
        guard let user = UserManager.shared.currentUser else {
            print("⚠️ 位置上传失败：无用户数据")
            return
        }
        
        UserManager.shared.uploadLocation()
    }
    
    // 🚫 已移除手动签到功能 - 只保留自动签到
    
    /// 发送超时通知给紧急联系人（使用苹果原生 iMessage）
    private func sendOverdueAlertToEmergencyContacts() {
        print("🚨 倒计时结束，准备发送 iMessage 通知紧急联系人")
        
        guard let user = UserManager.shared.currentUser else {
            print("⚠️ 无用户数据，跳过通知")
            return
        }
        
        // 获取紧急联系人，转换为 MessageManager 需要的格式
        let contacts = user.emergencyContacts
            .filter { $0.deletedAt == nil }  // 只选择未删除的联系人
            .map { EmergencyContactInfo(
                id: $0.id,
                name: $0.name,
                phone: $0.phone,
                relationship: $0.relationship
            )}
        
        guard !contacts.isEmpty else {
            print("⚠️ 没有紧急联系人，跳过通知")
            return
        }
        
        // 计算超时小时数
        let hoursOverdue = Int(DataManager.shared.systemConfig.offlineTimeoutHours)
        
        print("📱 发送 iMessage 给 \(contacts.count) 个紧急联系人")
        print("   - 超时阈值：\(hoursOverdue) 小时")
        
        // 使用苹果原生 iMessage 发送通知
        MessageManager.shared.sendLifeCheckAlert(
            to: contacts,
            userName: user.name,
            hoursOverdue: hoursOverdue
        ) { success, message in
            if success {
                print("✅ iMessage 通知发送成功")
                hasSentOverdueAlert = true  // 标记已发送，防止重复
            } else {
                print("❌ iMessage 通知失败：\(message ?? "未知错误")")
            }
        }
    }
    
    private func updateStatus() {
        // 确保使用最新的签到间隔
        dataManager.settings.checkInInterval = UserManager.shared.checkInInterval
        dataManager.settings.lastCheckInDate = UserManager.shared.lastCheckInDate
        dataManager.lastCheckInDate = UserManager.shared.lastCheckInDate
        let status = getCheckInStatus()
        isSafe = status.isSafe
        secondsRemaining = status.hoursRemaining * 3600
        print("🔄 updateStatus: secondsRemaining=\(secondsRemaining), isSafe=\(isSafe)")
        
        // 📱 安排签到提醒（使用后端配置的阈值和间隔）
        NotificationManager.shared.scheduleCheckInReminders(hoursRemaining: status.hoursRemaining)
    }
    
    private func getCheckInStatus() -> (isSafe: Bool, hoursRemaining: Double) {
        let hours = dataManager.settings.checkInInterval.hours
        
        // 📱 使用后端配置的离线阈值（默认 24 小时）
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        // 如果没有签到记录，返回完整的签到间隔时间
        guard let lastCheckIn = dataManager.lastCheckInDate else {
            return (true, Double(hours))
        }
        
        let elapsed = Date().timeIntervalSince(lastCheckIn) / 3600
        let remaining = Double(hours) - elapsed
        
        // 🔴 安全状态判断：
        // - 剩余时间 > 0：绿色（安全）
        // - 剩余时间 <= 0 但 < 离线阈值：橙色（警告）
        // - 剩余时间 <= -离线阈值：红色（危险）
        if remaining > 0 {
            return (true, max(0, remaining))  // 绿色
        } else if remaining > -offlineThreshold {
            return (true, max(0, remaining))  // 橙色（警告但还安全）
        } else {
            return (false, 0)  // 红色（危险）
        }
    }
    
    // MARK: - 签到卡片
    private var checkInCard: some View {
        VStack(spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18))
                    Text("安全签到")
                        .font(.headline)
                }
                .foregroundColor(.white.opacity(0.95))
                
                Spacer()
                
                // 倒计时标签
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text("距下次签到")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Text(formatCountdown(secondsRemaining))
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
            
            // ✅ 提示文字：打开 App 即可自动签到
            Text("打开 App 即可自动签到")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            // 🚫 已移除手动签到按钮 - 打开 App 自动签到
        }
        .padding(26)
        .background(
            LinearGradient(
                gradient: Gradient(colors: checkInColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
        .shadow(color: checkInShadowColor.opacity(0.35), radius: 12, x: 0, y: 6)
    }
    
    // 🎨 签到卡片颜色（根据倒计时状态变化）
    private var checkInColors: [Color] {
        let hoursRemaining = secondsRemaining / 3600
        let reminderThreshold = dataManager.systemConfig.checkinReminderThresholdHours  // 提醒阈值（默认 12 小时）
        
        if hoursRemaining > reminderThreshold {
            // 🟢 绿色：安全签到倒计时（高于提醒阈值）
            return [Color(hex: "34C759"), Color(hex: "28A74A")]
        } else if hoursRemaining > 0 {
            // 🟠 橙色：警告状态（低于提醒阈值但还未到期）
            return [Color(hex: "FF9500"), Color(hex: "FF8800")]
        } else {
            // 🔴 红色：危险状态（倒计时结束，已超时）
            return [Color(hex: "FF3B30"), Color(hex: "FF2D55")]
        }
    }
    
    private var checkInShadowColor: Color {
        let hoursRemaining = secondsRemaining / 3600
        let reminderThreshold = dataManager.systemConfig.checkinReminderThresholdHours
        
        if hoursRemaining > reminderThreshold {
            return Color(hex: "34C759")
        } else if hoursRemaining > 0 {
            return Color(hex: "FF9500")
        } else {
            return Color(hex: "FF3B30")
        }
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: statusColor.opacity(0.4), radius: 4, x: 0, y: 2)
                
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
            }
            
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 进度条 - 根据倒计时动态变化
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [statusColor.opacity(0.7), statusColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 6)
                        .shadow(color: statusColor.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // 🎨 状态卡片颜色（根据倒计时变化）
    private var statusColor: Color {
        let hoursRemaining = secondsRemaining / 3600
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        if hoursRemaining > 0 {
            return Color(hex: "34C759")  // 绿色
        } else if hoursRemaining > -offlineThreshold {
            return Color(hex: "FF9500")  // 橙色
        } else {
            return Color(hex: "FF3B30")  // 红色
        }
    }
    
    private var statusText: String {
        let hoursRemaining = secondsRemaining / 3600
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        if hoursRemaining > 0 {
            return "监测正常"
        } else if hoursRemaining > -offlineThreshold {
            return "警告：已超时"
        } else {
            return "危险：离线超时"
        }
    }
    
    private var statusIcon: String {
        let hoursRemaining = secondsRemaining / 3600
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        if hoursRemaining > 0 {
            return "checkmark.circle.fill"
        } else if hoursRemaining > -offlineThreshold {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var statusDescription: String {
        let hoursRemaining = secondsRemaining / 3600
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        if hoursRemaining > 0 {
            return "一切安好，记得定期签到哦"
        } else if hoursRemaining > -offlineThreshold {
            return "您已超过签到时间，请尽快签到"
        } else {
            return "您已离线超时，请立即签到！"
        }
    }
    
    // 📊 进度条百分比（根据倒计时动态计算）
    private var progressPercentage: Double {
        let hoursRemaining = secondsRemaining / 3600
        let checkInInterval = Double(dataManager.settings.checkInInterval.hours)
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        // 总时间 = 签到间隔 + 离线阈值
        let totalTime = checkInInterval + offlineThreshold
        
        // 剩余时间（可能为负数）
        let remainingTime = max(0, hoursRemaining + offlineThreshold)
        
        // 计算百分比（0-100%）
        let percentage = remainingTime / totalTime
        return min(1.0, max(0.0, percentage))
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 16))
                    Text("我的事务")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    print("🔵 点击查看全部")
                    navigateToWillAssets = true
                }) {
                    HStack(spacing: 4) {
                        Text("查看全部")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            
            ProgressRow(label: "身后嘱托", progress: dataManager.getWillProgress(), color: Color(hex: "34C759"), action: {
                print("🔵 点击身后嘱托进度")
                navigateToWillAssets = true
            })
            ProgressRow(label: "见证人", progress: dataManager.getWitnessProgress(), color: Color(hex: "FF9500"), action: {
                print("🔵 点击见证人进度")
                showingWitnessSheet = true
            })
            ProgressRow(label: "资产管理", progress: dataManager.getAssetProgress(), color: Color(hex: "007AFF"), action: {
                print("🔵 点击资产管理进度")
                navigateToWillAssets = true
            })
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 胶囊预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 16))
                    Text("最近的时光胶囊")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    print("🔵 点击全部胶囊")
                    navigateToTimeCapsule = true
                }) {
                    HStack(spacing: 4) {
                        Text("全部")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            
            if dataManager.capsules.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "6366F1").opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                    
                    Text("暂无时光胶囊")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        print("🔵 点击创建胶囊")
                        navigateToTimeCapsule = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("创建第一个胶囊")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "6366F1").opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ForEach(dataManager.capsules.prefix(3)) { capsule in
                    CapsulePreviewRow(capsule: capsule, onTap: {
                        print("🔵 点击胶囊：\(capsule.title)")
                        navigateToTimeCapsule = true
                    })
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Helpers
    private func formatCountdown(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    
}

// MARK: - 快捷操作项
struct QuickActionItem: View {
    let systemImage: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 进度行
struct ProgressRow: View {
    let label: String
    let progress: Double
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Text(label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "E5E5EA"))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color.opacity(0.7), color]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 7)
                            .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                }
                .frame(height: 7)
            }
        }
    }
}

// MARK: - 胶囊预览行
struct CapsulePreviewRow: View {
    let capsule: TimeCapsule
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: capsule.type.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .foregroundColor(Color(hex: capsule.type.color))
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 状态标签
            HStack(spacing: 4) {
                Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 11))
                Text(capsule.isSent ? "已发送" : "待发送")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(capsule.isSent ? Color(hex: "34C759").opacity(0.12) : Color(hex: "FF9500").opacity(0.12))
            .foregroundColor(capsule.isSent ? Color(hex: "34C759") : Color(hex: "FF9500"))
            .cornerRadius(10)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    // 📅 中文日期格式化
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeStatusView()
}
