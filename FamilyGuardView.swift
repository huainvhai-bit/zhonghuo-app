//
//  FamilyGuardView.swift
//  终活
//
//  家人守护主页 - 重新美化
//

import SwiftUI

struct FamilyGuardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var familyList: [FamilyMember] = []
    @State private var isLoading = false
    @State private var showingInviteCode = false
    @State private var showingBindFamily = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingAddMember = false  // 添加家人弹窗
    
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
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 16, weight: .semibold))
                            Text("邀请码")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "AF52DE"))
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
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView(onAdded: {
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
        VStack(spacing: 24) {
            Spacer()
            
            // 插图
            ZStack {
                Circle()
                    .fill(Color(hex: "AF52DE").opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            VStack(spacing: 12) {
                Text("还没有家人")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("邀请家人加入，互相关爱守护\n添加家人后会自动同步到紧急联系人")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: { showingAddMember = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("添加家人")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "AF52DE"), Color(hex: "8B5CF6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color(hex: "AF52DE").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: { showingBindFamily = true }) {
                    HStack {
                        Image(systemName: "link")
                        Text("绑定邀请码")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "AF52DE"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "AF52DE"), lineWidth: 1.5)
                    )
                }
                
                Button(action: { showingInviteCode = true }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("生成邀请码")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.secondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // 提示信息
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("添加的家人会自动成为紧急联系人")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 家人列表
    private var familyListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 统计卡片
                statsCard
                
                // 添加按钮
                addButtonCard
                
                // 家人列表
                ForEach(familyList) { member in
                    FamilyMemberCard(member: member, onDelete: {
                        deleteFamilyMember(member)
                    })
                }
            }
            .padding()
        }
    }
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("家人守护")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("已绑定 \(familyList.count) 位家人")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "AF52DE"), Color(hex: "8B5CF6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1.0, Double(familyList.count) / 5.0), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("至少绑定 2 位家人可获得完整守护")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(familyList.count)/2")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(familyList.count >= 2 ? .green : .orange)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - 添加按钮卡片
    private var addButtonCard: some View {
        Button(action: { showingAddMember = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("添加新家人")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(hex: "AF52DE"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "AF52DE"), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "AF52DE").opacity(0.05))
                    )
            )
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
    
    // MARK: - 删除家人
    private func deleteFamilyMember(_ member: FamilyMember) {
        Task {
            await deleteFamilyMemberAsync(member)
        }
    }
    
    @MainActor
    private func deleteFamilyMemberAsync(_ member: FamilyMember) async {
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            showingError = true
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=unbind")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "family_id": member.id
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 删除家人响应：\(httpResponse.statusCode)")
            }
            
            let result = try JSONDecoder().decode(FamilyUnbindResponse.self, from: data)
            
            if result.status == "success" {
                familyList.removeAll { $0.id == member.id }
                print("✅ 家人删除成功")
            } else {
                errorMessage = result.message ?? "删除失败"
                showingError = true
            }
        } catch {
            print("❌ 家人删除失败：\(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - 家人卡片
struct FamilyMemberCard: View {
    let member: FamilyMember
    let onDelete: () -> Void
    @State private var showingDetail = false
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
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
                        
                        Text(member.name.prefix(1))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // 信息
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(member.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if member.relationship == "配偶" {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Label(member.relationship, systemImage: "person.crop.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Label(member.phone, systemImage: "phone.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 状态
                    VStack(spacing: 4) {
                        Image(systemName: member.isConfirmed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(member.isConfirmed ? .green : .orange)
                        
                        Text(member.isConfirmed ? "已确认" : "待确认")
                            .font(.system(size: 10))
                            .foregroundColor(member.isConfirmed ? .green : .orange)
                    }
                }
                .padding(16)
                .background(Color.white)
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: { showingDetail = true }) {
                    Label("详情", systemImage: "info.circle")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
                
                Button(action: { showingDeleteConfirm = true }) {
                    Label("解除", systemImage: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "F5F5F7"))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingDetail) {
            FamilyMemberDetailView(member: member)
        }
        .alert("解除家人关系", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("解除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要解除与 \(member.name) 的家人关系吗？此操作不可恢复。")
        }
    }
}

// MARK: - 添加家人视图
struct AddFamilyMemberView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userManager = UserManager.shared
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = "配偶"
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    let relationships = ["配偶", "父母", "子女", "兄弟姐妹", "其他"]
    
    var onAdded: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("姓名", text: $name)
                        .textContentType(.name)
                    
                    TextField("手机号", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("关系", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel)
                        }
                    }
                }
                
                Section(footer: Text("添加的家人会自动成为紧急联系人，出现在紧急联系人列表和家人守护列表。")) {
                    Button(action: addFamilyMember) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("添加中...")
                            } else {
                                Text("添加家人")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting || name.isEmpty || phone.isEmpty)
                }
            }
            .navigationTitle("添加家人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("添加失败", isPresented: $showingError) {
                Button("确定") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addFamilyMember() {
        isSubmitting = true
        
        Task {
            await addFamilyMemberAsync()
        }
    }
    
    @MainActor
    private func addFamilyMemberAsync() async {
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            showingError = true
            isSubmitting = false
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            isSubmitting = false
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/family.php?action=bind")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "name": name,
                "phone": phone,
                "relationship": relationship
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 添加家人响应：\(httpResponse.statusCode)")
            }
            
            let result = try JSONDecoder().decode(FamilyBindResponse.self, from: data)
            
            if result.status == "success" {
                print("✅ 家人添加成功")
                
                // 自动添加到紧急联系人
                await addEmergencyContact()
                
                dismiss()
                onAdded?()
            } else {
                errorMessage = result.message ?? "添加失败"
                showingError = true
            }
        } catch {
            print("❌ 家人添加失败：\(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSubmitting = false
    }
    
    @MainActor
    private func addEmergencyContact() async {
        guard !DataManager.apiURL.isEmpty else {
            return
        }
        
        let token = UserDefaults.standard.string(forKey: "userToken") ?? ""
        guard !token.isEmpty else {
            return
        }
        
        do {
            let url = URL(string: "\(DataManager.apiURL)/api/emergency_contacts.php?action=add")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "name": name,
                "phone": phone,
                "relationship": relationship
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(EmergencyContactAddResponse.self, from: data)
            
            if result.status == "success" {
                print("✅ 紧急联系人添加成功")
            }
        } catch {
            print("❌ 紧急联系人添加失败：\(error)")
        }
    }
}

// MARK: - 响应模型
// FamilyListResponse 和 FamilyListData 已在 FamilyMember.swift 中定义

struct FamilyBindResponse: Codable {
    let status: String
    let message: String?
}

struct FamilyUnbindResponse: Codable {
    let status: String
    let message: String?
}

struct EmergencyContactAddResponse: Codable {
    let status: String
    let message: String?
}
