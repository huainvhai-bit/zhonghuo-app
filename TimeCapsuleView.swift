//
//  TimeCapsuleView.swift
//  终活
//
//  时光胶囊 - 完整的增删改查
//

import SwiftUI

struct TimeCapsuleView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedFilter: TimeCapsule.CapsuleType? = nil
    @State private var showingAddModal = false
    @State private var editingCapsule: TimeCapsule? = nil
    
    var filteredCapsules: [TimeCapsule] {
        dataManager.getFilteredCapsules(type: selectedFilter)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 云同步状态
                    syncStatusCard
                    
                    // 统计卡片
                    statsCard
                    
                    // 类型筛选
                    filterButtons
                    
                    // 胶囊列表
                    capsuleList
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("时光胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddModal = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingAddModal) {
                AddCapsuleModal(dataManager: dataManager)
            }
            .sheet(item: $editingCapsule) { capsule in
                EditCapsuleModal(dataManager: dataManager, capsule: capsule)
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
                
                Text("所有胶囊已安全备份到云端")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "34C759"))
        }
        .padding(14)
        .background(Color(hex: "34C759").opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        HStack(spacing: 8) {
            FilterChip(text: "全部 \(dataManager.capsules.count)", isActive: selectedFilter == nil) {
                selectedFilter = nil
            }
            
            FilterChip(text: "待发送 \(dataManager.capsules.filter { !$0.isSent }.count)", isActive: false) {}
            
            FilterChip(text: "已发送 \(dataManager.capsules.filter { $0.isSent }.count)", isActive: false) {}
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - 筛选按钮
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(text: "全部", isActive: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                FilterButton(text: "文字", isActive: selectedFilter == .text) {
                    selectedFilter = .text
                }
                
                FilterButton(text: "语音", isActive: selectedFilter == .audio) {
                    selectedFilter = .audio
                }
                
                FilterButton(text: "视频", isActive: selectedFilter == .video) {
                    selectedFilter = .video
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 胶囊列表
    private var capsuleList: some View {
        VStack(spacing: 12) {
            ForEach(filteredCapsules) { capsule in
                CapsuleCard(capsule: capsule, onEdit: {
                    editingCapsule = capsule
                }, onDelete: {
                    dataManager.deleteCapsule(id: capsule.id)
                })
            }
        }
        .padding(.bottom, 100)
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let text: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color(hex: "AF52DE") : Color.white)
                .foregroundColor(isActive ? .white : .primary)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isActive ? Color.clear : Color(hex: "E5E5EA"), lineWidth: 1)
                )
        }
    }
}

// MARK: - 筛选 Chip
struct FilterChip: View {
    let text: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isActive ? Color(hex: "AF52DE").opacity(0.12) : Color.clear)
                .foregroundColor(isActive ? Color(hex: "AF52DE") : .primary)
                .cornerRadius(6)
        }
    }
}

// MARK: - 胶囊卡片
struct CapsuleCard: View {
    let capsule: TimeCapsule
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 15) {
            // 图标
            Text(capsule.type.icon)
                .font(.system(size: 22))
                .frame(width: 50, height: 50)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .cornerRadius(12)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(formatSendDate(capsule.sendDate))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 标签
            Text(capsule.type.rawValue)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .cornerRadius(6)
            
            // 删除按钮
            Button(action: { showingDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onEdit()
        }
        .alert("删除胶囊", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive, action: onDelete)
        } message: {
            Text("确定要删除\"\(capsule.title)\"吗？此操作无法撤销。")
        }
    }
    
    private func formatSendDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = capsule.isSent ? "yyyy 年 M 月 d 日已发送" : "yyyy 年 M 月 d 日发送"
        return formatter.string(from: date)
    }
}

// MARK: - 添加胶囊弹窗
struct AddCapsuleModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: TimeCapsule.CapsuleType = .text
    @State private var sendDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("类型")) {
                    Picker("类型", selection: $selectedType) {
                        Text("✉️ 文字").tag(TimeCapsule.CapsuleType.text)
                        Text("🎙️ 语音").tag(TimeCapsule.CapsuleType.audio)
                        Text("🎥 视频").tag(TimeCapsule.CapsuleType.video)
                    }
                }
                
                Section(header: Text("内容")) {
                    TextField("标题", text: $title)
                    
                    if selectedType == .text {
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: selectedType == .audio ? "mic.fill" : "video.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("点击录制\(selectedType == .audio ? "语音" : "视频")")
                                .foregroundColor(.secondary)
                            
                            Button("开始录制") {
                                // TODO: 实现录制功能
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                
                Section(header: Text("发送时间")) {
                    DatePicker("发送日期", selection: $sendDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("新建时光胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        dataManager.addCapsule(title: title, content: content, type: selectedType, sendDate: sendDate)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 编辑胶囊弹窗
struct EditCapsuleModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let capsule: TimeCapsule
    @State private var title: String
    @State private var content: String
    @State private var sendDate: Date
    
    init(dataManager: DataManager, capsule: TimeCapsule) {
        self.dataManager = dataManager
        self.capsule = capsule
        _title = State(initialValue: capsule.title)
        _content = State(initialValue: capsule.content)
        _sendDate = State(initialValue: capsule.sendDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("内容")) {
                    TextField("标题", text: $title)
                    
                    if capsule.type == .text {
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                    } else {
                        Text("当前内容：\(content.isEmpty ? "无" : content)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("发送时间")) {
                    DatePicker("发送日期", selection: $sendDate, in: Date()..., displayedComponents: .date)
                }
            }
            .navigationTitle("编辑胶囊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updated = capsule
                        updated.title = title
                        updated.content = content
                        updated.sendDate = sendDate
                        dataManager.updateCapsule(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimeCapsuleView()
}
