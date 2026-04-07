//
//  Family/FamilyGuardView.swift
//  终活
//
//  家人守护主页
//  职责：家人列表 + 绑定邀请码 + 二维码分享
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct FamilyGuardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var userManager = UserManager.shared
    @State private var familyList: [FamilyMember] = []
    @State private var isLoading = true
    @State private var showingBindFamily = false
    @State private var showingShareQR = false
    @State private var showingScanner = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var inviteCode = ""
    @State private var qrImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F7").ignoresSafeArea()
                
                if isLoading {
                    loadingState
                } else if familyList.isEmpty {
                    emptyState
                } else {
                    familyListView
                }
            }
            .navigationTitle("家人守护")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupNavigationBar()
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
                        }
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FamilyListUpdated"))) { _ in
                Task {
                    await loadFamilyListAsync()
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 视图状态
    
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(hex: "AF52DE"))
            Text("正在加载家人列表...")
                .foregroundColor(.secondary)
        }
        .onAppear {
            Task {
                await loadFamilyListAsync()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("暂无家人")
                    .font(.headline)
                Text("邀请家人加入守护，相互关爱")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingBindFamily = true }) {
                Text("邀请家人")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(hex: "AF52DE"))
                    .cornerRadius(12)
            }
            
            Button(action: { showingShareQR = true }) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("分享二维码")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "AF52DE"))
            }
        }
    }
    
    private var familyListView: some View {
        List {
            Section {
                familyList
                    .forEach { member in
                        FamilyMemberRow(member: member)
                    }
            } header: {
                HStack {
                    Text("家人列表（\(familyList.count)）")
                        .font(.headline)
                    Spacer()
                    Button(action: { showingShareQR = true }) {
                        Image(systemName: "qrcode")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - 加载家人列表
    
    @MainActor
    private func loadFamilyListAsync() async {
        isLoading = true
        
        do {
            let query = """
            query {
                getFamilyMembers {
                    id
                    name
                    phone
                    relation
                    status
                    createdAt
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query, variables: [:])
            print("📡 GraphQL 家人列表响应：\(result)")
            
            if let data = result["data"] as? [String: Any],
               let members = data["getFamilyMembers"] as? [[String: Any]] {
                await MainActor.run {
                    familyList = members.map { member in
                        FamilyMember(
                            id: member["id"] as? String ?? "",
                            name: member["name"] as? String ?? "",
                            phone: member["phone"] as? String ?? "",
                            relation: member["relation"] as? String ?? "",
                            status: member["status"] as? String ?? "",
                            createdAt: member["createdAt"] as? Date ?? Date()
                        )
                    }
                    isLoading = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isLoading = false
            print("❌ 获取家人列表失败：\(error)")
        }
    }
    
    private func loadFamilyList() {
        Task {
            await loadFamilyListAsync()
        }
    }
    
    // MARK: - 邀请码生成
    
    private func generateInviteCode() async {
        do {
            let query = """
            mutation {
                generateInviteCode {
                    success
                    data {
                        inviteCode
                        qrUrl
                    }
                }
            }
            """
            
            let result = try await GraphQLClient.shared.query(query, variables: [:])
            
            if let data = result["data"] as? [String: Any],
               let inviteResult = data["generateInviteCode"] as? [String: Any],
               let success = inviteResult["success"] as? Bool,
               success,
               let resultData = inviteResult["data"] as? [String: Any] {
                let inviteCode = resultData["inviteCode"] as? String ?? ""
                let qrURL = resultData["qrUrl"] as? String ?? ""
                self.inviteCode = inviteCode
                self.qrImage = generateQRCode(from: inviteCode)
                print("✅ 邀请码：\(inviteCode)")
            }
        } catch {
            print("❌ 生成邀请码失败：\(error)")
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
        if let url = URL(string: string),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            return code.uppercased().replacingOccurrences(of: "-", with: "")
        }
        
        let cleaned = string.uppercased().replacingOccurrences(of: "-", with: "")
        if cleaned.count == 6 {
            return cleaned
        }
        
        return ""
    }
    
    @MainActor
    private func bindInviteCode(_ inviteCode: String) async {
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
                }
            }
            """
            
            let variables: [String: Any] = ["inviteCode": inviteCode]
            let result = try await GraphQLClient.shared.query(query, variables: variables)
            
            if let data = result["data"] as? [String: Any],
               let bindFamily = data["bindFamilyByInviteCode"] as? [String: Any],
               let success = bindFamily["success"] as? Bool,
               success {
                await loadFamilyListAsync()
                return
            } else {
                errorMessage = bindFamily?["message"] as? String ?? "绑定失败"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        showingError = true
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "AF52DE")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - 家庭成员结构
struct FamilyMember: Identifiable, Equatable {
    let id: String
    let name: String
    let phone: String
    let relation: String
    let status: String
    let createdAt: Date
    
    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 家庭成员行
struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack {
            Text(member.name)
                .font(.body)
            Spacer()
            Text(member.relation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FamilyGuardView()
}
