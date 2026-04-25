//
//  Capsule/CapsuleList.swift
//  终活
//
//  时光胶囊列表
//  职责：胶囊展示 + 筛选 + 空状态
//

import SwiftUI
import UIKit
import Foundation

struct CapsuleList: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CapsuleListViewModel()
    @State private var selectedFilter: TimeCapsule.CapsuleType? = nil
    @State private var showingAddCapsule = false  // ✅ 新增：控制新增胶囊弹窗
    @State private var showingUpgradePrompt = false  // ✅ 升级提示
    @State private var showingMembershipView = false  // ✅ 会员页面
    @State private var selectedCapsuleForShare: TimeCapsule? = nil  // 待分享的胶囊
    @State private var showingUpgradeForShare = false  // ✅ 分享功能需要会员
    @State private var selectedCapsuleForEdit: TimeCapsule? = nil  // 待编辑的胶囊
    @State private var capsuleToDelete: TimeCapsule? = nil  // 待删除的胶囊
    @State private var showingDeleteAlert = false  // ✅ 删除确认弹窗
    @State private var selectedCapsuleForDetail: TimeCapsule? = nil  // 待查看详情的胶囊
    
    var filteredCapsules: [TimeCapsule] {
        dataManager.getFilteredCapsules(type: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // ✅ 背景色全屏覆盖（与首页一致）
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 统计卡片
                        statsCard
                        
                        // 类型筛选
                        filterButtons
                        
                        // 胶囊列表
                        if filteredCapsules.isEmpty {
                            emptyState
                        } else {
                            capsuleList
                            
                            // ✅ 底部新增按钮（仅列表有内容时显示）
                            Button(action: {
                                // ✅ 检查胶囊数量限制
                                let membership = MembershipManager.shared
                                if !membership.canCreateCapsule(currentCount: dataManager.capsules.count) {
                                    showingUpgradePrompt = true
                                    return
                                }
                                showingAddCapsule = true
                            }) {
                                HStack {
                                    Text("+")
                                    Text(L10n.text("添加胶囊", en: "Add Capsule", ja: "カプセルを追加", ko: "캡슐 추가"))
                                        .accessibilityLabel(L10n.text("添加新的时光胶囊", en: "Add a new time capsule", ja: "新しいタイムカプセルを追加", ko: "새 타임 캡슐 추가"))
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "6366F1"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.bottom, 32)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle(L10n.text("时光胶囊", en: "Time Capsule", ja: "タイムカプセル", ko: "타임 캡슐"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(L10n.text("时光胶囊", en: "Time Capsule", ja: "タイムカプセル", ko: "타임 캡슐"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .stackNavigationStyle()
        .sheet(isPresented: $showingAddCapsule) {
            NavigationView {
                CapsuleEditView(dataManager: dataManager)  // ✅ 新增模式
            }
            .stackNavigationStyle()
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                CapsuleLimitPromptView(
                    currentCount: dataManager.capsules.count,
                    maxCount: MembershipManager.shared.maxCapsules,
                    onUpgrade: {
                        showingUpgradePrompt = false
                        showingMembershipView = true
                    },
                    onCancel: {
                        showingUpgradePrompt = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingMembershipView) {
            NavigationView {
                MembershipView()
            }
            .stackNavigationStyle()
        }
        .sheet(isPresented: $showingUpgradeForShare) {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "6366F1"))
                        
                        Text(L10n.text("胶囊分享是会员功能", en: "Capsule sharing is a premium feature", ja: "カプセル共有は会員機能です", ko: "캡슐 공유는 멤버십 기능입니다"))
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(L10n.text("升级到会员版，即可将时光胶囊分享给家人，让他们及时收到您的祝福", en: "Upgrade to premium to share capsules with your family and let them receive your message in time.", ja: "会員プランにアップグレードすると、タイムカプセルを家族と共有でき、タイムリーにメッセージを届けられます。", ko: "멤버십으로 업그레이드하면 타임 캡슐을 가족과 공유해 제때 메시지를 전달할 수 있습니다."))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showingUpgradeForShare = false
                            showingMembershipView = true
                        }) {
                            Text(L10n.text("升级会员", en: "Upgrade", ja: "アップグレード", ko: "업그레이드"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "6366F1"))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingUpgradeForShare = false
                        }) {
                            Text(L10n.string(.later))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
        .sheet(item: $selectedCapsuleForShare, onDismiss: {
            selectedCapsuleForShare = nil
        }) { capsule in
            ShareCapsuleSheet(
                capsule: capsule,
                familyMembers: dataManager.familyMembers,
                onAddFamily: {
                    selectedCapsuleForShare = nil
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SwitchToTab"),
                        object: nil,
                        userInfo: ["tab": 3]
                    )
                },
                onShare: { [self] selectedMembers in
                    let receiverIds = selectedMembers.map { $0.relatedUserId }
                    Task {
                        do {
                            let result = try await self.dataManager.shareCapsule(capsuleId: capsule.id, receiverIds: receiverIds)
                            print("✅ 胶囊分享成功：\(result)")
                            await MainActor.run {
                                self.selectedCapsuleForShare = nil
                            }
                        } catch {
                            let errorMsg = error.localizedDescription
                            print("❌ 胶囊分享失败：\(errorMsg)")
                            if errorMsg.contains("会员") || errorMsg.contains("premium") {
                                await MainActor.run {
                                    self.selectedCapsuleForShare = nil
                                    self.showingUpgradeForShare = true
                                }
                            }
                        }
                    }
                },
                onCancel: {
                    selectedCapsuleForShare = nil
                }
            )
        }
        .sheet(item: $selectedCapsuleForEdit, onDismiss: {
            selectedCapsuleForEdit = nil
        }) { capsule in
            NavigationView {
                CapsuleEditView(dataManager: dataManager, existingCapsule: capsule)
            }
            .stackNavigationStyle()
        }
        .sheet(item: $selectedCapsuleForDetail, onDismiss: {
            selectedCapsuleForDetail = nil
        }) { capsule in
            NavigationView {
                CapsuleDetailView(dataManager: dataManager, capsule: capsule)
            }
            .stackNavigationStyle()
        }
        .alert(L10n.string(.deleteCapsule), isPresented: $showingDeleteAlert) {
            Button(L10n.string(.cancel), role: .cancel) {
                capsuleToDelete = nil
            }
            Button(L10n.string(.deleteAction), role: .destructive) {
                if let capsule = capsuleToDelete {
                    dataManager.capsules.removeAll { $0.id == capsule.id }
                    dataManager.saveCapsulesToFile()
                }
                capsuleToDelete = nil
            }
        } message: {
            Text(L10n.text("确定要删除这个胶囊吗？此操作不可撤销。", en: "Delete this capsule? This cannot be undone.", ja: "このカプセルを削除しますか？この操作は元に戻せません。", ko: "이 캡슐을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."))
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            setupNavigationBar()
            viewModel.onAppear()
        }
    }
    
    // 设置紫色导航栏背景（与首页一致）
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
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 20))
                    Text(L10n.text("时光胶囊", en: "Time Capsule", ja: "タイムカプセル", ko: "타임 캡슐"))
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(.white)
                    
                    Text(L10n.text("记录美好，留给未来的自己", en: "Capture memories for your future self", ja: "素敵な思い出を、未来の自分へ", ko: "미래의 자신에게 남길 아름다운 기억"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                // 胶囊数量
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dataManager.capsules.count)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text(L10n.text("个胶囊", en: "capsules", ja: "個のカプセル", ko: "개의 캡슐"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            
            // 统计信息
            HStack(spacing: 0) {
                StatBox(value: "\(dataManager.capsules.count)", label: "全部", icon: "square.grid.2x2", bgColor: .white.opacity(0.2))
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 30)
                
                StatBox(value: "\(dataManager.capsules.filter { !$0.isSent }.count)", label: "待发送", icon: "clock.fill", bgColor: .white.opacity(0.2))
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 30)
                
                StatBox(value: "\(dataManager.capsules.filter { $0.isSent }.count)", label: "已发送", icon: "checkmark.circle.fill", bgColor: .white.opacity(0.2))
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.25), radius: 10, x: 0, y: 4)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部按钮
                FilterButton(title: "全部", icon: "square.grid.2x2", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                // 文字胶囊
                FilterButton(title: "文字", icon: "doc.text", isSelected: selectedFilter == .text) {
                    selectedFilter = .text
                }
                
                // 语音胶囊
                FilterButton(title: "语音", icon: "mic", isSelected: selectedFilter == .audio) {
                    selectedFilter = .audio
                }
                
                // 视频胶囊
                FilterButton(title: "视频", icon: "video", isSelected: selectedFilter == .video) {
                    selectedFilter = .video
                }
            }
        }
    }
    
    private var capsuleList: some View {
        VStack(spacing: 12) {
            ForEach(filteredCapsules) { capsule in
                SwipeableCapsuleCard(
                    capsule: capsule,
                    onEdit: {
                        selectedCapsuleForEdit = capsule
                    },
                    onDelete: {
                        showingDeleteAlert = true
                        capsuleToDelete = capsule
                    },
                    onSend: {
                        if !MembershipManager.shared.canShareCapsule() {
                            showingUpgradeForShare = true
                            return
                        }
                        selectedCapsuleForShare = capsule
                    },
                    onTap: {
                        selectedCapsuleForDetail = capsule
                    }
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "capsule")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "6366F1").opacity(0.5))
            
            Text(LocalizedStringKey("还没有时光胶囊"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey("点击右上角 ➕ 创建第一个胶囊"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            NavigationLink(destination: CapsuleEditView(dataManager: dataManager)) {
                Text(L10n.text("创建胶囊", en: "Create capsule", ja: "カプセルを作成", ko: "캡슐 만들기"))
                    .accessibilityLabel(L10n.text("创建新的时光胶囊", en: "Create a new time capsule", ja: "新しいタイムカプセルを作成", ko: "새 타임 캡슐 만들기"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
    }
    
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "6366F1"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? Color(hex: "6366F1").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - 胶囊卡片（✅ 优化：增强视觉效果）
struct CapsuleCard: View {
    let capsule: TimeCapsule
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // 类型图标 - 圆形渐变
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: iconForType(capsule.type))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // 中间内容
            VStack(alignment: .leading, spacing: 6) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // 类型标签
                    Text(capsule.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "6366F1").opacity(0.1))
                        .cornerRadius(6)
                    
                    // 状态标签
                    HStack(spacing: 4) {
                        Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                            .font(.system(size: 10))
                        Text(capsule.isSent ? "已发送" : "待发送")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(capsule.isSent ? .green : .orange)
                }
                
                // 发送日期
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 发送按钮
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(10)
            }
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.06), radius: 10, x: 0, y: 3)
    }
    
    private func iconForType(_ type: TimeCapsule.CapsuleType) -> String {
        switch type {
        case .text: return "doc.text.fill"
        case .audio, .voice: return "mic.fill"
        case .video, .image, .sticker: return "video.fill"
        @unknown default: return "capsule.fill"
        }
    }
    
    private func formatSendDate(_ date: Date) -> String {
        "\(date.chineseDateString()) 发送"
    }
}

// MARK: - 统计项
struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let bgColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 分享胶囊弹窗
struct ShareCapsuleSheet: View {
    let capsule: TimeCapsule
    let familyMembers: [FamilyInfo]
    let onAddFamily: () -> Void
    let onShare: ([FamilyInfo]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedMembers: Set<String> = []  // 选中的家人 ID
    @State private var isAllSelected = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 胶囊信息
                HStack(spacing: 12) {
                    Image(systemName: capsule.type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: "6366F1"))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(capsule.title)
                            .font(.system(size: 16, weight: .semibold))
                        Text(L10n.text("选择要发送的家人", en: "Choose family members to send to", ja: "送信する家族を選択", ko: "보낼 가족을 선택하세요"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 全选按钮
                Button(action: {
                    isAllSelected.toggle()
                    if isAllSelected {
                        selectedMembers = Set(familyMembers.map { $0.relatedUserId })
                    } else {
                        selectedMembers.removeAll()
                    }
                }) {
                    HStack {
                        Image(systemName: isAllSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(isAllSelected ? Color(hex: "6366F1") : .secondary)
                        Text(L10n.text("全选", en: "Select all", ja: "すべて選択", ko: "전체 선택"))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(L10n.text("\(selectedMembers.count)/\(familyMembers.count) 人已选", en: "\(selectedMembers.count)/\(familyMembers.count) selected", ja: "\(selectedMembers.count)/\(familyMembers.count) 人選択済み", ko: "\(selectedMembers.count)/\(familyMembers.count)명 선택됨"))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // 家人列表
                if familyMembers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(L10n.text("暂无已绑定的家人", en: "No family bound yet", ja: "まだ家族が連携されていません", ko: "아직 연결된 가족이 없습니다"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(L10n.text("请先在「家人守护」中添加家人", en: "Please add family members in Family", ja: "まず「家族」から家族を追加してください", ko: "먼저 가족 보호에서 가족을 추가하세요"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: onAddFamily) {
                            Text(L10n.text("去添加家人", en: "Add family", ja: "家族を追加", ko: "가족 추가"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "6366F1"))
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(familyMembers) { member in
                                FamilyShareRow(
                                    member: member,
                                    isSelected: selectedMembers.contains(member.relatedUserId),
                                    onToggle: {
                                        if selectedMembers.contains(member.relatedUserId) {
                                            selectedMembers.remove(member.relatedUserId)
                                        } else {
                                            selectedMembers.insert(member.relatedUserId)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                // 底部按钮
                VStack(spacing: 12) {
                    Button(action: {
                        let selected = familyMembers.filter { selectedMembers.contains($0.relatedUserId) }
                        onShare(selected)
                    }) {
                        Text(L10n.text("发送给家人", en: "Send to family", ja: "家族に送信", ko: "가족에게 보내기"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedMembers.isEmpty ? Color.gray : Color(hex: "6366F1"))
                            .cornerRadius(12)
                    }
                    .disabled(selectedMembers.isEmpty)
                    
                    Button(action: onCancel) {
                        Text(L10n.string(.cancel))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle(L10n.text("分享胶囊", en: "Share Capsule", ja: "カプセルを共有", ko: "캡슐 공유"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.cancel)) {
                        onCancel()
                    }
                }
            }
        }
        .stackNavigationStyle()
    }
}

// MARK: - 家人分享行
struct FamilyShareRow: View {
    let member: FamilyInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "6366F1") : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.relatedUserName ?? "家人")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text(member.relationType)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let phone = member.relatedUserPhone, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 胶囊行
struct CapsuleRow: View {
    let capsule: TimeCapsule
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: capsule.type.icon)
                        .foregroundColor(.secondary)
                    Text(capsule.title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if !capsule.isSent {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                        }
                        
                        if capsule.isSent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Text(capsule.content)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(capsule.type.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "6366F1").opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatSendDate(_ date: Date) -> String {
        "\(date.chineseDateString()) \(capsule.isSent ? "已发送" : "发送")"
    }
}


// MARK: - 可滑动的胶囊卡片
struct SwipeableCapsuleCard: View {
    let capsule: TimeCapsule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSend: () -> Void
    let onTap: () -> Void  // 点击打开详情
    
    @State private var offset: CGFloat = 0
    @State private var isShowingActions = false
    @State private var dragStartY: CGFloat = 0  // 记录拖拽开始的Y位置
    
    // 是否向左滑出显示了操作按钮
    private var isSwipedLeft: Bool {
        offset < -50
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 背景操作按钮 - 始终在卡片下方
            HStack(spacing: 0) {
                // 左侧：删除按钮
                Button(action: {
                    // 关闭滑动菜单
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        isShowingActions = false
                    }
                    // 延迟执行删除，让动画先完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 80)
                        .opacity(isShowingActions ? 1 : 0)  // 仅在显示操作按钮时可见
                }
                .frame(width: 60)
                .allowsHitTesting(isShowingActions)  // 仅在显示时响应点击
                
                Spacer()
                
                // 右侧：编辑按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        isShowingActions = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onEdit()
                    }
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 80)
                        .opacity(isShowingActions ? 1 : 0)
                }
                .frame(width: 60)
                .allowsHitTesting(isShowingActions)
            }
            .background(Color.red)
            .cornerRadius(16)
            
            // 主卡片 - 使用独立offset避免被按钮遮挡
            cardContent
                .offset(x: offset)
        }
    }
    
    // 卡片内容（提取出来方便复用）
    private var cardContent: some View {
        HStack(spacing: 14) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: iconForType(capsule.type))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // 中间内容
            VStack(alignment: .leading, spacing: 6) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(capsule.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "6366F1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "6366F1").opacity(0.1))
                        .cornerRadius(6)
                    
                    HStack(spacing: 4) {
                        Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                            .font(.system(size: 10))
                        Text(capsule.isSent ? "已发送" : "待发送")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(capsule.isSent ? .green : .orange)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 发送按钮
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "6366F1"))
                    .cornerRadius(10)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(hex: "6366F1").opacity(0.06), radius: 10, x: 0, y: 3)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    // 如果已经显示操作按钮，只处理关闭手势
                    if isShowingActions {
                        if value.translation.width > 40 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                                isShowingActions = false
                            }
                        }
                        return
                    }
                    
                    // 只处理纯水平拖拽（不干扰垂直滚动）
                    let translation = value.translation
                    
                    // 如果水平移动距离大于垂直距离，才认为是水平滑动
                    if abs(translation.width) > abs(translation.height) {
                        if translation.width < 0 {
                            // 向左滑：显示删除和编辑按钮
                            offset = max(translation.width, -120)
                        } else {
                            // 向右滑：限制在60以内
                            offset = min(translation.width, 60)
                        }
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if value.translation.width < -80 {
                            // 向左滑显示编辑和删除按钮
                            offset = -100
                            isShowingActions = true
                        } else {
                            // 其他情况恢复原位
                            offset = 0
                            isShowingActions = false
                        }
                    }
                }
        )
        .onTapGesture {
            if isShowingActions {
                // 关闭滑动菜单
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isShowingActions = false
                }
            } else {
                // 打开详情
                onTap()
            }
        }
    }
    
    private func iconForType(_ type: TimeCapsule.CapsuleType) -> String {
        switch type {
        case .text: return "doc.text.fill"
        case .audio, .voice: return "mic.fill"
        case .video, .image, .sticker: return "video.fill"
        @unknown default: return "capsule.fill"
        }
    }
    
    private func formatSendDate(_ date: Date) -> String {
        "\(date.chineseDateString()) \(capsule.isSent ? "已发送" : "发送")"
    }
}

#Preview {
    NavigationView {
        CapsuleList(dataManager: DataManager.shared)
    }
    .stackNavigationStyle()
}
