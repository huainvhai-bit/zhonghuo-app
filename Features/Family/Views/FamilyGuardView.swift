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
    @Environment(\.scenePhase) private var scenePhase
    @State private var familyList: [FamilyMember] = []
    @State private var isLoading = true  // ✅ 修复 #2: 初始状态为加载中
    @State private var didInitialLoad = false
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
    @State private var showingInviteConfirmation = false
    @State private var pendingInvitePreview: FamilyInvitePreview?
    @State private var pendingFamilyRequests: [FamilyPendingRequest] = []
    @State private var familyRefreshTask: Task<Void, Never>?
    @State private var confirmingRequestId: String?
    @State private var isManualRefreshing = false

    private var approvalFamilyRequests: [FamilyPendingRequest] {
        pendingFamilyRequests.filter { $0.needsMyApproval }
    }

    private var waitingFamilyRequests: [FamilyPendingRequest] {
        pendingFamilyRequests.filter { !$0.needsMyApproval }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if isLoading {
                    // 加载状态
                    loadingState
                } else if familyList.isEmpty && pendingFamilyRequests.isEmpty {
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

                // 进入家人 tab 时拉一次最新的家人列表（含每个家人最新的"安全倒计时"），
                // 不再用后台 30s 轮询，避免 tab 频繁刷新；
                // 首次进入显示 loading，再次进入静默刷新避免闪烁
                let isFirstAppear = !didInitialLoad
                didInitialLoad = true
                Task {
                    await loadFamilyListAsync(showLoading: isFirstAppear)
                }
            }
            .onDisappear {
                stopFamilyPolling()
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active else { return }
                Task { await loadFamilyListAsync(showLoading: false) }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(L10n.string(.familyGuard))
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
            .confirmationDialog(
                L10n.text("确认家人绑定", en: "Confirm family binding", ja: "家族連携を確認", ko: "가족 연결 확인"),
                isPresented: $showingInviteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.text("提交申请", en: "Submit request", ja: "申請を送信", ko: "요청 제출")) {
                    Task { await acceptPendingInvite() }
                }
                Button(L10n.string(.cancel), role: .cancel) {
                    pendingInvitePreview = nil
                }
            } message: {
                if let preview = pendingInvitePreview {
                    Text(L10n.text(
                        "将与 \(preview.inviterName)（账号：\(preview.inviterAccount.isEmpty ? "未知" : preview.inviterAccount)）提交绑定申请，等待对方最终确认后才会正式生效。",
                        en: "You are about to submit a binding request with \(preview.inviterName) (account: \(preview.inviterAccount.isEmpty ? "unknown" : preview.inviterAccount)). The binding becomes official only after the other side confirms it.",
                        ja: "\(preview.inviterName)（アカウント：\(preview.inviterAccount.isEmpty ? "不明" : preview.inviterAccount)）へ連携申請を送信します。相手が最終確認してから正式に有効になります。",
                        ko: "\(preview.inviterName)(계정: \(preview.inviterAccount.isEmpty ? "알 수 없음" : preview.inviterAccount))에게 연결 요청을 제출합니다. 상대방이 최종 확인해야 정식으로 적용됩니다."
                    ))
                }
            }
            .sheet(isPresented: $showingFamilyArchive) {
                FamilyArchiveView()
            }
            .sheet(isPresented: $showingBindFamily) {
                BindFamilyView(onBound: {
                    Task { await loadFamilyListAsync(showLoading: false) }
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
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 250_000_000)
                                await bindInviteCode(cleaned)
                            }
                        } else {
                            errorMessage = L10n.string(.invalidQRCode)
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
                    Task { await loadFamilyListAsync(showLoading: false) }
                }, onCancel: {
                    showingManualInput = false
                })
            }
            .sheet(isPresented: $showingUpgradeForFamily) {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    UpgradePromptView(
                        feature: L10n.string(.familyGuard),
                        statusText: L10n.string(.familyLimitReached),
                        currentLimit: String(format: L10n.string(.familyLimitCurrent), "\(MembershipManager.shared.currentFamilyLimit())"),
                        targetLimit: L10n.string(.familyLimitTarget),
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
        .stackNavigationStyle()
    }
    
    // MARK: - 加载状态
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(L10n.string(.loadingFamilyListTitle))
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
                        title: L10n.string(.scanFamilyTitle),
                        subtitle: L10n.string(.scanFamilySubtitle),
                        buttonTitle: L10n.string(.scanFamilyButton),
                        buttonColor: Color(hex: "6366F1")
                    ) {
                        handleFamilyBindEntry {
                            showingScanner = true
                        }
                    }
                    
                    // 2. 分享我的二维码
                    actionCard(
                        icon: "qrcode",
                        iconColor: Color(hex: "AF52DE"),
                        title: L10n.string(.shareQRCodeTitle),
                        subtitle: L10n.string(.shareQRCodeSubtitle),
                        buttonTitle: L10n.string(.shareQRCodeButton),
                        buttonColor: Color(hex: "AF52DE")
                    ) {
                        showingShareQR = true
                    }
                    
                    // 3. 手动输入邀请码 - ✅ 修复 #8: 改用 sheet 方式
                    actionCard(
                        icon: "textformat",
                        iconColor: Color(hex: "F59E0B"),
                        title: L10n.string(.manualInviteTitle),
                        subtitle: L10n.string(.manualInviteSubtitle),
                        buttonTitle: L10n.string(.manualInviteButton),
                        buttonColor: Color(hex: "F59E0B")
                    ) {
                        handleFamilyBindEntry {
                            showingManualInput = true
                        }
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
                
                Text(L10n.string(.linkedFamily))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text(L10n.string(.noFamilyBoundTitle))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text(L10n.string(.noFamilyBoundHint))
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
                        title: L10n.string(.scanFamilyTitle),
                        subtitle: L10n.string(.scanFamilySubtitle),
                        buttonTitle: L10n.string(.scanFamilyButton),
                        buttonColor: Color(hex: "6366F1")
                    ) {
                        handleFamilyBindEntry {
                            showingScanner = true
                        }
                    }
                    
                    // 2. 分享我的二维码
                    actionCard(
                        icon: "qrcode",
                        iconColor: Color(hex: "AF52DE"),
                        title: L10n.string(.shareQRCodeTitle),
                        subtitle: L10n.string(.shareQRCodeSubtitle),
                        buttonTitle: L10n.string(.shareQRCodeButton),
                        buttonColor: Color(hex: "AF52DE")
                    ) {
                        showingShareQR = true
                    }
                    
                    // 3. 手动输入邀请码 - ✅ 修复 #8: 改用 sheet 方式
                    actionCard(
                        icon: "textformat",
                        iconColor: Color(hex: "F59E0B"),
                        title: L10n.string(.manualInviteTitle),
                        subtitle: L10n.string(.manualInviteSubtitle),
                        buttonTitle: L10n.string(.manualInviteButton),
                        buttonColor: Color(hex: "F59E0B")
                    ) {
                        handleFamilyBindEntry {
                            showingManualInput = true
                        }
                    }
                }
                
                // 4. 已关联家人列表
                if !approvalFamilyRequests.isEmpty {
                    pendingRequestsSection
                }

                if !waitingFamilyRequests.isEmpty {
                    awaitingRequestsSection
                }

                // 5. 已关联家人列表
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "10B981"))

                Text(L10n.string(.linkedFamily))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(familyList.count) \(L10n.string(.familyCountSuffix))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Button {
                    Task {
                        isManualRefreshing = true
                        await loadFamilyListAsync(showLoading: false)
                        isManualRefreshing = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(.degrees(isManualRefreshing ? 360 : 0))
                        .animation(isManualRefreshing
                                   ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                   : .default,
                                   value: isManualRefreshing)
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.leading, 4)
                }
                .accessibilityLabel(L10n.text("刷新家人列表",
                                              en: "Refresh family list",
                                              ja: "家族リストを更新",
                                              ko: "가족 목록 새로고침"))
            }

            Text(L10n.text(
                "如绑定后未显示确认请求，请点击右上角刷新；倒计时按对方账号的设置自动同步。",
                en: "If a binding confirmation isn't shown after pairing, tap the refresh button. Countdowns sync to the other party's settings.",
                ja: "連携後に確認リクエストが表示されない場合は更新ボタンを押してください。カウントダウンは相手側の設定に同期します。",
                ko: "연결 후 확인 요청이 보이지 않으면 새로고침 버튼을 누르세요. 카운트다운은 상대방 설정에 따라 동기화됩니다."))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if familyList.isEmpty {
                Text(pendingFamilyRequests.isEmpty
                     ? L10n.text("暂时还没有已绑定的家人", en: "No family members bound yet.", ja: "まだ家族は連携されていません。", ko: "아직 연결된 가족이 없습니다.")
                     : L10n.text("已有家人申请在处理中，确认后会显示在这里", en: "There is a family request in progress. It will appear here after confirmation.", ja: "家族申請が進行中です。確認後にここへ表示されます。", ko: "가족 요청이 진행 중입니다. 확인 후 여기에 표시됩니다."))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(familyList) { member in
                    FamilyMemberCard(member: member, onDelete: {
                        Task { await loadFamilyListAsync(showLoading: false) }
                    })
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - 待确认请求
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "F59E0B"))

                Text(L10n.text("待我确认的家人申请", en: "Family requests waiting for my confirmation", ja: "私の確認待ちの家族申請", ko: "내 확인을 기다리는 가족 요청"))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(approvalFamilyRequests.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            ForEach(approvalFamilyRequests) { request in
                FamilyPendingRequestCard(
                    request: request,
                    showsConfirmButton: true,
                    isConfirming: confirmingRequestId == request.id,
                    onConfirm: {
                        Task { await finalizePendingFamilyRequest(request) }
                    }
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - 等待对方确认
    private var awaitingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "6366F1"))

                Text(L10n.text("等待对方确认", en: "Waiting for the other side", ja: "相手の確認待ち", ko: "상대방 확인 대기"))
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(waitingFamilyRequests.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            ForEach(waitingFamilyRequests) { request in
                FamilyPendingRequestCard(
                    request: request,
                    showsConfirmButton: false,
                    isConfirming: false,
                    onConfirm: {}
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - 方法
    
    /// 后端 `members[].id` 为家人关系表主键；分享胶囊需传对方 **`users.id`**（与 `family_relations.related_user_id` 一致）
    private static func relatedUserIdFromFamilyMemberPayload(_ member: [String: Any]) -> String {
        for key in ["relatedUserId", "related_user_id"] {
            guard let raw = member[key] as? String else { continue }
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return ""
    }

    /// 加载家人列表：`showLoading: true` 时使用全屏 Progress；必须在结束时仍走完整函数返回路径以清空 `isLoading`，切勿在未传 `showLoading:true` 时抢先写 `isLoading = true`
    @MainActor
    private func loadFamilyListAsync(showLoading: Bool = false) async {
        // 仅在首屏/显式要求时显示加载占位，避免后台轮询导致 tab 反复闪烁
        if showLoading {
            isLoading = true
        }
        defer {
            if showLoading {
                isLoading = false
            }
        }

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
                            relatedUserId
                            name
                            phone
                            relation
                            status
                            createdAt
                            relatedUserLastCheckInDate
                            relatedUserCheckInExpireAt
                            relatedUserIsFamilyMode
                        }
                        invited {
                            id
                            name
                            phone
                            relation
                            status
                            createdAt
                        }
                        pendingRequests {
                            id
                            invite_code
                            inviter_id
                            accepted_by
                            inviterName
                            inviterPhone
                            inviterAccount
                            acceptedByName
                            acceptedByPhone
                            acceptedByAccount
                            needsMyApproval
                            relation_type
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
                        let newFamilyList = members.compactMap { member -> FamilyMember? in
                            let relationRowId = (member["id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !relationRowId.isEmpty else { return nil }
                            let peerUid = Self.relatedUserIdFromFamilyMemberPayload(member)
                            // `id` 为关系行主键；分享胶囊等 API 需要对方用户 UUID（relatedUserId）
                            let stableMemberId = peerUid.isEmpty ? relationRowId : peerUid
                            return FamilyMember(
                                id: stableMemberId,
                                relationId: relationRowId,
                                name: member["name"] as? String ?? "",
                                phone: member["phone"] as? String ?? "",
                                avatar: member["avatar"] as? String ?? "",
                                relationship: member["relation"] as? String ?? "",
                                status: .accepted,
                                statusText: L10n.string(.bindSuccess),
                                lastCheckInDate: relatedUserCheckInDate(from: member),
                                nextCheckInDeadline: relatedUserCheckInDeadline(from: member),
                                isFamilyMode: relatedUserIsFamilyMode(from: member),
                                createdAt: parseBackendDate(member["createdAt"] as? String) ?? Date(),
                                deviceInfo: nil
                            )
                        }
                        // 仅当数据真的变化时再 set，避免 SwiftUI 不必要的重渲染
                        if !sameFamilyList(self.familyList, newFamilyList) {
                            self.familyList = newFamilyList
                            DataManager.shared.updateFamilyMembersCache(newFamilyList.map { member in
                                FamilyInfo(
                                    id: member.relationId,
                                    relationType: member.relationship,
                                    relatedUserId: member.id,
                                    relatedUserName: member.name,
                                    relatedUserPhone: member.phone,
                                    relatedUserLastCheckInDate: member.lastCheckInDate
                                )
                            })
                        }
                    }

                    let parsedRequests: [FamilyPendingRequest]
                    if let pendingRequests = familyData["pendingRequests"] as? [[String: Any]] {
                        parsedRequests = pendingRequests.compactMap { request in
                            guard let id = request["id"] as? String, !id.isEmpty else { return nil }
                            let createdAt = parseBackendDate(request["created_at"] as? String ?? request["createdAt"] as? String)
                            let inviterName = request["inviterName"] as? String ?? ""
                            let inviterPhone = request["inviterPhone"] as? String ?? ""
                            let inviterAccount = request["inviterAccount"] as? String ?? ""
                            let acceptedByName = request["acceptedByName"] as? String ?? ""
                            let acceptedByPhone = request["acceptedByPhone"] as? String ?? ""
                            let acceptedByAccount = request["acceptedByAccount"] as? String ?? ""
                            let needsMyApproval = (request["needsMyApproval"] as? Bool)
                                ?? ((request["needs_my_approval"] as? NSNumber)?.boolValue)
                                ?? (request["needs_my_approval"] as? Bool)
                                ?? false
                            let displayName = request["displayName"] as? String ?? (needsMyApproval ? acceptedByName : inviterName)
                            let displayPhone = request["displayPhone"] as? String ?? (needsMyApproval ? acceptedByPhone : inviterPhone)
                            let displayAccount = request["displayAccount"] as? String ?? (needsMyApproval ? acceptedByAccount : inviterAccount)
                            return FamilyPendingRequest(
                                id: id,
                                inviteCode: request["invite_code"] as? String ?? request["inviteCode"] as? String ?? "",
                                inviterId: request["inviter_id"] as? String ?? request["inviterId"] as? String ?? "",
                                inviterName: inviterName,
                                inviterPhone: inviterPhone,
                                inviterAccount: inviterAccount,
                                acceptedById: request["accepted_by"] as? String ?? request["acceptedById"] as? String ?? "",
                                acceptedByName: acceptedByName,
                                acceptedByPhone: acceptedByPhone,
                                acceptedByAccount: acceptedByAccount,
                                displayName: displayName,
                                displayPhone: displayPhone,
                                displayAccount: displayAccount,
                                relationType: request["relation_type"] as? String ?? request["relationType"] as? String ?? "family",
                                status: request["status"] as? String ?? "awaiting_owner",
                                needsMyApproval: needsMyApproval,
                                createdAt: createdAt
                            )
                        }
                    } else {
                        parsedRequests = []
                    }
                    if !samePendingRequestList(self.pendingFamilyRequests, parsedRequests) {
                        self.pendingFamilyRequests = parsedRequests
                    }

                    print("✅ 家人列表加载成功：\(familyList.count) 人")

                    // 家人列表更新后，按当前数据重排"家人超时未签到"本地推送
                    LifeCheckStatusManager.shared.scheduleFamilyOverdueNotifications(self.familyList)
                }
            } else if let familyResult = (result["data"] as? [String: Any])?["family"] as? [String: Any] {
                let message = familyResult["message"] as? String ?? L10n.string(.pleaseRetry)
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
                    inviteCode = ""
                    qrImage = nil
                    errorMessage = message
                    showingError = true
                }
            }
        } catch {
            print("❌ 生成邀请码失败：\(error)")
            print("❌ 错误详情：\(error.localizedDescription)")
            inviteCode = ""
            qrImage = nil
            errorMessage = error.localizedDescription
            showingError = true
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

    private func makeInvitePreview(from result: [String: Any]) -> FamilyInvitePreview? {
        guard let relationId = result["relationId"] as? String, !relationId.isEmpty else { return nil }

        return FamilyInvitePreview(
            id: relationId,
            inviteCode: result["inviteCode"] as? String ?? "",
            inviterId: result["inviterId"] as? String ?? "",
            inviterName: result["inviterName"] as? String ?? "",
            inviterPhone: result["inviterPhone"] as? String ?? "",
            inviterAccount: result["inviterAccount"] as? String ?? "",
            relationType: result["relationType"] as? String ?? "family",
            requiresConfirmation: result["requiresConfirmation"] as? Bool ?? false,
            status: result["status"] as? String ?? "pending"
        )
    }

    private func parseBackendDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if value == "0000-00-00 00:00:00" { return nil }
        if value.hasPrefix("0000-00-00") { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: value) {
            return date
        }
        // users.last_check_in_date 在库中多为 DATE 类型，接口常见仅日期：2026-04-27
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: value) {
            return date
        }

        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: value) { return d }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: value) { return d }

        return nil
    }

    /// 解析对方最后签到时间：兼容 String / 数字时间戳、以及下划线/大小写变体键名
    private func relatedUserCheckInDate(from member: [String: Any]) -> Date? {
        if let s = stringOrNilFromJSON(member["relatedUserLastCheckInDate"])
            ?? stringOrNilFromJSON(member["related_user_last_check_in_date"]) {
            return parseBackendDate(s)
        }
        if let d = member["relatedUserLastCheckInDate"] as? Double, d > 0 {
            if d > 1_000_000_000_000 { return Date(timeIntervalSince1970: d / 1000) }
            return Date(timeIntervalSince1970: d)
        }
        if let i = member["relatedUserLastCheckInDate"] as? Int, i > 0 {
            let d = TimeInterval(i)
            if d > 1_000_000_000_000 { return Date(timeIntervalSince1970: d / 1000) }
            return Date(timeIntervalSince1970: d)
        }
        if let n = member["relatedUserLastCheckInDate"] as? NSNumber, n.doubleValue > 0 {
            let d = n.doubleValue
            if d > 1_000_000_000_000 { return Date(timeIntervalSince1970: d / 1000) }
            return Date(timeIntervalSince1970: d)
        }
        return nil
    }

    private func stringOrNilFromJSON(_ value: Any?) -> String? {
        if let s = value as? String, !s.isEmpty { return s }
        return nil
    }

    /// 解析对方下次应签到的截止时间（Unix 秒级时间戳）
    private func relatedUserCheckInDeadline(from member: [String: Any]) -> Date? {
        let raw: Double? = {
            if let n = member["relatedUserCheckInExpireAt"] as? NSNumber { return n.doubleValue }
            if let i = member["relatedUserCheckInExpireAt"] as? Int { return Double(i) }
            if let d = member["relatedUserCheckInExpireAt"] as? Double { return d }
            if let s = member["relatedUserCheckInExpireAt"] as? String, let d = Double(s) { return d }
            return nil
        }()
        guard let value = raw, value > 0 else { return nil }
        return Date(timeIntervalSince1970: value > 1_000_000_000_000 ? value / 1000 : value)
    }

    /// 解析对方是否处于"家人守护"模式（兼容 Bool / Int / String）
    private func relatedUserIsFamilyMode(from member: [String: Any]) -> Bool {
        if let b = member["relatedUserIsFamilyMode"] as? Bool { return b }
        if let n = member["relatedUserIsFamilyMode"] as? NSNumber { return n.boolValue }
        if let i = member["relatedUserIsFamilyMode"] as? Int { return i != 0 }
        if let s = member["relatedUserIsFamilyMode"] as? String {
            let lower = s.lowercased()
            return lower == "true" || lower == "1" || lower == "yes"
        }
        return false
    }

    private func handleFamilyBindEntry(_ action: () -> Void) {
        if !MembershipManager.shared.canAddFamilyMember(currentCount: familyList.count) {
            showingUpgradeForFamily = true
            return
        }
        action()
    }

    private func startFamilyPolling() {
        // 已弃用：移除 30s 后台轮询，改为每次进入家人 tab / App 回前台时按需刷新一次。
        // 数据准确性由对方 App 在"安全倒计时重置"时主动上传保证；
        // 单条家人卡片的倒计时滚动由 TimelineView 每秒推进，不依赖网络刷新。
    }

    /// 比较两份家人列表是否一致（仅基于会影响 UI 的字段）
    private func sameFamilyList(_ a: [FamilyMember], _ b: [FamilyMember]) -> Bool {
        guard a.count == b.count else { return false }
        for (lhs, rhs) in zip(a, b) {
            if lhs.id != rhs.id { return false }
            if lhs.relationId != rhs.relationId { return false }
            if lhs.name != rhs.name { return false }
            if lhs.phone != rhs.phone { return false }
            if lhs.relationship != rhs.relationship { return false }
            if lhs.status != rhs.status { return false }
            if lhs.lastCheckInDate != rhs.lastCheckInDate { return false }
            if lhs.nextCheckInDeadline != rhs.nextCheckInDeadline { return false }
            if lhs.isFamilyMode != rhs.isFamilyMode { return false }
        }
        return true
    }

    private func samePendingRequestList(_ a: [FamilyPendingRequest], _ b: [FamilyPendingRequest]) -> Bool {
        guard a.count == b.count else { return false }
        for (lhs, rhs) in zip(a, b) {
            if lhs.id != rhs.id { return false }
            if lhs.status != rhs.status { return false }
            if lhs.needsMyApproval != rhs.needsMyApproval { return false }
            if lhs.displayName != rhs.displayName { return false }
        }
        return true
    }

    private func stopFamilyPolling() {
        familyRefreshTask?.cancel()
        familyRefreshTask = nil
    }
    
    // ✅ 扫码绑定邀请码
    @MainActor
    private func bindInviteCode(_ inviteCode: String) async {
        let currentCount = familyList.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            errorMessage = L10n.string(.familyLimitReached)
            showingError = true
            return
        }

        let token = KeychainManager.shared.getToken() ?? ""
        guard !token.isEmpty else {
            errorMessage = L10n.string(.noAccount)
            showingError = true
            return
        }

        guard !DataManager.apiURL.isEmpty else {
            errorMessage = L10n.string(.pleaseRetry)
            showingError = true
            return
        }

        do {
            let result = try await DataManager.shared.bindFamilyByInviteCode(inviteCode: inviteCode)
            print("📡 GraphQL 绑定家人响应：\(result)")

            let success = result["success"] as? Bool ?? false
            guard success else {
                errorMessage = result["message"] as? String ?? L10n.string(.bindFailed)
                showingError = true
                return
            }

            if let preview = makeInvitePreview(from: result), preview.requiresConfirmation {
                pendingInvitePreview = preview
                showingInviteConfirmation = true
                return
            }

            _ = try? await DataManager.shared.refreshFamilyMembers()
            await loadFamilyListAsync()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    @MainActor
    private func acceptPendingInvite() async {
        guard let preview = pendingInvitePreview else { return }

        do {
            let result = try await DataManager.shared.acceptFamilyInvite(relationId: preview.id)
            print("📡 家人关系确认响应：\(result)")

            let success = result["success"] as? Bool ?? false
            if success {
                _ = try? await DataManager.shared.refreshFamilyMembers()
                pendingInvitePreview = nil
                showingInviteConfirmation = false
                await loadFamilyListAsync()
            } else {
                errorMessage = result["message"] as? String ?? L10n.string(.bindFailed)
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    @MainActor
    private func finalizePendingFamilyRequest(_ request: FamilyPendingRequest) async {
        print("🔵 点击确认绑定待确认家人申请：relationId=\(request.id), inviter=\(request.inviterId), acceptedBy=\(request.acceptedById)")
        confirmingRequestId = request.id
        defer { confirmingRequestId = nil }

        do {
            let result = try await DataManager.shared.acceptFamilyInvite(relationId: request.id)
            print("📡 待确认家人请求确认响应：\(result)")

            let success = result["success"] as? Bool ?? false
            if success {
                print("✅ 待确认家人申请确认成功，刷新本地家人列表")
                _ = try? await DataManager.shared.refreshFamilyMembers()
                await loadFamilyListAsync()
            } else {
                errorMessage = result["message"] as? String ?? L10n.string(.bindFailed)
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
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
                    Text(L10n.string(.shareQRCodeTitle))
                        .font(.system(size: 22, weight: .bold))
                    
                    Text(L10n.string(.shareQRCodeSubtitle))
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
                            Text(L10n.string(.qrGenerating))
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
                        Text(L10n.string(.refreshQRCode))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "AF52DE"))
                }
                .disabled(isRefreshing)
                
                // 邀请码
                VStack(spacing: 8) {
                    Text(L10n.string(.inviteCode))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    if inviteCode.isEmpty {
                        Text(L10n.string(.qrFetching))
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
                    Text(L10n.string(.manualInviteHint))
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // 复制按钮
                Button(action: copyInviteCode) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(L10n.string(.copyInviteCode))
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
            .navigationTitle(L10n.string(.shareInviteCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.closeButton)) {
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

                    if member.isFamilyMode {
                        // 对方已开启"家人守护"模式，自身不再签到——不再显示倒计时
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text(L10n.string(.familyGuarding))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.green)
                    } else if let deadline = effectiveDeadline {
                        otherPartyCountdownBlock(deadline: deadline)
                    } else {
                        Text(L10n.string(.noRecordPrefix))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 状态
                if member.status == .pending {
                    Text(L10n.string(.pendingAcceptance))
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
        .confirmationDialog(L10n.string(.bindRelationTitle), isPresented: $showingDeleteConfirm) {
            Button(L10n.string(.removeRelation), role: .destructive) {
                deleteMember()
            }
            Button(L10n.string(.cancel), role: .cancel) {}
        } message: {
            Text(String(format: L10n.string(.bindRelationMessage), member.name))
        }
    }

    /// 仅使用对方账号自己的「下次签到截止时间」（来自服务端 checkin_expire_at），避免按本机/系统默认间隔误算
    private var effectiveDeadline: Date? {
        return member.nextCheckInDeadline
    }

    /// 倒计时块：仅显示 HH:MM:SS（每秒刷新）；超时后按 offlineTimeoutHours 决定颜色与文案
    @ViewBuilder
    private func otherPartyCountdownBlock(deadline: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let out = otherPartyCountdownText(deadline: deadline, now: context.date)
            Text(out.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(out.color)
                .monospacedDigit()
        }
    }

    private func otherPartyCountdownText(deadline: Date, now: Date) -> (text: String, color: Color) {
        let remainingSeconds = deadline.timeIntervalSince(now)
        if remainingSeconds > 0 {
            return (formatHMS(seconds: Int(remainingSeconds.rounded(.down))), .green)
        }
        let offlineHours = DataManager.shared.systemConfig.offlineTimeoutHours
        let overdueSeconds = -remainingSeconds
        if overdueSeconds <= offlineHours * 3600 {
            return (L10n.string(.checkingOverdue), .orange)
        }
        return (L10n.string(.checkingSevere), .red)
    }

    private func formatHMS(seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
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

// MARK: - 待确认家人卡片
struct FamilyPendingRequestCard: View {
    let request: FamilyPendingRequest
    let showsConfirmButton: Bool
    let isConfirming: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(request.needsMyApproval
                         ? L10n.text("等待我确认", en: "Waiting for my confirmation", ja: "私の確認待ち", ko: "내 확인 대기")
                         : L10n.text("等待对方确认", en: "Waiting for the other side", ja: "相手の確認待ち", ko: "상대방 확인 대기"))
                        .font(.system(size: 16, weight: .semibold))

                    Text(request.displayName.isEmpty ? request.inviterName : request.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(request.needsMyApproval
                     ? L10n.text("待确认", en: "Pending", ja: "確認待ち", ko: "확인 대기")
                     : L10n.text("已提交", en: "Submitted", ja: "申請済み", ko: "제출됨"))
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "F59E0B").opacity(0.12))
                    .foregroundColor(Color(hex: "F59E0B"))
                    .cornerRadius(6)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("对方账号", en: "Other account", ja: "相手アカウント", ko: "상대 계정"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(request.displayAccount.isEmpty ? request.inviteCode : request.displayAccount)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "6366F1"))
                }

                Spacer()
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("对方手机号", en: "Other phone", ja: "相手の電話番号", ko: "상대 전화번호"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(request.displayPhone.isEmpty ? "-" : request.displayPhone)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            Text(L10n.text(
                "申请会先进入待确认状态，等邀请人再次确认后才会正式建立关系。",
                en: "The request will first stay pending. The relationship becomes official only after the inviter confirms again.",
                ja: "申請はまず確認待ちになります。招待者が再確認してから正式な関係になります。",
                ko: "요청은 먼저 확인 대기 상태가 됩니다. 초대자가 다시 확인해야 정식 관계가 됩니다."
            ))
            .font(.system(size: 13))
            .foregroundColor(.secondary)

            if let createdAt = request.createdAt {
                Text(L10n.text("创建时间", en: "Created at", ja: "作成日時", ko: "생성 시각") + "：\(createdAt.chineseDateTimeString())")
                    .font(.system(size: 12))
            .foregroundColor(.secondary.opacity(0.8))
            }

            if showsConfirmButton {
                Button(action: onConfirm) {
                    HStack(spacing: 8) {
                        if isConfirming {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.85)
                            Text(L10n.text("确认中", en: "Confirming", ja: "確認中", ko: "확인 중"))
                        } else {
                            Text(L10n.text("确认绑定", en: "Confirm binding", ja: "連携を確定", ko: "연결 확인"))
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(isConfirming ? Color(hex: "8B95E9") : Color(hex: "6366F1"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isConfirming)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - 手动输入邀请码视图 (内联) - ✅ 修复 #6
struct ManualInputInviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isBinding = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingInviteConfirmation = false
    @State private var pendingInvitePreview: FamilyInvitePreview?
    
    var onBound: (() -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "textformat")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(L10n.string(.manualInviteTitle))
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(L10n.string(.manualInviteSubtitle))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(hex: "FFF9E6"))
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string(.inviteCode))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField(L10n.string(.inviteCodePlaceholder), text: $inviteCode)
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
                        Text(L10n.string(.binding))
                    } else {
                        Text(L10n.string(.bindNow)).font(.system(size: 16, weight: .semibold))
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
        .navigationTitle(L10n.string(.manualInvite))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.string(.cancel)) { onCancel?() }
            }
        }
        .alert(L10n.string(.bindFailed), isPresented: $showError) {
            Button(L10n.string(.confirm), role: .cancel) { }
        } message: { Text(errorMessage) }
        .confirmationDialog(
            L10n.text("确认家人绑定", en: "Confirm family binding", ja: "家族連携を確認", ko: "가족 연결 확인"),
            isPresented: $showingInviteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("提交申请", en: "Submit request", ja: "申請を送信", ko: "요청 제출")) {
                Task { await confirmPendingInvite() }
            }
            Button(L10n.string(.cancel), role: .cancel) {
                pendingInvitePreview = nil
            }
        } message: {
                if let preview = pendingInvitePreview {
                    Text(L10n.text(
                        "将与 \(preview.inviterName)（账号：\(preview.inviterAccount.isEmpty ? "未知" : preview.inviterAccount)）提交绑定申请，等待对方最终确认后才会正式生效。",
                        en: "You are about to submit a binding request with \(preview.inviterName) (account: \(preview.inviterAccount.isEmpty ? "unknown" : preview.inviterAccount)). The binding becomes official only after the other side confirms it.",
                        ja: "\(preview.inviterName)（アカウント：\(preview.inviterAccount.isEmpty ? "不明" : preview.inviterAccount)）へ連携申請を送信します。相手が最終確認してから正式に有効になります。",
                        ko: "\(preview.inviterName)(계정: \(preview.inviterAccount.isEmpty ? "알 수 없음" : preview.inviterAccount))에게 연결 요청을 제출합니다. 상대방이 최종 확인해야 정식으로 적용됩니다."
                    ))
                }
            }
    }
    
    private func bindInviteCode() {
        let currentCount = DataManager.shared.familyMembers.count
        if !MembershipManager.shared.canAddFamilyMember(currentCount: currentCount) {
            errorMessage = L10n.string(.familyLimitReached)
            showError = true
            return
        }
        
        guard inviteCode.count == 6 else { return }
        isBinding = true
        Task {
            do {
                let result = try await DataManager.shared.bindFamilyByInviteCode(inviteCode: inviteCode)
                if let success = result["success"] as? Bool, success {
                    if let preview = makeInvitePreview(from: result), preview.requiresConfirmation {
                        await MainActor.run {
                            pendingInvitePreview = preview
                            showingInviteConfirmation = true
                            isBinding = false
                        }
                        return
                    }

                    _ = try? await DataManager.shared.refreshFamilyMembers()
                    await MainActor.run { onBound?(); dismiss() }
                    return
                }
                throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: L10n.string(.bindFailed)])
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; showError = true }
            }
            await MainActor.run { isBinding = false }
        }
    }

    @MainActor
    private func confirmPendingInvite() async {
        guard let preview = pendingInvitePreview else { return }
        isBinding = true
        showingInviteConfirmation = false

        do {
            let result = try await DataManager.shared.acceptFamilyInvite(relationId: preview.id)
            if let success = result["success"] as? Bool, success {
                _ = try? await DataManager.shared.refreshFamilyMembers()
                await MainActor.run { onBound?(); dismiss() }
                return
            }
            errorMessage = result["message"] as? String ?? L10n.string(.bindFailed)
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isBinding = false
    }

    private func makeInvitePreview(from result: [String: Any]) -> FamilyInvitePreview? {
        guard let relationId = result["relationId"] as? String, !relationId.isEmpty else { return nil }

        return FamilyInvitePreview(
            id: relationId,
            inviteCode: result["inviteCode"] as? String ?? inviteCode,
            inviterId: result["inviterId"] as? String ?? "",
            inviterName: result["inviterName"] as? String ?? "",
            inviterPhone: result["inviterPhone"] as? String ?? "",
            inviterAccount: result["inviterAccount"] as? String ?? "",
            relationType: result["relationType"] as? String ?? "family",
            requiresConfirmation: result["requiresConfirmation"] as? Bool ?? false,
            status: result["status"] as? String ?? "pending"
        )
    }
}
