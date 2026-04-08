//
//  Home/HomeStatusView.swift
//  终活
//
//  首页状态视图
//  职责：签到卡片 + 状态卡片 + 进度卡片 + 胶囊预览
//

import SwiftUI
import MessageUI
import UserNotifications

// MARK: - CheckInStatus 枚举
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
    @State private var navigateToWitness = false
    @State private var showingWitnessSheet = false
    @State private var showingEmergencyContactAlert = false
    @State private var showingEmergencyContactsSheet = false
    @State private var hasSentOverdueAlert = false
    
    var body: some View {
        ZStack {
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
            
            // 紧急联系人不足提示
            if showingEmergencyContactAlert {
                EmergencyContactAlert(
                    showingEmergencyContactAlert: $showingEmergencyContactAlert,
                    showingEmergencyContactsSheet: $showingEmergencyContactsSheet
                )
            }
        }
        .onAppear {
            loadCheckInStatus()
            Task {
                await startAutoCheckInIfNeeded()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - CheckIn Card
    private var checkInCard: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [checkInColor.opacity(0.2), checkInColor.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            VStack(spacing: 8) {
                Text("签到")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 自动签到状态指示器
                Circle()
                    .fill(checkInColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: checkInColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(showCheckInAnimation ? 1.2 : 1.0)
                    .animation(.spring(), value: showCheckInAnimation)
            }
        }
    }
    
    private var checkInColor: Color {
        isSafe ? Color(hex: "34C759") : Color(hex: "FF3B30")
    }
    
    // MARK: - Status Card
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
            
            // 进度条
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
    
    private var progressPercentage: Double {
        let hoursRemaining = timerManager.secondsRemaining / 3600
        let totalHours = dataManager.systemConfig.checkinIntervalHours
        return max(0, min(1, hoursRemaining / totalHours))
    }
    
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
                text: "危险：失联",
                icon: "xmark.circle.fill",
                description: "已长时间未签到，系统将自动通知紧急联系人"
            )
        }
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("距离下次签到")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatCountdown(timerManager.secondsRemaining))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // 倒计时进度条
            let totalHours = dataManager.systemConfig.checkinIntervalHours
            let remainingHours = max(0, timerManager.secondsRemaining / 3600)
            let progress = remainingHours / totalHours
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [checkInColor.opacity(0.7), checkInColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("签到间隔：\(Int(totalHours)) 小时")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: showCheckInHistory) {
                    Text("查看历史")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "AF52DE"))
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private func formatCountdown(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((Int(seconds) % 3600) / 60)
        
        if hours > 0 {
            return "\(hours)时\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    private func showCheckInHistory() {
        // TODO: 跳转到签到历史页面
        print("📅 查看签到历史")
    }
    
    // MARK: - Capsule Preview
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("胶囊")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("查看全部") {
                    navigateToTimeCapsule = true
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "AF52DE"))
            }
            
            if !dataManager.capsules.isEmpty {
                ForEach(dataManager.capsules.prefix(3)) { capsule in
                    CapsulePreviewRow(capsule: capsule)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.app.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("暂无胶囊")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(18)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private func setupNavigationBar() {
        // 设置导航栏背景色
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "6366F1")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    // MARK: - 签到状态加载
    private func loadCheckInStatus() {
        isSafe = statusManager.isSafe
        timerManager.updateSeconds(statusManager.hoursRemaining * 3600)
        
        // 启动倒计时定时器
        timerManager.start {
            self.updateUIOnTimerTick()
        }
    }
    
    private func updateUIOnTimerTick() {
        // 检查是否需要推送提醒
        checkAndSendReminderIfNeeded()
    }
    
    private func checkAndSendReminderIfNeeded() {
        let hoursRemaining = timerManager.secondsRemaining / 3600
        let firstReminderHours = dataManager.systemConfig.checkinReminderThresholdHours
        let reminderInterval = dataManager.systemConfig.checkinReminderIntervalHours
        
        // 首次提醒：剩余时间 <= 首次提醒时间
        if hoursRemaining <= firstReminderHours && hoursRemaining > 0 && !hasSentOverdueAlert {
            sendReminderNotification(title: "签到提醒", body: "您还有\(Int(hoursRemaining))小时需要签到，请及时签到")
            hasSentOverdueAlert = true
        }
        
        // 超时提醒
        if hoursRemaining <= 0 && !hasSentOverdueAlert {
            sendReminderNotification(title: "签到超时", body: "您已超过签到时间，请尽快签到以免系统自动通知紧急联系人")
            hasSentOverdueAlert = true
        }
    }
    
    private func sendReminderNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送通知失败：\(error)")
            } else {
                print("✅ 发送通知成功：\(title)")
            }
        }
    }
    
    // MARK: - 场景切换处理
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App 从后台恢复到前台
            print("🟢 App 恢复到前台")
            loadCheckInStatus()
            Task {
                await startAutoCheckInIfNeeded()
            }
            timerManager.start { [timerManager] in
                self.updateUIOnTimerTick()
            }
        case .inactive:
            // App 处于非活动状态
            print("🟡 App 处于非活动状态")
        case .background:
            // App 进入后台
            print("🔴 App 进入后台")
            // 在后台时继续更新倒计时（基于系统时间）
            updateCountdownBasedOnSystemTime()
        @unknown default:
            break
        }
    }
    
    // MARK: - 自动签到
    private func startAutoCheckInIfNeeded() async {
        // ✅ 修复：检查签到是否已过期（而不是检查今天是否已签到）
        // 只有 checkin_expire_at < 当前时间 才需要签到
        let now = Date()
        let checkInInterval = DataManager.shared.systemConfig.checkinIntervalHours
        let expireAt = statusManager.lastCheckInDate?.addingTimeInterval(checkInInterval * 3600)
        
        if let expireTime = expireAt {
            if now < expireTime {
                // 还在有效期内，不需要签到
                let hoursLeft = expireTime.timeIntervalSince(now) / 3600
                print("✅ 签到仍在有效期内，剩余 \(String(format: "%.1f", hoursLeft)) 小时，跳过自动签到")
                return
            }
        }
        
        // 已过期，需要自动签到
        print("⏰ 签到已过期，执行自动签到...")
        
        // 延迟 2 秒后自动签到（等待数据加载完成）
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await performAutoCheckIn()
    }
    
    private func performAutoCheckIn() async {
        print("✍️ 执行自动签到...")
        await statusManager.checkIn()
        
        await MainActor.run {
            withAnimation(.spring()) {
                showCheckInAnimation = true
            }
            
            // 重置动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    showCheckInAnimation = false
                }
            }
        }
    }
    
    // MARK: - 基于系统时间更新倒计时
    private func updateCountdownBasedOnSystemTime() {
        guard let lastCheckIn = statusManager.lastCheckInDate else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastCheckIn)
        let totalSeconds = dataManager.systemConfig.checkinIntervalHours * 3600
        let remaining = max(0, totalSeconds - elapsed)
        
        timerManager.updateSeconds(remaining)
    }
}

// MARK: - Emergency Contact Alert
struct EmergencyContactAlert: View {
    @Binding var showingEmergencyContactAlert: Bool
    @Binding var showingEmergencyContactsSheet: Bool
    
    var body: some View {
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
                        showingEmergencyContactsSheet = true
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
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Capsule Preview Row
struct CapsulePreviewRow: View {
    let capsule: TimeCapsule
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
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
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func onTap() {
        // TODO: 跳转到胶囊详情
        print("capsule tapped")
    }
}

// MARK: - Countdown Timer Manager
class CountdownTimerManager: ObservableObject {
    static let shared = CountdownTimerManager()
    
    @Published var secondsRemaining: Double = 0
    @Published var isRunning: Bool = false
    
    private var timer: Timer?
    
    private init() {}
    
    func start(onTick: @escaping () -> Void) {
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
