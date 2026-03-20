//
//  FamilyGuardView.swift
//  终活
//
//  家人守护主页
//

import SwiftUI
// CodeScanner 依赖 - 待 Xcode 正确配置后启用
// import CodeScanner

struct FamilyGuardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var familyList: [FamilyMember] = []
    @State private var isLoading = false
    @State private var showingInviteCode = false
    @State private var showingBindFamily = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F7").ignoresSafeArea()
                
                if familyList.isEmpty && !isLoading {
                    // 空状态
                    emptyState
                } else {
                    // 家人列表
                    familyListView
                }
            }
            .navigationTitle("家人守护")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInviteCode = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "qrcode")
                            Text("我的邀请码")
                        }
                        .font(.system(size: 13))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingBindFamily = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .onAppear {
                loadFamilyList()
            }
            .sheet(isPresented: $showingInviteCode) {
                InviteCodeView()
            }
            .sheet(isPresented: $showingBindFamily) {
                BindFamilyView(onBound: {
                    loadFamilyList()
                })
            }
            .refreshable {
                await loadFamilyListAsync()
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("还没有家人")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("邀请家人加入，互相关爱守护")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                Button(action: { showingInviteCode = true }) {
                    Label("生成邀请码", systemImage: "qrcode")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { showingBindFamily = true }) {
                    Label("绑定家人", systemImage: "person.badge.plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.indigo)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.indigo, lineWidth: 1.5)
                        )
                }
            }
        }
    }
    
    // MARK: - 家人列表
    private var familyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(familyList) { member in
                    FamilyMemberCard(member: member)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 数据加载
    private func loadFamilyList() {
        isLoading = true
        
        Task {
            await loadFamilyListAsync()
        }
    }
    
    @MainActor
    private func loadFamilyListAsync() async {
        isLoading = true
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            showingError = true
            isLoading = false
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            isLoading = false
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=list_family")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 家人列表响应：\(httpResponse.statusCode)")
            }
            
            let result = try JSONDecoder().decode(FamilyListResponse.self, from: data)
            
            if result.status == "success" {
                familyList = result.data?.list ?? []
                print("✅ 家人列表加载成功：\(familyList.count) 人")
            } else {
                errorMessage = result.message ?? "加载失败"
                showingError = true
            }
        } catch {
            print("❌ 家人列表加载失败：\(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
}

// MARK: - 家人卡片
struct FamilyMemberCard: View {
    let member: FamilyMember
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: 15) {
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
                        .frame(width: 50, height: 50)
                    
                    if !member.avatar.isEmpty {
                        AsyncImage(url: URL(string: member.avatar)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(member.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if member.status == .pending {
                            Text("待接受")
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                    }
                    
                    if let deviceInfo = member.deviceInfo {
                        HStack(spacing: 12) {
                            // 步数
                            Label(deviceInfo.stepCountText, systemImage: "figure.walk")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            // 电量
                            HStack(spacing: 2) {
                                Text(deviceInfo.batteryLevelText)
                                    .font(.system(size: 12))
                                Text(deviceInfo.batteryStateIcon)
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Text(member.status == .pending ? "等待接受邀请" : "暂无设备信息")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .sheet(isPresented: $showingDetail) {
            FamilyMemberDetailView(member: member)
        }
    }
}

#Preview {
    FamilyGuardView()
}
