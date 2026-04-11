//
//  FamilyArchiveView.swift
//  终活
//
//  家族档案馆（V2.0.0 核心功能）
//  功能：家庭成员共享、共同编辑、家族树可视化
//

import SwiftUI
import CloudKit

// MARK: - 数据模型

struct FamilyArchive: Identifiable, Codable {
    var id: String
    var userId: String
    var archiveName: String
    var description: String?
    var coverImage: String?
    var isPublic: Bool = false
    var members: [FamilyArchiveMember]
    var createdAt: Date
    var updatedAt: Date
    
    // ✅ 计算属性
    var memberCount: Int {
        return members.count
    }
    
    var isOwner: Bool {
        return userId == UserManager.shared.currentUser?.id
    }
}

struct FamilyArchiveMember: Identifiable, Codable {
    var id: String
    var archiveId: String
    var userId: String
    var userName: String
    var userAvatar: String?
    var role: ArchiveRole
    var joinedAt: Date
    var permissions: [ArchivePermission]
    
    enum ArchiveRole: String, Codable {
        case owner = "创建者"
        case admin = "管理员"
        case editor = "编辑者"
        case viewer = "查看者"
    }
    
    enum ArchivePermission: String, Codable {
        case view = "查看"
        case edit = "编辑"
        case addMember = "添加成员"
        case delete = "删除"
    }
}

// MARK: - 主视图

struct FamilyArchiveView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var archives: [FamilyArchive] = []
    @State private var showingCreateModal = false
    @State private var selectedArchive: FamilyArchive?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 欢迎横幅
                    welcomeBanner
                    
                    // 创建按钮
                    createButton
                    
                    // 档案列表
                    archiveList
                }
                .padding()
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("家族档案馆")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // loadArchives()
            }
            .sheet(isPresented: $showingCreateModal) {
                CreateArchiveView(dataManager: dataManager)
            }
        }
    }
    
    // MARK: - 欢迎横幅
    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("家族档案馆")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("共享家族记忆，传承家族故事")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 创建按钮
    private var createButton: some View {
        Button(action: { showingCreateModal = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("创建家族档案")
            }
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "6366F1"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - 档案列表
    private var archiveList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("家族档案")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            if archives.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(archives) { archive in
                        ArchiveCard(archive: archive)
                            .onTapGesture {
                                selectedArchive = archive
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("暂无家族档案")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Text("创建第一个家族档案，与家人共享您的故事")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - 加载档案
    private func loadArchives() {
        guard UserManager.shared.isLoggedIn else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // ✅ 修复：使用 DataManager 统一函数
                let archivesData = try await DataManager.shared.fetchFamilyArchives()
                print("📡 家庭档案响应：\(archivesData)")
                
                archives = archivesData.compactMap { data -> FamilyArchive? in
                    guard let id = data["id"] as? String,
                          let archiveName = data["archiveName"] as? String else {
                        return nil
                    }
                    return FamilyArchive(
                        id: id,
                        userId: UserManager.shared.currentUser?.id ?? "",
                        archiveName: archiveName,
                        description: data["description"] as? String ?? "",
                        coverImage: nil,
                        isPublic: data["isPublic"] as? Bool ?? false,
                        members: [],
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                }
            } catch {
                print("❌ 获取家庭档案失败：\(error)")
                // return []
            }
        }
    }

// MARK: - 档案卡片

struct ArchiveCard: View {
    let archive: FamilyArchive
    
    var body: some View {
        HStack(spacing: 16) {
            // 封面（使用用户头像作为默认）
            Circle()
                .fill(avatarGradient)
                .frame(width: 70, height: 70)
                .overlay(
                    Text(archive.archiveName.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // 档案信息
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(archive.archiveName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if archive.isPublic {
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(archive.description ?? "暂无描述")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("\(archive.memberCount) 位成员")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if archive.isOwner {
                        Text("创建者")
                            .font(.system(size: 12))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "E0E7FF"))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var avatarGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 创建档案视图

struct CreateArchiveView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var archiveName = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var isLoading = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 输入区域
                VStack(spacing: 16) {
                    TextField("档案名称（必填）", text: $archiveName)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    TextField("描述（选填）", text: $description)
                        .font(.system(size: 16))
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Toggle("公开分享", isOn: $isPublic)
                        .font(.system(size: 16))
                        .padding(.horizontal)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 创建按钮
                Button(action: createArchive) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("创建档案")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(archiveName.isEmpty ? Color.gray.opacity(0.5) : Color("6366F1"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(archiveName.isEmpty || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "F5F5F7"))
            .navigationTitle("创建家族档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
    
    private func createArchive() {
        guard !archiveName.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        Task {
            do {
                // ✅ 修复：使用 DataManager 统一函数
                let success = try await DataManager.shared.createFamilyArchive(
                    archiveName: archiveName,
                    description: description,
                    isPublic: isPublic
                )
                
                if success {
                    print("✅ 家庭档案创建成功")
                    presentationMode.wrappedValue.dismiss()
                    // loadArchives() // 刷新列表
                }
            } catch {
                print("❌ 创建家庭档案失败：\(error)")
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - 预览

struct FamilyArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyArchiveView()
    }
}
}
