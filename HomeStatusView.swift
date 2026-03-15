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
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationView {
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
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("终活")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("v2.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onReceive(timer) { _ in
                updateStatus()
            }
        }
    }
    
    private func updateStatus() {
        let status = dataManager.getCheckInStatus()
        isSafe = status.isSafe
        secondsRemaining = status.hoursRemaining * 3600
    }
    
    // MARK: - 签到卡片
    private var checkInCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                Text("安全签到")
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.white.opacity(0.95))
            
            Text(formatCountdown(secondsRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
            
            Button(action: performCheckIn) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 16))
                    Text("我很好，签到确认")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(Color(hex: "34C759"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .disabled(isSafe)
            .opacity(isSafe ? 0.5 : 1)
            .scaleEffect(isSafe ? 1.0 : 1.02)
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "2DA84F")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color(hex: "34C759").opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: "34C759"))
                    .frame(width: 10, height: 10)
                
                Text("监测正常")
                    .font(.headline)
                    .foregroundColor(Color(hex: "34C759"))
                
                Spacer()
            }
            
            Text("一切安好，记得定期签到哦")
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
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.76, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 快捷操作网格
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionItem(
                    systemImage: "mic.fill",
                    label: "录制语音",
                    color: Color(hex: "AF52DE"),
                    action: {
                        // TODO: 导航到录音功能
                    }
                )
                QuickActionItem(
                    systemImage: "doc.text.fill",
                    label: "身后事务",
                    color: Color(hex: "34C759"),
                    action: {
                        // 导航到嘱托页面
                    }
                )
                QuickActionItem(
                    systemImage: "person.2.fill",
                    label: "见证人",
                    color: Color(hex: "FF9500"),
                    action: {
                        // TODO: 导航到见证人功能
                    }
                )
                QuickActionItem(
                    systemImage: "yensign.circle.fill",
                    label: "资产",
                    color: Color(hex: "007AFF"),
                    action: {
                        // 导航到资产页面
                    }
                )
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("我的事务")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // 导航到嘱托与资产页面
                }) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "AF52DE"))
                }
            }
            
            ProgressRow(label: "身后嘱托", progress: dataManager.getWillProgress(), color: Color(hex: "34C759"), action: {
                // 导航到身后嘱托详情
            })
            ProgressRow(label: "见证人", progress: dataManager.getWitnessProgress(), color: Color(hex: "FF9500"), action: {
                // 导航到见证人页面
            })
            ProgressRow(label: "资产管理", progress: dataManager.getAssetProgress(), color: Color(hex: "007AFF"), action: {
                // 导航到资产管理页面
            })
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 胶囊预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近的时光胶囊")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // TODO: 导航到时光胶囊页面
                }) {
                    Text("全部")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "AF52DE"))
                }
            }
            
            if dataManager.capsules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无时光胶囊")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(dataManager.capsules.prefix(3)) { capsule in
                    CapsulePreviewRow(capsule: capsule, onTap: {
                        // TODO: 点击编辑胶囊
                    })
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
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
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
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
            VStack(spacing: 6) {
                HStack {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "E5E5EA"))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color.opacity(0.7), color]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

// MARK: - 胶囊预览行
struct CapsulePreviewRow: View {
    let capsule: TimeCapsule
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // 图标
            Image(systemName: capsule.type.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .foregroundColor(Color(hex: capsule.type.color))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(formatSendDate(capsule.sendDate))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态标签
            HStack(spacing: 4) {
                Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 10))
                Text(capsule.isSent ? "已发送" : "待发送")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(capsule.isSent ? Color(hex: "34C759").opacity(0.12) : Color(hex: "FF9500").opacity(0.12))
            .foregroundColor(capsule.isSent ? Color(hex: "34C759") : Color(hex: "FF9500"))
            .cornerRadius(8)
        }
        .padding(.vertical, 6)
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
