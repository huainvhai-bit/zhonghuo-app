//
//  FamilyGuardView.swift
//  终活
//
//  家人守护主页 - 优化版
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// 使用 APIManager 进行 GraphQL API 调用

struct FamilyGuardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var familyList: [FamilyMember] = []
    @State private var isLoading = true  // ✅ 修复 #2: 初始状态为加载中
    @State private var showingBindFamily = false
    @State private var showingShareQR = false
    @State private var showingScanner = false
    @State private var showingManualInput = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingUpgradeForFamily = false
    @State private var showingMembershipView = false
    @State private var inviteCode = ""
    @State private var qrImage: UIImage?
    @State private var showingFamilyArchive = false  // 📚 家族档案
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if isLoading {
                    // 加载状态
                    loadingState
                } else if familyList.isEmpty {
                    // 空状态
                    emptyState
                } else {
                    // 家人列表
                    familyListView
                }
            }
            // ✅ Bug 4 修复：移除 large 标题模式，避免与 toolbar 标题重复
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupNavigationBar()
                
                print("🔵 家人守护页面 onAppear")
                
                // ✅ 修复 #8: 只加载家人列表，不自动获取邀请码（避免卡顿）
                // 邀请码只在点击"查看二维码"时才获取
                Task {
                    await loadFamilyListAsync()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("家人守护")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // 📚 家族档案按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFamilyArchive = true }) {
                        Image(systemName: "folder.fill")
                    }
                }
            }
            .sheet(isPresented: $showingFamilyArchive) {
                FamilyArchiveView()
            }
            .sheet(isPresented: $showingBindFamily) {
                BindFamilyView(onBound: {
                    loadFamilyList()
                })
            }
            .sheet(isPresented: $showingShareQR) {
                ShareQRView(
                    inviteCode: $inviteCode,
                    qrImage: $qrImage,
                    onRefresh: {
                        Task {
                            await generateInviteCode()
                        }
                    }
                )
                .onAppear {
                    // 打开页面时确保有邀请码
                    if inviteCode.isEmpty {
                        Task {
                            await generateInviteCode()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView(
                    onCodeScanned: { code in
                        showingScanner = false
                        let cleaned = extractInviteCode(from: code)
                        if !cleaned.isEmpty {
                            Task {
                                await bindInviteCode(cleaned)
                            }
                        } else {
                            errorMessage = "无效的二维码"
                            showingError = true
                        }
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
            }
            .sheet(isPresented: $showingManualInput) {
                ManualInputInviteCodeView(onBound: {
                    showingManualInput = false
                    loadFamilyList()
                }, onCancel: {
                    showingManualInput = false
                })
            }
            .sheet(isPresented: $showingUpgradeForFamily) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    UpgradePromptView(
                        feature: "绑定家人",
                        statusText: "当前家人数量已达上限",
                        currentLimit: "当前最多 \(MembershipManager.shared.currentFamilyLimit()) 位家人",
                        targetLimit: "会员版可绑定更多家人",
                        onUpgrade: {
                            showingUpgradeForFamily = false
                            showingMembershipView = true
                        },
                        onCancel: {
                            showingUpgradeForFamily = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingMembershipView) {
                NavigationView {
                    MembershipView()
                }
            }
            .refreshable {
                await loadFamilyListAsync()
            }
        }
    }
    
    // MARK: - 加载状态
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在加载家人列表...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 操作卡片区
                VStack(spacing: 16) {
                    // 1. 扫码关联家人
                    actionCard(
                        icon: "qrcode.viewfinder",
                        iconColor: Color(hex: "6366F1"),
                        title: "扫码关联家人",
                        subtitle: "扫描家人的邀请码，快速绑定关系",
                        buttonTitle: "开始扫码",
                        buttonColor: Color(hex: "6366F1")
                    ) {
                        if !MembershipManager.shared.canAddFamilyMember(currentCount: familyList.count) {
                            showingUpgradeForFamily = true
                            return
                        }
                        showingScanner = true
                    }
                    
                    // 2. 分享我的二维码
                    actionCard(
                        icon: "qrcode",
                        iconColor: Color(hex: "AF52DE"),
                        title: "分享我的二维码",
                        subtitle: "家人扫描下方二维码绑定你",
                        buttonTitle: "查看二维码",
                        buttonColor: Color(hex: "AF52DE")
                    ) {
                        showingShareQR = true
                    }
                    
                    // 3. 手动输入邀请码 - ✅ 修复 #8: 改用 sheet 方式
                    actionCard(
                        icon: "textformat",
                        iconColor: Color(hex: "F59E0B"),
                        title: "手动输入邀请码",
                        subtitle: "如果无法扫码，可以手动输入 6 位邀请码",
                        buttonTitle: "立即输入",
                        buttonColor: Color(hex: "F59E0B")
                    ) {
                        if !MembershipManager.shared.canAddFamilyMember(currentCount: familyList.count) {
                            showingUpgradeForFamily = true
                            return
                        }
                        showingManualInput = true
                    }
                }
                
                // 空状态提示卡片
                emptyFamilyCard
            }
            .padding()
        }
    }
    
    // MARK: - 空家人卡片
    private var emptyFamilyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "10B981").opacity(0.5))
                
                Text("已关联的家人")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("暂时还没有绑定家人")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("使用上方功能绑定家人，互相关爱守护")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 家人列表视图
    private var familyListView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 操作卡片区
                VStack(spacing: 16) {
                    // 1. 扫码关联家人
                    actionCard(
                        icon: "qrcode.viewfinder",
                        iconColor: Color(hex: "6366F1"),
                        title: "扫码关联家人",
                        subtitle: "扫描家人的邀请码，快速绑定关系",
                        buttonTitle: "开始扫码",
                        buttonColor: Color(hex: "6366F1")
                    ) {
                        showingScanner = true
                    }
                    
                    // 2. 分享我的二维码
                    actionCard(
                        icon: "qrcode",
                        iconColor: Color(hex: "AF52DE"),
                        title: "分享我的二维码",
                        subtitle: "家人扫描下方二维码绑定你",
                        buttonTitle: "查看二维码",
                        buttonColor: Color(hex: "AF52DE")
                    ) {
                        showingShareQR = true
                    }
                    
                    // 3. 手动输入邀请码 - ✅ 修复 #8: 改用 sheet 方式
                    actionCard(
                        icon: "textformat",
                        iconColor: Color(hex: "F59E0B"),
                        title: "手动输入邀请码",
                        subtitle: "如果无法扫码，可以手动输入 6 位邀请码",
                        buttonTitle: "立即输入",
                        buttonColor: Color(hex: "F59E0B")
                    ) {
                        showingManualInput = true
                    }
                }
                
                // 4. 已关联家人列表
                familyListSection
            }
            .padding()
        }
    }
    
    // MARK: - 操作卡片
    private func actionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
                    .frame(width: 60, height: 60)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 家人列表
    private var familyListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "10B981"))
                
                Text("已关联的家人")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("\(familyList.count) 人")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            ForEach(familyList) { member in
                FamilyMemberCard(member: member, onDelete: {
                    loadFamilyList()
                })
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 方法
    
    private func loadFamilyList() {
        isLoading = true
        Task {
            await loadFamilyListAsync()
        }
    }
    
    @MainActor
    private func loadFamilyListAsync() async {
        // ✅ 修复：使用 defer 确保 isLoading 总是被重置
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        isLoading = true
        
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            print("⚠️ 加载家人列表失败：Token 为空")
            return
        }
        guard !DataManager.apiURL.isEmpty else {
            print("⚠️ 加载家人列表失败：API URL 为空")
            return
        }
        
        print("🔵 开始加载家人列表...")
        
        do {
            // 使用 GraphQL family query
            let query = """
            query {
                family {
                    success
                    message
                    data {
                        members {
                            id
                            name
                            phone
                            relation
                            status
                            createdAt
                        }
                        invited {
                            id
                            name
                            phone
                            relation
                            status
                            createdAt
                        }
                    }
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query)
            print("📡 GraphQL 家人列表响应：\(result)")
            
            if let data = result["data"] as? [String: Any],
               let familyResult = data["family"] as? [String: Any],
               let success = familyResult["success"] as? Bool,
               success {
                if let familyData = familyResult["data"] as? [String: Any] {
                    // 解析 members
                    if let members = familyData["members"] as? [[String: Any]] {
                        let newFamilyList = members.compactMap { member in
                            FamilyMember(
                                id: member["id"] as? String ?? "",
                                relationId: member["id"] as? String ?? "",
                                name: member["name"] as? String ?? "",
                                phone: member["phone"] as? String ?? "",
                                avatar: member["avatar"] as? String ?? "",
                                relationship: member["relation"] as? String ?? "",
                                status: .accepted,
                                statusText: "已绑定",
                                createdAt: Date(),
                                deviceInfo: nil
                            )
                        }
                        self.familyList = newFamilyList
                    }
                    
                    print("✅ 家人列表加载成功：\(familyList.count) 人")
                }
            } else if let familyResult = (result["data"] as? [String: Any])?["family"] as? [String: Any] {
                let message = familyResult["message"] as? String ?? "加载失败"
                print("❌ 家人列表加载失败：\(message)")
            }
        } catch {
            print("❌ 加载家人列表失败：\(error)")
        }
    }
    
    @MainActor
    private func generateInviteCode() async {
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            print("❌ Token 为空")
            return
        }
        guard !DataManager.apiURL.isEmpty else {
            print("❌ API URL 为空")
            return
        }
        
        print("🔵 开始生成邀请码...")
        
        do {
            print("🔵 开始获取邀请码（GraphQL）...")
            
            // 使用 GraphQL getInviteCode query
            let query = """
            query {
                getInviteCode {
                    success
                    message
                    data { inviteCode qrUrl }
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query)
            print("📡 GraphQL 邀请码响应：\(result)")
            
            if let data = result["data"] as? [String: Any],
               let inviteResult = data["getInviteCode"] as? [String: Any] {
                let success = inviteResult["success"] as? Bool ?? false
                if success {
                    if let resultData = inviteResult["data"] as? [String: Any] {
                        let inviteCode = resultData["inviteCode"] as? String ?? ""
                        _ = resultData["qrUrl"] as? String ?? ""
                        print("✅ 邀请码：\(inviteCode)")
                        self.inviteCode = inviteCode
                        self.qrImage = generateQRCode(from: inviteCode)
                        print("✅ 二维码生成完成")
                    }
                } else {
                    let message = inviteResult["message"] as? String ?? "未知错误"
                    print("❌ 邀请码生成失败：\(message)")
                }
            }
        } catch {
            print("❌ 生成邀请码失败：\(error)")
            print("❌ 错误详情：\(error.localizedDescription)")
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func extractInviteCode(from string: String) -> String {
        // 尝试从 URL 中提取 code 参数
        if let url = URL(string: string),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            return code.uppercased().replacingOccurrences(of: "-", with: "")
        }
        
        // 直接是 6 位邀请码
        let cleaned = string.uppercased().replacingOccurrences(of: "-", with: "")
        if cleaned.count == 6 {
            return cleaned
        }
        
        return ""
    }
    
    // ✅ 扫码绑定邀请码
    @MainActor
    private func bindInviteCode(_ inviteCode: String) async {
        let currentCount = familyList.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            errorMessage = "家人数量已达上限，升级会员可绑定更多家人"
            showingError = true
            return
        }
        
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未初始化"
            showingError = true
            return
        }
        
        do {
            let query = """
            mutation($inviteCode: String!) {
                bindFamilyByInviteCode(inviteCode: $inviteCode) {
                    success
                    message
                    data {
                        members { id name phone relation status createdAt }
                        invited { id name phone relation status createdAt }
                    }
                }
            }
            """
            
            let variables: [String: Any] = ["inviteCode": inviteCode]
            let result = try await GraphQLClient.shared.query(query, variables: variables)
            print("📡 GraphQL 绑定家人响应：\(result)")
            
            if let data = result["data"] as? [String: Any],
               let bindFamily = data["bindFamilyByInviteCode"] as? [String: Any] {
                let success = bindFamily["success"] as? Bool ?? false
                if success {
                    await loadFamilyListAsync()
                    return
                } else {
                    errorMessage = bindFamily["message"] as? String ?? "绑定失败"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        showingError = true
    }
}

// MARK: - 分享二维码视图
struct ShareQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var inviteCode: String
    @Binding var qrImage: UIImage?
    let onRefresh: () -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("分享我的邀请码")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("家人扫描下方二维码绑定你")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 二维码
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 260, height: 260)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 220, height: 220)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("正在生成...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 刷新按钮
                Button(action: refreshQRCode) {
                    HStack {
                        Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        Text("刷新二维码")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "AF52DE"))
                }
                .disabled(isRefreshing)
                
                // 邀请码
                VStack(spacing: 8) {
                    Text("邀请码")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    if inviteCode.isEmpty {
                        Text("正在获取...")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Text(inviteCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "AF52DE"))
                            .textSelection(.enabled)
                    }
                }
                .padding()
                .background(Color(hex: "AF52DE").opacity(0.1))
                .cornerRadius(12)
                
                // 提示文字
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("可手动输入邀请码绑定")
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // 复制按钮
                Button(action: copyInviteCode) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("复制邀请码")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(inviteCode.isEmpty ? Color.gray : Color(hex: "AF52DE"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(inviteCode.isEmpty)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding()
            .navigationTitle("分享邀请码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func refreshQRCode() {
        isRefreshing = true
        // 直接调用 onRefresh，它会触发 generateInviteCode
        onRefresh()
        // 2 秒后重置刷新状态（给 API 调用足够时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isRefreshing = false
        }
    }
    
    private func copyInviteCode() {
        UIPasteboard.general.string = inviteCode
    }
}

#Preview {
    FamilyGuardView()
}

// MARK: - 导航栏样式设置
extension FamilyGuardView {
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "6366F1")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - 家人卡片
struct FamilyMemberCard: View {
    let member: FamilyMember
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(Color(hex: "AF52DE").opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "AF52DE"))
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(member.name)
                            .font(.system(size: 16, weight: .semibold))
                        
                        // 关系标签
                        Text(member.relationship)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "AF52DE").opacity(0.1))
                            .foregroundColor(Color(hex: "AF52DE"))
                            .cornerRadius(4)
                    }
                    
                    Text(member.phone)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态
                if member.status == .pending {
                    Text("待接受")
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "F59E0B").opacity(0.1))
                        .foregroundColor(Color(hex: "F59E0B"))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
                
                // 删除按钮
                Button(action: { showingDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
            
            // 设备信息（如果有）
            if let deviceInfo = member.deviceInfo {
                Divider()
                
                HStack(spacing: 20) {
                    // 步数
                    HStack(spacing: 6) {
                        Image(systemName: "footprints")
                            .foregroundColor(Color(hex: "6366F1"))
                        Text(deviceInfo.stepCountText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // 电量
                    HStack(spacing: 6) {
                        Text(deviceInfo.batteryStateIcon)
                        Text("\(deviceInfo.batteryLevelText)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .confirmationDialog("解除关系", isPresented: $showingDeleteConfirm) {
            Button("解除", role: .destructive) {
                deleteMember()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要与 \(member.name) 解除家人关系吗？此操作不可恢复。")
        }
    }
    
    private func deleteMember() {
        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else { return }
        guard !DataManager.apiURL.isEmpty else { return }
        
        Task {
            do {
                // 使用 GraphQL removeFamily mutation
                let query = """
                mutation($relationId: String!) {
                    removeFamily(relationId: $relationId) {
                        success
                        message
                    }
                }
                """
                
                let variables: [String: Any] = ["relationId": member.relationId]
                let result = try await GraphQLClient.shared.query(query, variables: variables)
                print("📡 GraphQL 删除家人响应：\(result)")
                
                if let data = result["data"] as? [String: Any],
                   let removeFamily = data["removeFamily"] as? [String: Any] {
                    let success = removeFamily["success"] as? Bool ?? false
                    if success {
                        print("✅ 删除家人成功")
                        onDelete()
                    } else {
                        let message = removeFamily["message"] as? String ?? "删除失败"
                        print("❌ 删除家人失败：\(message)")
                    }
                }
            } catch {
                print("❌ 删除失败：\(error)")
            }
        }
    }
}

// MARK: - 手动输入邀请码视图 (内联) - ✅ 修复 #6
struct ManualInputInviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isBinding = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onBound: (() -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text("手动输入邀请码")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text("请输入家人分享给你的 6 位邀请码，完成绑定后你们将互相关爱守护。")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(hex: "FFF9E6"))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("邀请码")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("6 位邀请码", text: $inviteCode)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .textContentType(.oneTimeCode)
                    .keyboardType(.asciiCapable)
                    .autocapitalization(.allCharacters)
                    .onChange(of: inviteCode) { newValue in
                        if newValue.count > 6 { inviteCode = String(newValue.prefix(6)) }
                        inviteCode = newValue.uppercased()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: bindInviteCode) {
                HStack {
                    if isBinding {
                        ProgressView().tint(.white).scaleEffect(0.8)
                        Text("绑定中...")
                    } else {
                        Text("立即绑定").font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(inviteCode.count == 6 && !isBinding ? Color(hex: "F59E0B") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(inviteCode.count != 6 || isBinding)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("手动输入邀请码")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onCancel?() }
            }
        }
        .alert("绑定失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: { Text(errorMessage) }
    }
    
    private func bindInviteCode() {
        let currentCount = DataManager.shared.familyMembers.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            errorMessage = "家人数量已达上限，升级会员可绑定更多家人"
            showError = true
            return
        }
        
        guard inviteCode.count == 6 else { return }
        isBinding = true
        Task {
            do {
                let query = """
                mutation($inviteCode: String!) {
                    bindFamilyByInviteCode(inviteCode: $inviteCode) {
                        success
                        message
                        data {
                            members { id name phone relation status createdAt }
                            invited { id name phone relation status createdAt }
                        }
                    }
                }
                """
                let result = try await GraphQLClient.shared.query(query, variables: ["inviteCode": inviteCode])
                if let data = result["data"] as? [String: Any],
                   let bindFamily = data["bindFamilyByInviteCode"] as? [String: Any],
                   let success = bindFamily["success"] as? Bool, success {
                    await MainActor.run { onBound?(); dismiss() }
                    return
                }
                throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "绑定失败"])
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; showError = true }
            }
            await MainActor.run { isBinding = false }
        }
    }
}
