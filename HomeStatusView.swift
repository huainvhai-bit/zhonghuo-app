//
//  HomeStatusView.swift
//  终活
//
//  首页 - 签到、状态、快捷操作
//

import SwiftUI

struct HomeStatusView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.scenePhase) var scenePhase
    @State private var showCheckInAnimation = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var secondsRemaining: Double = 0
    @State private var isSafe: Bool = true
    @State private var navigateToWillAssets = false
    @State private var navigateToTimeCapsule = false
    @State private var navigateToWitness = false
    @State private var showingWitnessSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                .background(Color(hex: "F6F6F8"))
                
                // 隐藏的全局导航链接
                NavigationLink(destination: WillAssetsView(), isActive: $navigateToWillAssets) {
                    EmptyView()
                }
                .opacity(0)
                
                NavigationLink(destination: TimeCapsuleView(), isActive: $navigateToTimeCapsule) {
                    EmptyView()
                }
                .opacity(0)
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
                } else {
                    // 倒计时结束，检查是否需要签到
                    updateStatus()
                }
            }
            .onAppear {
                print("🟢 首页 onAppear - 触发自动签到")
                
                // 先执行自动签到（如果需要）
                handleAutoCheckIn()
                
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
        
        // 执行自动签到
        print("✅ 执行自动签到")
        let result = userManager.recordCheckIn(isAuto: true)
        print("   - recordCheckIn 结果：\(result)")
        
        // 更新 DataManager 的 lastCheckInDate
        dataManager.lastCheckInDate = userManager.lastCheckInDate
        
        print("✅ 自动签到完成！倒计时已重置为 \(userManager.checkInInterval.rawValue) 小时")
    }
    
    private func handleManualCheckIn() {
        let userManager = UserManager.shared
        guard userManager.isLoggedIn else {
            print("⚠️ 手动签到：用户未登录")
            return
        }
        
        print("👆 用户点击手动签到")
        let result = userManager.recordCheckIn(isAuto: false)
        
        if case .success = result {
            print("✅ 手动签到成功！")
            dataManager.lastCheckInDate = userManager.lastCheckInDate
            updateStatus()
            
            // 显示成功提示
            showCheckInAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCheckInAnimation = false
            }
        } else {
            print("❌ 手动签到失败")
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
        
        // 安排签到提醒（低于 12 小时时每 3 小时提醒一次）
        NotificationManager.shared.scheduleCheckInReminders(hoursRemaining: status.hoursRemaining)
    }
    
    private func getCheckInStatus() -> (isSafe: Bool, hoursRemaining: Double) {
        let hours = dataManager.settings.checkInInterval.hours
        
        // 如果没有签到记录，返回完整的签到间隔时间
        guard let lastCheckIn = dataManager.lastCheckInDate else {
            return (true, Double(hours))
        }
        
        let elapsed = Date().timeIntervalSince(lastCheckIn) / 3600
        let remaining = hours - elapsed
        return (remaining > 0, max(0, remaining))
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
            
            // 手动签到按钮
            Button(action: {
                handleManualCheckIn()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("立即签到")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "34C759"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(26)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "28A74A")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
        .shadow(color: Color(hex: "34C759").opacity(0.35), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSafe ? Color(hex: "34C759") : Color(hex: "FF3B30"))
                    .frame(width: 10, height: 10)
                    .shadow(color: (isSafe ? Color(hex: "34C759") : Color(hex: "FF3B30")).opacity(0.4), radius: 4, x: 0, y: 2)
                
                Text(isSafe ? "监测正常" : "需要签到")
                    .font(.headline)
                    .foregroundColor(isSafe ? Color(hex: "34C759") : Color(hex: "FF3B30"))
                
                Spacer()
                
                Image(systemName: isSafe ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isSafe ? Color(hex: "34C759") : Color(hex: "FF3B30"))
            }
            
            Text(isSafe ? "一切安好，记得定期签到哦" : "您已超过签到时间，请立即签到")
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
                                gradient: Gradient(colors: [isSafe ? Color(hex: "6366F1") : Color(hex: "FF3B30"), isSafe ? Color(hex: "007AFF") : Color(hex: "FF9500")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (isSafe ? 0.76 : 0.1), height: 6)
                        .shadow(color: (isSafe ? Color(hex: "6366F1") : Color(hex: "FF3B30")).opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
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
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
    
    // 中文日期格式化
    private func formatChineseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: date)
    }
    
    private func formatChineseDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeStatusView()
}
