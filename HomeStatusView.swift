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
    @State private var checkInTimer: Timer?
    @State private var hoursRemaining: Double = 0
    @State private var isSafe: Bool = true
    
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
                .padding(16)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("终活")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        updateStatus()
        checkInTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateStatus()
        }
    }
    
    private func stopTimer() {
        checkInTimer?.invalidate()
        checkInTimer = nil
    }
    
    private func updateStatus() {
        let status = dataManager.getCheckInStatus()
        isSafe = status.isSafe
        hoursRemaining = status.hoursRemaining
    }
    
    // MARK: - 签到卡片
    private var checkInCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24))
                Text("安全签到")
                    .font(.title2.bold())
                Spacer()
            }
            .foregroundColor(.white)
            
            Text(formatCountdown(hoursRemaining))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Button(action: performCheckIn) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("我很好，签到确认")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "34C759"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(14)
            }
            .disabled(isSafe)
            .opacity(isSafe ? 0.5 : 1)
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "30B34E")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: "34C759"))
                    .frame(width: 12, height: 12)
                
                Text("监测正常")
                    .font(.title2.bold())
                    .foregroundColor(Color(hex: "34C759"))
            }
            
            Text("一切安好，记得定期签到哦")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.76, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - 快捷操作网格
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionItem(icon: "🎙️", label: "录制语音", color: Color(hex: "AF52DE"), action: {
                // TODO: 导航到录音功能
            })
            QuickActionItem(icon: "📋", label: "身后事务", color: Color(hex: "34C759"), action: {
                // 导航到嘱托页面
            })
            QuickActionItem(icon: "👥", label: "见证人", color: Color(hex: "FF9500"), action: {
                // TODO: 导航到见证人功能
            })
            QuickActionItem(icon: "💰", label: "资产", color: Color(hex: "007AFF"), action: {
                // 导航到资产页面
            })
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("我的事务")
                    .font(.headline)
                Spacer()
                Text("查看全部")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            ProgressRow(label: "身后嘱托", progress: 0.6)
            ProgressRow(label: "见证人", progress: 0.67)
            ProgressRow(label: "资产管理", progress: 0.33)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - 胶囊预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近的时光胶囊")
                .font(.headline)
            
            ForEach(dataManager.capsules.prefix(3)) { capsule in
                CapsulePreviewRow(capsule: capsule)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    private func formatCountdown(_ hours: Double) -> String {
        let hrs = Int(hours)
        let mins = Int((hours - Double(hrs)) * 60)
        return "\(hrs)小时 \(mins)分"
    }
    
    private func performCheckIn() {
        withAnimation(.spring()) {
            showCheckInAnimation = true
            dataManager.checkIn()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCheckInAnimation = false
        }
    }
}

// MARK: - 快捷操作项
struct QuickActionItem: View {
    let icon: String
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
                    
                    Text(icon)
                        .font(.system(size: 22))
                }
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 进度行
struct ProgressRow: View {
    let label: String
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15))
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - 胶囊预览行
struct CapsulePreviewRow: View {
    let capsule: TimeCapsule
    
    var body: some View {
        HStack(spacing: 12) {
            Text(capsule.type.icon)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatSendDate(capsule.sendDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(capsule.type.rawValue)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月 d 日"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeStatusView()
}
