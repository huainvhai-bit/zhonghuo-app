//
//  WillAssetsView.swift
//  终活
//
//  嘱托与资产 - 完整的增删改查 + 模板
//

import SwiftUI

struct WillAssetsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedTab = 0 // 0=遗嘱，1=资产
    @State private var didInitialLoad = false
    @State private var showingAddAssetModal = false
    @State private var showingTemplateModal = false
    @State private var editingModule: WillModule? = nil
    @State private var editingAsset: Asset? = nil
    @State private var showingPDFExport = false
    @State private var showingUpgradeForExport = false  // 导出功能需要会员
    @State private var showingUpgradeForWill = false  // 新增嘱托数量需要会员限制
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
            .navigationTitle("嘱托与资产")
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
                        Text("嘱托与资产")
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
                    feature: "导出 PDF",
                    statusText: "当前功能仅会员可用",
                    currentLimit: "免费版无法导出",
                    targetLimit: "会员版可导出",
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
                    feature: "新增嘱托",
                    statusText: "当前嘱托模块数量已达上限",
                    currentLimit: "当前最多 \(MembershipManager.shared.currentWillLimit()) 个模块",
                    targetLimit: "会员版可创建更多嘱托模块",
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
            }
        }
    }
    
    
    // MARK: - 分段控制器
    private var segmentControl: some View {
        HStack(spacing: 4) {
            Button(action: { selectedTab = 0 }) {
                Text("我的嘱托")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 0 ? Color(hex: "6366F1") : Color.clear)
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .cornerRadius(8)
            }
            
            Button(action: { selectedTab = 1 }) {
                Text("资产管理")
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
    
    // MARK: - 遗嘱内容
    private var willContent: some View {
        VStack(spacing: 16) {
            // 进度卡片
            progressCard
            
            // 遗嘱模块列表
            ForEach(dataManager.willModules) { module in
                WillModuleRow(module: module, onTap: {
                    editingModule = module
                }, onDelete: {
                    dataManager.deleteWillModule(module)
                })
            }
            
            // 新增嘱托按钮
            Button(action: {
                // 创建新的空白模块（使用 otherInstructions 类型）
                let currentCount = dataManager.willModules.count
                if !MembershipManager.shared.canCreateWill(currentCount: currentCount) {
                    showingUpgradeForWill = true
                    return
                }
                let newModule = WillModule(
                    id: UUID().uuidString,
                    type: .otherInstructions,
                    title: "自定义嘱托",
                    subtitle: "添加您想交代的事",
                    content: "",
                    isCompleted: false
                )
                editingModule = newModule
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新增自定义嘱托")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "6366F1").opacity(0.1))
                .foregroundColor(Color(hex: "6366F1"))
                .cornerRadius(12)
            }
            
            // 法律提示
            infoCard(
                icon: "⚖️",
                title: "关于遗嘱的法律说明",
                desc: "本遗嘱为自书遗嘱，需亲笔签名并注明日期才具法律效力。建议有 2 名以上见证人在场，或前往公证处办理公证。"
            )
            
            // 操作按钮
            NavigationLink(destination: WillPreviewView()) {
                HStack {
                    Text("👁️")
                    Text("预览嘱托")
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
                title: "安全提示",
                desc: "仅记录资产信息用于身后事务处理，不存储密码和完整账号。建议记录账号后 4 位以便识别。"
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
                    Text("添加资产")
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
                    Text("填写进度")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("完成度越高，您的意愿就越清晰")
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
                Text("已完成 \(dataManager.willModules.filter { $0.isCompleted }.count) 项")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("共 \(dataManager.willModules.count) 项")
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

// MARK: - 遗嘱模块卡片
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
        .alert("删除资产", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除资产「\(asset.name)」吗？此操作不可恢复。")
        }
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

// MARK: - 遗嘱模块行（支持删除）
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
        .alert("删除嘱托", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除嘱托「\(module.title)」吗？此操作不可恢复。")
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
//  终活
//
//  遗嘱模块编辑 + 模板
//

import SwiftUI

// MARK: - 编辑遗嘱模块弹窗
