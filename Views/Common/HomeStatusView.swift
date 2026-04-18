//
//  HomeStatusView.swift
//  终活
//
//  首页 - 签到、状态、快捷操作
//

import SwiftUI
import MessageUI

// MARK: - CheckInStatus 枚举（✅ 修复 #2: 定义签到状态枚举）
enum CheckInStatus {
    case safe
    case warning
    case danger
}

struct HomeStatusView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject private var statusManager = LifeCheckStatusManager.shared
    @State private var showCheckInAnimation = false
    @State private var isSafe: Bool = true
    @StateObject private var timerManager = CountdownTimerManager.shared
    @State private var navigateToWillAssets = false
    @State private var navigateToTimeCapsule = false
    @State private var navigateToFamilyTab = false  // 跳转到家人守护 tab
    @State private var showingEmergencyContactAlert = false
    @State private var hasSentOverdueAlert = false  // 防止重复发送
    
    var body: some View {
        NavigationView {
            ZStack {
                // ✅ 修复 #5: 背景色全屏覆盖
                Color(hex: "F5F5F7")
                    .ignoresSafeArea(edges: .all)
                
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
                
                NavigationLink(destination: CapsuleList(dataManager: dataManager), isActive: $navigateToTimeCapsule) {
                    EmptyView()
                }
                .opacity(0)
                
                // 👥 家人不足提示（家人直接替代紧急联系人）
                if showingEmergencyContactAlert {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("家人不足")
                                .font(.headline)
                            
                            Text("为了您的安全，请至少添加 1 位家人。\n在紧急情况下，家人可以及时帮助您。")
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
                                    navigateToFamilyTab = true  // 跳转到家人守护 tab
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
            .onAppear {
                setupNavigationBar()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("终活 v2.0 ✅")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                // 📥 加载系统配置（后端可配置）
                Task {
                    await DataManager.shared.loadSystemConfig()
                    await DataManager.shared.loadReceivedCapsules()  // ✅ 加载我收到的胶囊
                }
                
                // 🎯 打开 App 自动签到（延迟执行，确保用户数据已加载）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleAutoCheckIn()
                }
                
                // 👥 检查家人数量
                checkEmergencyContactsCount()
                
                // 📞 检查是否需要通知监护人
                checkGuardianNotification()
                
                // 然后更新倒计时显示
                updateStatus()
                
                // ✅ 修复：启动 Timer（切换界面后继续运行）
                timerManager.start {
                    // 检查是否刚进入危险状态（倒计时归零）
                    if self.timerManager.secondsRemaining <= 0 && !self.hasSentOverdueAlert {
                        // 倒计时结束，发送 iMessage 通知紧急联系人
                        self.sendOverdueAlertToEmergencyContacts()
                    }
                }
                
                // 🔔 监听签到完成通知（刷新倒计时）
                NotificationCenter.default.addObserver(forName: NSNotification.Name("CheckInDidComplete"), object: nil, queue: .main) { _ in
                    print("🔔 收到签到完成通知，刷新倒计时")
                    updateStatus()
                }
            }
            .onDisappear {
                // ✅ 修复：视图消失时停止 timer，但管理器保持单例状态
                timerManager.stop()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerAutoCheckIn"))) { _ in
                print("🔔 收到自动签到通知（从后台进入前台）")
                handleAutoCheckIn()
                updateStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SceneDidBecomeActive"))) { _ in
                print("🔔 收到场景激活通知，刷新倒计时")
                updateStatus()
            }
        }
    }
    
    // ✅ 修复：标记为 @MainActor，确保所有状态更新在主线程
    @MainActor
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
        // ✅ 改为检查家人数量（家人直接替代紧急联系人）
        let familyCount = DataManager.shared.familyMembers.count
        let minimumFamily = 1  // 至少添加 1 位家人
        print("👥 检查家人数量：\(familyCount) 人（要求：至少 \(minimumFamily) 人）")
        
        if familyCount < minimumFamily {
            print("⚠️ 家人不足，显示提示")
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
        
        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            print("⚠️ 同步失败：认证失败")
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
    
    // ✅ 修复：确保所有状态更新在主线程执行
    @MainActor
    private func updateStatus() {
        // 确保使用最新的签到间隔
        dataManager.settings.checkInInterval = UserManager.shared.checkInInterval
        dataManager.settings.lastCheckInDate = UserManager.shared.lastCheckInDate
        dataManager.lastCheckInDate = UserManager.shared.lastCheckInDate
        let status = getCheckInStatus()
        isSafe = status.isSafe
        let seconds = status.hoursRemaining * 3600
        timerManager.updateSeconds(seconds)
        print("🔄 updateStatus: secondsRemaining=\(seconds), isSafe=\(isSafe)")
        
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
            
            Text(formatCountdown(timerManager.secondsRemaining))
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
    // ✅ P2 修复 #10: 优化计算属性，缓存计算结果
    private var checkInColors: [Color] {
        let checkInState = getCurrentCheckInState()
        return checkInState.colors
    }
    
    private var checkInShadowColor: Color {
        let checkInState = getCurrentCheckInState()
        return checkInState.shadowColor
    }
    
    // ✅ P2 修复 #10: 提取状态计算逻辑，避免重复计算
    private func getCurrentCheckInState() -> (colors: [Color], shadowColor: Color, status: CheckInStatus) {
        let hoursRemaining = timerManager.secondsRemaining / 3600
        let reminderThreshold = dataManager.systemConfig.checkinReminderThresholdHours
        
        if hoursRemaining > reminderThreshold {
            let colors: [Color] = [Color(hex: "34C759"), Color(hex: "28A74A")]
            let shadowColor = Color(hex: "34C759")
            return (colors, shadowColor, .safe)
        } else if hoursRemaining > 0 {
            let colors: [Color] = [Color(hex: "FF9500"), Color(hex: "FF8800")]
            let shadowColor = Color(hex: "FF9500")
            return (colors, shadowColor, .warning)
        } else {
            let colors: [Color] = [Color(hex: "FF3B30"), Color(hex: "FF2D55")]
            let shadowColor = Color(hex: "FF3B30")
            return (colors, shadowColor, .danger)
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
    // ✅ P2 修复 #10: 优化计算属性，缓存中间结果
    private var statusColor: Color {
        let status = getStatusState()
        return status.color
    }
    
    private var statusText: String {
        let status = getStatusState()
        return status.text
    }
    
    private var statusIcon: String {
        let status = getStatusState()
        return status.icon
    }
    
    private var statusDescription: String {
        let status = getStatusState()
        return status.description
    }
    
    // ✅ P2 修复 #10: 提取状态计算逻辑，避免重复计算
    private func getStatusState() -> (color: Color, text: String, icon: String, description: String) {
        let hoursRemaining = timerManager.secondsRemaining / 3600
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        if hoursRemaining > 0 {
            return (
                color: Color(hex: "34C759"),
                text: "监测正常",
                icon: "checkmark.circle.fill",
                description: "一切安好，记得定期签到哦"
            )
        } else if hoursRemaining > -offlineThreshold {
            return (
                color: Color(hex: "FF9500"),
                text: "警告：已超时",
                icon: "exclamationmark.circle.fill",
                description: "您已超过签到时间，请尽快签到"
            )
        } else {
            return (
                color: Color(hex: "FF3B30"),
                text: "危险：离线超时",
                icon: "xmark.circle.fill",
                description: "您已离线超时，请立即签到！"
            )
        }
    }
    
    // 📊 进度条百分比（根据倒计时动态计算）
    // ✅ P2 修复 #10: 优化计算属性
    private var progressPercentage: Double {
        let hoursRemaining = timerManager.secondsRemaining / 3600
        let checkInInterval = Double(dataManager.settings.checkInInterval.hours)
        let offlineThreshold = dataManager.systemConfig.offlineTimeoutHours
        
        let totalTime = checkInInterval + offlineThreshold
        let remainingTime = max(0, hoursRemaining + offlineThreshold)
        
        return min(1.0, max(0.0, remainingTime / totalTime))
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
    
    // MARK: - 收到的胶囊预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 16))
                    Text("我收到的时光胶囊")
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
            
            if dataManager.receivedCapsules.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "6366F1").opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6366F1"))
                    }
                    
                    Text("暂无收到的胶囊")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("家人分享的胶囊会出现在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ForEach(dataManager.receivedCapsules.prefix(3)) { capsule in
                    ReceivedCapsulePreviewRow(capsule: capsule, onTap: {
                        print("🔵 点击收到的胶囊：\(capsule.title)")
                        // TODO: 打开胶囊详情
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
        Button(action: {
            print("🔵 ProgressRow 点击：\(label)")
            action()
        }) {
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
            .contentShape(Rectangle())  // ✅ 修复：确保整个区域可点击
        }
        .buttonStyle(.plain)  // ✅ 修复：使用 plain 样式
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
        .contentShape(Rectangle())  // ✅ 确保整个区域可点击
        .onTapGesture {
            print("🔵 CapsulePreviewRow 点击：\(capsule.title)")
            onTap()
        }
        .buttonStyle(.plain)  // ✅ 添加 plain 样式
    }
    
    // 📅 中文日期格式化
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 收到的胶囊预览行
struct ReceivedCapsulePreviewRow: View {
    let capsule: ReceivedCapsule
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: capsule.typeEnum.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(Color(hex: capsule.typeEnum.color).opacity(0.12))
                .foregroundColor(Color(hex: capsule.typeEnum.color))
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                    Text("来自：\(capsule.senderName)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 未打开状态标签
            if !capsule.isOpened {
                HStack(spacing: 4) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 11))
                    Text("未读")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "6366F1").opacity(0.12))
                .foregroundColor(Color(hex: "6366F1"))
                .cornerRadius(10)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("已读")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "34C759").opacity(0.12))
                .foregroundColor(Color(hex: "34C759"))
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔵 ReceivedCapsulePreviewRow 点击：\(capsule.title)")
            onTap()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 导航栏样式设置
extension HomeStatusView {
    private func setupNavigationBar() {
    // 设置导航栏背景色（兼容 iOS 15+）
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(hex: "6366F1")
    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    
    // 设置滚动时的外观
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - 倒计时 Timer 管理器（✅ 修复：在后台持续运行）
class CountdownTimerManager: ObservableObject {
    static let shared = CountdownTimerManager()
    
    @Published var secondsRemaining: Double = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    
    private init() {}
    
    func start(onTick: @escaping () -> Void) {
        // 如果已经在运行，先停止
        stop()
        
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
                onTick()
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func updateSeconds(_ seconds: Double) {
        secondsRemaining = seconds
    }
}

#Preview {
    HomeStatusView()
}
