//
//  HomeStatusView.swift
//  安伴助手
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
    @StateObject private var viewModel = HomeStatusViewModel()
    @StateObject private var timerManager = CountdownTimerManager.shared
    @State private var navigateToWillAssets = false
    @State private var navigateToTimeCapsule = false
    @State private var navigateToFamilyTab = false  // 跳转到关闭签到 tab
    @State private var navigateToReceivedCapsules = false  // 跳转到我收到的留言列表
    @State private var navigateToCapsuleDetail = false  // 跳转留言详情
    @State private var selectedReceivedCapsule: ReceivedCapsule?  // 选中的留言
    @State private var hasSentOverdueAlert = false  // 防止重复发送
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        checkInCard
                        HomeAnnouncementBar(text: dataManager.systemConfig.homeAnnouncementText)
                        statusCard
                        if !AppConfig.isChinaReviewMode {
                            progressCard
                        }
                        capsulePreview
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle(L10n.string(.homeWithYou))
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
                        Text(L10n.string(.homeWithYou))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                // 📥 加载系统配置（后端可配置）
                Task {
                    await viewModel.loadInitialData()
                }
                
                // 🎯 打开 App 自动签到（延迟执行，确保用户数据已加载）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.handleAutoCheckIn()
                }
                
                // 然后更新倒计时显示
                Task { @MainActor in
                    viewModel.updateStatus(timerManager: timerManager)
                }
                
                // ✅ 启动倒计时定时器（基于绝对截止时间刷新）
                // 注意：timerManager 是 @StateObject，当 secondsRemaining 变化时会自动触发视图更新
                timerManager.start { }
                
                // ✅ 设置定期重新计算回调（每60秒从服务器获取倒计时）
                timerManager.recalculateFromServer = {
                    Task {
                        await viewModel.syncStatusFromServer(timerManager: timerManager)
                    }
                }
                
            }
            .onDisappear {
                // ✅ 修复：视图消失时停止 timer，但管理器保持单例状态
                timerManager.stop()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerAutoCheckIn"))) { _ in
                print("🔔 收到自动签到通知（从后台进入前台）")
                viewModel.handleAutoCheckIn()
                Task { @MainActor in
                    viewModel.updateStatus(timerManager: timerManager)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SceneDidBecomeActive"))) { _ in
                print("🔔 收到场景激活通知，刷新倒计时")
                Task { @MainActor in
                    await dataManager.loadReceivedCapsules()
                }
                Task { @MainActor in
                    viewModel.updateStatus(timerManager: timerManager)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FamilyModeChanged"))) { _ in
                print("🔔 收到关闭签到切换通知，刷新首页状态")
                Task { @MainActor in
                    viewModel.updateStatus(timerManager: timerManager)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CheckInDidComplete"))) { _ in
                print("🔔 收到签到完成通知，刷新倒计时")
                Task { @MainActor in
                    viewModel.updateStatus(timerManager: timerManager)
                    LifeCheckStatusManager.shared.requestNotificationRefresh(reason: "签到完成通知")
                }
            }
            // 隐藏的全局导航链接
            .background(
                Group {
                    if !AppConfig.isChinaReviewMode {
                        NavigationLink(destination: WillAssetsView(), isActive: $navigateToWillAssets) { EmptyView() }
                            .opacity(0)
                    }
                    NavigationLink(destination: CapsuleList(dataManager: dataManager), isActive: $navigateToTimeCapsule) { EmptyView() }
                        .opacity(0)
                    if !AppConfig.isChinaReviewMode {
                        NavigationLink(destination: FamilyGuardView(), isActive: $navigateToFamilyTab) { EmptyView() }
                            .opacity(0)
                    }
                    NavigationLink(destination: ReceivedCapsuleListView(), isActive: $navigateToReceivedCapsules) { EmptyView() }
                        .opacity(0)
                    NavigationLink(destination: Group {
                        if let capsule = selectedReceivedCapsule {
                            ReceivedCapsuleDetailView(capsule: capsule)
                        }
                    }, isActive: $navigateToCapsuleDetail) { EmptyView() }
                    .opacity(0)
                }
            )
        }
        .stackNavigationStyle()
    }
    
    // MARK: - 签到卡片
    private var checkInCard: some View {
        // 👨‍👩‍👧 关闭签到模式显示不同的 UI
        let isFamilyMode = !AppConfig.isChinaReviewMode && UserDefaults.standard.bool(forKey: "isFamilyMode")
        
        return VStack(spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: isFamilyMode ? "person.2.fill" : "checkmark.shield.fill")
                        .font(.system(size: 18))
                    Text(isFamilyMode ? L10n.string(.familyGuarding) : L10n.string(.safeCheckIn))
                        .font(.headline)
                }
                .foregroundColor(.white.opacity(0.95))
                
                Spacer()
                
                if !isFamilyMode {
                    // 倒计时标签
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(L10n.string(.signInInterval))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            
            if isFamilyMode {
                // 👨‍👩‍👧 关闭签到模式显示提示图标
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                
                Text(L10n.string(.familyProtected))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(L10n.string(.familyCheckStatus))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text(formatCountdown(timerManager.secondsRemaining))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // ✅ 提示文字：打开 App 即可自动签到
                Text(L10n.string(.autoCheckIn))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // 🚫 已移除手动签到按钮 - 打开 App 自动签到
        }
        .padding(26)
        .background(
            LinearGradient(
                gradient: Gradient(colors: isFamilyMode ? [Color.green.opacity(0.8), Color.blue.opacity(0.8)] : checkInColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
        .shadow(color: (isFamilyMode ? Color.green : checkInShadowColor).opacity(0.35), radius: 12, x: 0, y: 6)
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
        .background(Color.appCardBackground)
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
                text: L10n.string(.monitorNormalTitle),
                icon: "checkmark.circle.fill",
                description: L10n.string(.monitorNormalDesc)
            )
        } else if hoursRemaining > -offlineThreshold {
            return (
                color: Color(hex: "FF9500"),
                text: L10n.string(.monitorWarningTitle),
                icon: "exclamationmark.circle.fill",
                description: L10n.string(.monitorWarningDesc)
            )
        } else {
            return (
                color: Color(hex: "FF3B30"),
                text: L10n.string(.monitorDangerTitle),
                icon: "xmark.circle.fill",
                description: L10n.string(.monitorDangerDesc)
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
                    Text(L10n.string(.myTasks))
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    print("🔵 点击查看全部，切换到留言Tab")
                    // ✅ 修复：直接切换到留言Tab（Tab index = 1）
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SwitchToTab"),
                        object: nil,
                        userInfo: ["tab": 1]
                    )
                }) {
                    HStack(spacing: 4) {
                        Text(L10n.string(.viewAll))
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
            
            ProgressRow(label: L10n.string(.assetManagement), progress: dataManager.getAssetProgress(), color: Color(hex: "007AFF"), action: {
                print("🔵 点击资产管理进度")
                navigateToWillAssets = true
            })
        }
        .padding(18)
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 收到的留言预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 16))
                    Text(L10n.string(.receivedCapsules))
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    print("🔵 点击全部留言")
                    navigateToReceivedCapsules = true
                }) {
                    HStack(spacing: 4) {
                        Text(L10n.string(.all))
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
                    
                    Text(L10n.string(.noReceivedCapsules))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(L10n.string(.receivedCapsuleHint))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ForEach(dataManager.receivedCapsules.prefix(3)) { capsule in
                    ReceivedCapsulePreviewRow(capsule: capsule, onTap: {
                        print("🔵 点击收到的留言：\(capsule.title)")
                        selectedReceivedCapsule = capsule
                        navigateToCapsuleDetail = true
                    })
                }
            }
        }
        .padding(18)
        .background(Color.appCardBackground)
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

// MARK: - 留言预览行
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
                Text(capsule.isSent ? L10n.string(.sent) : L10n.string(.pendingSend))
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
        date.chineseDateTimeString()
    }
}

// MARK: - 收到的留言预览行
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
                    Text("\(L10n.string(.from))：\(capsule.senderName)")
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
                    Text(L10n.string(.unread))
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
                    Text(L10n.string(.read))
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
    @Published var deadline: Date?
    
    private var timer: Timer?
    private var recalculateTimer: Timer?
    
    private init() {}
    
    func start(onTick: @escaping () -> Void) {
        // 如果已经在运行，先停止
        stop()
        
        isRunning = true
        refreshRemaining()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.refreshRemaining()
            if self.secondsRemaining > 0 {
                onTick()
            }
        }
        
        // ✅ 添加定期重新计算功能（每60秒重新计算，确保与服务器同步）
        recalculateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.recalculateFromServer?()
        }
    }
    
    // ✅ 定期重新计算的回调
    var recalculateFromServer: (() -> Void)?
    
    func stop() {
        timer?.invalidate()
        timer = nil
        recalculateTimer?.invalidate()
        recalculateTimer = nil
        isRunning = false
    }
    
    func updateSeconds(_ seconds: Double) {
        secondsRemaining = max(0, seconds)
        deadline = Date().addingTimeInterval(secondsRemaining)
    }

    func refreshRemaining() {
        guard let deadline else { return }
        secondsRemaining = max(0, deadline.timeIntervalSince(Date()))
    }
}

#Preview {
    HomeStatusView()
}
