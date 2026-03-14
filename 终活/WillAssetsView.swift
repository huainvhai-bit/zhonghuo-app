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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 云同步状态
                    syncStatusCard
                    
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
            .sheet(isPresented: $showingAddAssetModal) {
                AddAssetModal(dataManager: dataManager)
            }
            .sheet(isPresented: $showingTemplateModal) {
                TemplateModal(dataManager: dataManager)
            }
            .sheet(item: $editingModule) { module in
                EditWillModuleModal(dataManager: dataManager, module: module)
            }
        }
    }
    
    // MARK: - 云同步状态
    private var syncStatusCard: some View {
        HStack(spacing: 12) {
            Text("☁️")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("云端已同步")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "34C759"))
                
                Text("上次同步：刚刚 · 所有数据已安全备份")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("详情") {
                // TODO: 显示同步详情
            }
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(14)
        .background(Color(hex: "34C759").opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - 分段控制器
    private var segmentControl: some View {
        HStack(spacing: 4) {
            Button(action: { selectedTab = 0 }) {
                Text("我的嘱托")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 0 ? Color(hex: "AF52DE") : Color.clear)
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .cornerRadius(8)
            }
            
            Button(action: { selectedTab = 1 }) {
                Text("资产管理")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 1 ? Color(hex: "AF52DE") : Color.clear)
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
            
            // 使用模板按钮
            Button(action: { showingTemplateModal = true }) {
                HStack {
                    Text("📋")
                    Text("使用预设模板")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(Color(hex: "AF52DE"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "AF52DE"), lineWidth: 1)
                )
            }
            
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
            Button(action: {
                // TODO: 预览遗嘱
            }) {
                HStack {
                    Text("👁️")
                    Text("预览遗嘱")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "AF52DE"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                // TODO: 导出 PDF
            }) {
                HStack {
                    Text("📤")
                    Text("导出 PDF")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(Color(hex: "AF52DE"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "AF52DE"), lineWidth: 1)
                )
            }
        }
        .padding(.bottom, 100)
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
                .background(Color(hex: "AF52DE"))
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
                    .foregroundColor(Color(hex: "AF52DE"))
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
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
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
        .background(Color(hex: "AF52DE").opacity(0.08))
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
                    .foregroundColor(Color(hex: "AF52DE"))
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
