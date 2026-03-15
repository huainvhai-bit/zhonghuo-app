//
//  HomeStatusView.swift
//  终活
//
//  首页 - 签到、状态、快捷操作
//

import SwiftUI

struct HomeStatusView: View {
    @ObservedObject var dataManager = DataManager.shared
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
                        quickActionsGrid
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
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("终活")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "AF52DE"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("v2.0")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "AF52DE").opacity(0.1))
                        .foregroundColor(Color(hex: "AF52DE"))
                        .cornerRadius(6)
                }
            }
            .onReceive(timer) { _ in
                updateStatus()
            }
            // 见证人页面暂时禁用，等待项目配置修复
            // .sheet(isPresented: $showingWitnessSheet) {
            //     WitnessView()
            // }
        }
    }
    
    private func updateStatus() {
        let status = dataManager.getCheckInStatus()
        isSafe = status.isSafe
        secondsRemaining = status.hoursRemaining * 3600
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
            
            Button(action: performCheckIn) {
                HStack(spacing: 10) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 18))
                    Text("我很好，签到确认")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color(hex: "F8F9FA")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(Color(hex: "34C759"))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
            .scaleEffect(showCheckInAnimation ? 0.95 : 1.0)
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
                                gradient: Gradient(colors: [isSafe ? Color(hex: "AF52DE") : Color(hex: "FF3B30"), isSafe ? Color(hex: "007AFF") : Color(hex: "FF9500")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (isSafe ? 0.76 : 0.1), height: 6)
                        .shadow(color: (isSafe ? Color(hex: "AF52DE") : Color(hex: "FF3B30")).opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 快捷操作网格
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("快捷操作")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                QuickActionItem(
                    systemImage: "mic.fill",
                    label: "录制语音",
                    color: Color(hex: "AF52DE"),
                    action: {
                        print("🔵 点击录制语音")
                        // TODO: 导航到录音功能
                    }
                )
                QuickActionItem(
                    systemImage: "doc.text.fill",
                    label: "身后事务",
                    color: Color(hex: "34C759"),
                    action: {
                        print("🔵 点击身后事务")
                        navigateToWillAssets = true
                    }
                )
                QuickActionItem(
                    systemImage: "person.2.fill",
                    label: "见证人",
                    color: Color(hex: "FF9500"),
                    action: {
                        print("🔵 点击见证人")
                        // TODO: 见证人独立页面开发中
                        showingWitnessSheet = true
                    }
                )
                QuickActionItem(
                    systemImage: "yensign.circle.fill",
                    label: "资产",
                    color: Color(hex: "007AFF"),
                    action: {
                        print("🔵 点击资产")
                        navigateToWillAssets = true
                    }
                )
            }
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
                    .foregroundColor(Color(hex: "AF52DE"))
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
                    .foregroundColor(Color(hex: "AF52DE"))
                }
            }
            
            if dataManager.capsules.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "AF52DE").opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "AF52DE"))
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
                        .foregroundColor(Color(hex: "AF52DE"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "AF52DE").opacity(0.1))
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
    
    private func performCheckIn() {
        print("🔵 签到按钮被点击")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCheckInAnimation = true
            dataManager.checkIn()
            // 立即更新倒计时
            updateStatus()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCheckInAnimation = false
        }
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
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeStatusView()
}
