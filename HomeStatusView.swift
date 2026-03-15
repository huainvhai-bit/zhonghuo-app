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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    checkInCard
                    statusCard
                    quickActionsGrid
                    progressCard
                    capsulePreview
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("终活 v2.0 ✅")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { _ in
                updateStatus()
            }
        }
    }
    
    private func updateStatus() {
        let status = dataManager.getCheckInStatus()
        isSafe = status.isSafe
        secondsRemaining = status.hoursRemaining * 3600 // 转换为秒
    }
    
    // MARK: - 签到卡片
    private var checkInCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 22))
                Text("安全签到")
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.white.opacity(0.95))
            
            Text(formatCountdown(secondsRemaining))
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
            
            Button(action: performCheckIn) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("我很好，签到确认")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "34C759"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .disabled(isSafe)
            .opacity(isSafe ? 0.5 : 1)
            .scaleEffect(isSafe ? 1.0 : 1.02)
        }
        .padding(22)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "30B34E")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color(hex: "34C759").opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                        .frame(height: 5)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.76, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 快捷操作网格
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - 胶囊预览
    private var capsulePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近的时光胶囊")
                .font(.headline)
            
            ForEach(dataManager.capsules.prefix(3)) { capsule in
                CapsulePreviewRow(capsule: capsule)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    private func formatCountdown(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
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
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Text(icon)
                        .font(.system(size: 20))
                }
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
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
