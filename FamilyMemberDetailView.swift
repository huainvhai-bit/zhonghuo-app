//
//  FamilyMemberDetailView.swift
//  终活
//
//  家人详情页面
//

import SwiftUI
import MapKit

struct FamilyMemberDetailView: View {
    let member: FamilyMember
    @Environment(\.dismiss) private var dismiss
    @State private var showingRemoveAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F7").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 头像和信息
                        headerSection
                        
                        // 设备信息
                        if let deviceInfo = member.deviceInfo {
                            deviceInfoSection(deviceInfo)
                        }
                        
                        // 位置信息（如果有）
                        if let deviceInfo = member.deviceInfo,
                           deviceInfo.lastUpdate != nil {
                            locationSection
                        }
                        
                        // 操作按钮
                        actionSection
                    }
                    .padding()
                }
            }
            .navigationTitle(member.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("解除关系", isPresented: $showingRemoveAlert) {
                Button("取消", role: .cancel) {}
                Button("解除", role: .destructive) {
                    removeFamily()
                }
            } message: {
                Text("解除后将无法查看对方的设备信息和位置")
            }
        }
    }
    
    // MARK: - 头部
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                if !member.avatar.isEmpty {
                    AsyncImage(url: URL(string: member.avatar)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 40))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                }
            }
            
            // 姓名
            Text(member.name)
                .font(.system(size: 24, weight: .bold))
            
            // 状态
            if member.status == .pending {
                Text("待接受")
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            } else {
                Text("已绑定")
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            // 电话
            if !member.phone.isEmpty {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 12))
                    Text(member.phone)
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 设备信息
    @ViewBuilder
    private func deviceInfoSection(_ deviceInfo: DeviceInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "iphone")
                    .font(.system(size: 16))
                    .foregroundColor(.indigo)
                Text("设备信息")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            // 步数
            DeviceInfoRow(
                icon: "figure.walk",
                iconColor: .green,
                title: "今日步数",
                value: deviceInfo.stepCountText,
                subtitle: deviceInfo.lastUpdate.map { "更新于 \(formatDate($0))" }
            )
            
            Divider()
            
            // 电量
            DeviceInfoRow(
                icon: batteryIcon(deviceInfo.batteryState),
                iconColor: batteryColor(deviceInfo.batteryLevel),
                title: "设备电量",
                value: deviceInfo.batteryLevelText,
                subtitle: deviceInfo.batteryStateText
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 位置信息
    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                Text("位置信息")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            
            // 地图（如果有坐标）
            if let deviceInfo = member.deviceInfo {
                // TODO: 如果有经纬度，显示地图
                // 暂时显示占位
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("位置信息加载中...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 操作按钮
    private var actionSection: some View {
        VStack(spacing: 12) {
            if member.status == .pending {
                // 待接受状态，显示接受/拒绝按钮
                HStack(spacing: 12) {
                    Button(action: rejectInvite) {
                        Label("拒绝", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: acceptInvite) {
                        Label("接受", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            } else {
                // 已绑定，显示解除关系按钮
                Button(action: { showingRemoveAlert = true }) {
                    Label("解除关系", systemImage: "person.badge.minus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func batteryIcon(_ state: Int) -> String {
        switch state {
        case 2: return "battery.100.bolt"
        case 3: return "battery.100"
        default: return "battery.75"
        }
    }
    
    private func batteryColor(_ level: Float) -> Color {
        if level >= 0.5 { return .green }
        if level >= 0.2 { return .orange }
        return .red
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func acceptInvite() {
        Task {
            let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=accept_invite")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: String] = ["relation_id": member.relationId]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
            dismiss()
        }
    }
    
    private func rejectInvite() {
        Task {
            let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=reject_invite")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: String] = ["relation_id": member.relationId]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
            dismiss()
        }
    }
    
    private func removeFamily() {
        Task {
            let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=remove_family")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: String] = ["relation_id": member.relationId]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            _ = try? await URLSession.shared.data(for: request)
            dismiss()
        }
    }
}

// MARK: - 设备信息行
struct DeviceInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    FamilyMemberDetailView(member: FamilyMember(
        id: "test",
        relationId: "rel-test",
        name: "张三",
        phone: "138****0000",
        avatar: "",
        status: .accepted,
        statusText: "已绑定",
        createdAt: Date(),
        deviceInfo: DeviceInfo(
            stepCount: 8520,
            batteryLevel: 0.85,
            batteryState: 2,
            lastUpdate: Date()
        )
    ))
}
