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
    @State private var showingAddAssetModal = false
    @State private var showingTemplateModal = false
    @State private var editingModule: WillModule? = nil
    @State private var showingPDFExport = false
    @State private var pdfExportSuccess = false
    
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
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("嘱托与资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("嘱托与资产")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPDFExport = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddAssetModal) {
                AddAssetModal(dataManager: dataManager)
            }
            .sheet(isPresented: $showingTemplateModal) {
                TemplateModal(dataManager: dataManager)
            }
            .sheet(item: $editingModule) { module in
                EditWillModuleModal(dataManager: dataManager, module: module)
            }
            .sheet(isPresented: $showingPDFExport) {
                PDFExportSheet(isPresented: $showingPDFExport, modules: dataManager.willModules, witnesses: dataManager.witnesses, assets: dataManager.assets, onSuccess: {
                    pdfExportSuccess = true
                })
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
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - 遗嘱内容
    private var willContent: some View {
        VStack(spacing: 16) {
            // 进度卡片
            progressCard
            
            // 遗嘱模块列表
            ForEach(dataManager.willModules) { module in
                WillModuleCard(module: module, onTap: {
                    editingModule = module
                })
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
                    Text("预览遗嘱")
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
                AssetCard(asset: asset)
            }
            
            // 添加资产按钮
            Button(action: { showingAddAssetModal = true }) {
                HStack {
                    Text("+")
                    Text("添加金融资产")
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
        .background(Color.white)
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
        .background(Color.white)
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
        .background(Color.white)
        .cornerRadius(14)
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

#Preview {
    WillAssetsView()
}
//
//  WillModuleEdit.swift
//  终活
//
//  遗嘱模块编辑 + 模板
//

import SwiftUI

// MARK: - 编辑遗嘱模块弹窗
