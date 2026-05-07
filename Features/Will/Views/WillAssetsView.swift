//
//  WillAssetsView.swift
//  安心助手
//
//  事项与资产 - 完整的增删改查 + 模板
//

import SwiftUI

struct WillAssetsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedTab = 0 // 0=重要事项，1=资产
    @State private var didInitialLoad = false
    @State private var showingAddAssetModal = false
    @State private var showingTemplateModal = false
    @State private var editingModule: WillModule? = nil
    @State private var editingAsset: Asset? = nil
    @State private var showingPDFExport = false
    @State private var showingUpgradeForExport = false  // 导出功能需要会员
    @State private var showingUpgradeForWill = false  // 新增事项数量需要会员限制
    @State private var showingMembershipView = false
    @State private var pdfExportSuccess = false
    @State private var templateContent = ""
    @State private var templateIsCompleted = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 分段控制器
                    segmentControl
                    
                    // 内容
                    if selectedTab == 0 {
                        willContent
                    } else {
                        assetsContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemBackground))
            .navigationTitle(L10n.string(.willAndAssets))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupNavigationBar()

                guard !didInitialLoad else { return }
                didInitialLoad = true

                dataManager.loadAllData()

                // 初始化默认模板（如果为空）
                if dataManager.willModules.isEmpty {
                    dataManager.initializeDefaultWillModules()
                }
                if dataManager.assets.isEmpty {
                    dataManager.initializeDefaultAssets()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "signature")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(L10n.string(.willAndAssets))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if MembershipManager.shared.canExportData() {
                            showingPDFExport = true
                        } else {
                            showingUpgradeForExport = true
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddAssetModal) {
                AddAssetModal(dataManager: dataManager, asset: nil)
            }
            .sheet(isPresented: $showingTemplateModal) {
                TemplateModal(dataManager: dataManager, content: $templateContent, isCompleted: $templateIsCompleted)
            }
            .sheet(item: $editingModule) { module in
                EditWillModuleModal(dataManager: dataManager, module: module)
            }
            .sheet(item: $editingAsset) { asset in
                AddAssetModal(dataManager: dataManager, asset: asset)
            }
            .sheet(isPresented: $showingPDFExport) {
                PDFExportSheet(isPresented: $showingPDFExport, modules: dataManager.willModules, assets: dataManager.assets, capsules: dataManager.capsules, onSuccess: {
                    pdfExportSuccess = true
                })
            }
            .sheet(isPresented: $showingUpgradeForExport) {
                    UpgradePromptView(
                    feature: L10n.text("导出 PDF", en: "Export PDF", ja: "PDFを書き出し", ko: "PDF 내보내기"),
                    statusText: L10n.text("当前功能仅会员可用", en: "This feature is for members only", ja: "この機能は会員限定です", ko: "이 기능은 멤버십 전용입니다"),
                    currentLimit: L10n.text("免费版无法导出", en: "Not available on free plan", ja: "無料プランでは書き出せません", ko: "무료 플랜에서는 내보낼 수 없습니다"),
                    targetLimit: L10n.text("会员版可导出", en: "Premium can export", ja: "会員プランでは書き出せます", ko: "멤버십에서는 내보낼 수 있습니다"),
                    onUpgrade: {
                        showingUpgradeForExport = false
                        showingMembershipView = true
                    },
                    onCancel: {
                        showingUpgradeForExport = false
                    }
                )
            }
            .sheet(isPresented: $showingUpgradeForWill) {
                    UpgradePromptView(
                    feature: L10n.text("新增事项", en: "Add note", ja: "項目を追加", ko: "항목 추가"),
                    statusText: L10n.text("当前仅可使用默认事项模板", en: "Only default note templates are available", ja: "既定のテンプレートのみ利用できます", ko: "기본 템플릿만 사용할 수 있습니다"),
                    currentLimit: L10n.text("免费版可使用 5 个默认模板", en: "Free plan includes 5 default templates", ja: "無料プランでは 5 つの既定テンプレートを利用できます", ko: "무료 플랜은 기본 템플릿 5개를 제공합니다"),
                    targetLimit: L10n.text("会员版可自定义事项且数量不限", en: "Premium can create unlimited custom notes", ja: "会員プランではカスタム項目を無制限に作成できます", ko: "멤버십에서는 사용자 지정 항목을 무제한으로 만들 수 있습니다"),
                    onUpgrade: {
                        showingUpgradeForWill = false
                        showingMembershipView = true
                    },
                    onCancel: {
                        showingUpgradeForWill = false
                    }
                )
            }
            .sheet(isPresented: $showingMembershipView) {
                NavigationView {
                    MembershipView()
                }
                .stackNavigationStyle()
            }
        }
        .stackNavigationStyle()
    }
    
    
    // MARK: - 分段控制器
    private var segmentControl: some View {
        HStack(spacing: 4) {
            Button(action: { selectedTab = 0 }) {
                Text(L10n.string(.myWills))
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 0 ? Color(hex: "6366F1") : Color.clear)
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .cornerRadius(8)
            }
            
            Button(action: { selectedTab = 1 }) {
                Text(L10n.string(.assetManagement))
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 1 ? Color(hex: "6366F1") : Color.clear)
                    .foregroundColor(selectedTab == 1 ? .white : .primary)
                    .cornerRadius(8)
            }
        }
        .padding(4)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 重要事项内容
    private var willContent: some View {
        VStack(spacing: 16) {
            // 进度卡片
            progressCard
            
            // 重要事项列表
            ForEach(dataManager.willModules) { module in
                WillModuleRow(module: module, onTap: {
                    editingModule = module
                }, onDelete: {
                    dataManager.deleteWillModule(module)
                })
            }
            
            // 新增事项按钮
            Button(action: {
                // 创建新的空白模块（使用 otherInstructions 类型）
                if !MembershipManager.shared.canCreateCustomWill() {
                    showingUpgradeForWill = true
                    return
                }
                    let newModule = WillModule(
                    id: UUID().uuidString,
                    type: .otherInstructions,
                    title: L10n.text("自定义事项", en: "Custom note", ja: "カスタム項目", ko: "사용자 항목"),
                    subtitle: L10n.text("添加您想记录的重要内容", en: "Add what you want to record", ja: "記録したい内容を追加してください", ko: "기록하고 싶은 내용을 추가하세요"),
                    content: "",
                    isCompleted: false
                )
                editingModule = newModule
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.string(.addCustomWill))
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "6366F1").opacity(0.1))
                .foregroundColor(Color(hex: "6366F1"))
                .cornerRadius(12)
            }
            
            // 说明提示
            infoCard(
                icon: "📝",
                title: L10n.text("重要事项说明", en: "Important note", ja: "重要事項の説明", ko: "중요 사항 안내"),
                desc: L10n.text("这里用于个人整理和信息参考，不构成法律意见或法律文书。内容不会自动发送，只有您主动发送后添加用户才可查看。", en: "This area is for personal organization and reference only. It is not legal advice or a legal document. Content is not sent automatically and is only visible after you manually send it.", ja: "ここは個人整理と参考用です。法的助言や法的文書ではありません。内容は自動送信されず、手動送信後のみ相手が確認できます。", ko: "개인 정리와 참고용입니다. 법률 자문이나 법적 문서가 아닙니다. 내용은 자동 전송되지 않으며 직접 전송한 후에만 상대가 볼 수 있습니다.")
            )
            
            // 操作按钮
            NavigationLink(destination: WillPreviewView()) {
                HStack {
                    Text("👁️")
                    Text(L10n.string(.previewWill))
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "6366F1"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
        }
        .padding(.bottom, 80)
    }
    
    // MARK: - 资产内容
    private var assetsContent: some View {
        VStack(spacing: 16) {
            // 安全提示
            infoCard(
                icon: "🔒",
                title: L10n.text("安全提示", en: "Safety note", ja: "安全上の注意", ko: "안전 안내"),
                desc: L10n.text("仅记录资产线索用于个人整理和信息参考，不存储密码和完整账号。建议记录账号后 4 位以便识别。", en: "Only asset references are stored for personal organization and reference. Passwords and full account numbers are not stored. We recommend recording the last 4 digits of an account for identification.", ja: "個人整理と参考として資産情報のみを保存し、パスワードや完全なアカウント番号は保存しません。識別のために末尾4桁の記録を推奨します。", ko: "개인 정리와 참고용으로 자산 정보만 기록하며, 비밀번호와 전체 계정 번호는 저장하지 않습니다. 식별을 위해 마지막 4자리를 기록하는 것을 권장합니다.")
            )
            
            // 资产列表
            ForEach(dataManager.assets) { asset in
                AssetRow(asset: asset, onDelete: {
                    dataManager.deleteAsset(asset)
                }, onEdit: {
                    editingAsset = asset
                })
            }
            .onDelete { atOffsets in
                dataManager.deleteAssets(at: atOffsets)
            }
            
            // 添加资产按钮
            Button(action: { showingAddAssetModal = true }) {
                HStack {
                    Text("+")
                    Text(L10n.string(.addAsset))
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "6366F1"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string(.fillingProgress))
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(L10n.string(.progressHint))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(dataManager.getWillProgress() * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "6366F1"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * dataManager.getWillProgress(), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(L10n.string(.completedItems).replacingOccurrences(of: "%@", with: "\(dataManager.willModules.filter { $0.isCompleted }.count)"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(L10n.string(.totalItems).replacingOccurrences(of: "%@", with: "\(dataManager.willModules.count)"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }
    
    // MARK: - 信息卡片
    private func infoCard(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "6366F1").opacity(0.08))
        .cornerRadius(12)
    }
}

    // MARK: - 重要事项模块卡片
struct WillModuleCard: View {
    let module: WillModule
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Text(module.type.icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color(hex: module.type.color).opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(module.subtitle.isEmpty ? module.type.subtitle : module.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if module.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "34C759"))
                    .font(.system(size: 22))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 资产卡片
struct AssetCard: View {
    let asset: Asset
    
    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack(spacing: 12) {
                Text(asset.type.icon)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: asset.type.color).opacity(0.12))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(asset.institution)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("¥\(formatBalance(asset.balance))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "6366F1"))
            }
            
            Divider()
            
            // 详情
            ForEach(Array(asset.details.keys), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.details[key] ?? "")
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

// MARK: - 资产行（支持编辑和删除）
struct AssetRow: View {
    let asset: Asset
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack(spacing: 12) {
                Text(asset.type.icon)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: asset.type.color).opacity(0.12))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(asset.institution)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("¥\(formatBalance(asset.balance))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "6366F1"))
                
                // 编辑按钮
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(hex: "6366F1"))
                        .font(.system(size: 16))
                }
                .padding(.leading, 8)
                
                // 删除按钮
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                .padding(.leading, 4)
            }
            
            Divider()
            
            // 详情
            ForEach(Array(asset.details.keys), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.details[key] ?? "")
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .alert(L10n.string(.deleteAsset), isPresented: $showingDeleteAlert) {
            Button(L10n.string(.cancel), role: .cancel) {}
            Button(L10n.string(.deleteAction), role: .destructive) {
                onDelete()
            }
        } message: {
            Text(String(format: L10n.string(.deleteAssetMessage), asset.name))
        }
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

    // MARK: - 重要事项模块行（支持删除）
struct WillModuleRow: View {
    let module: WillModule
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 14) {
            Text(module.type.icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color(hex: module.type.color).opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(module.subtitle.isEmpty ? module.type.subtitle : module.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if module.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "34C759"))
                    .font(.system(size: 22))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            // 删除按钮
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .padding(.leading, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .onTapGesture(perform: onTap)
        .alert(L10n.string(.deleteWill), isPresented: $showingDeleteAlert) {
            Button(L10n.string(.cancel), role: .cancel) {}
            Button(L10n.string(.deleteAction), role: .destructive) {
                onDelete()
            }
        } message: {
            Text(String(format: L10n.string(.deleteWillMessage), module.title))
        }
    }
}

#Preview {
    WillAssetsView()
}

// MARK: - 导航栏样式设置
extension WillAssetsView {
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

//
//  WillModuleEdit.swift
//  安心助手
//
    //  重要事项模块编辑 + 模板
//

import SwiftUI

    // MARK: - 编辑重要事项弹窗
