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
                    // 统计卡片
                    statsCard
                    
                    // 类型筛选
                    filterButtons
                    
                    // 胶囊列表
                    if filteredCapsules.isEmpty {
                        emptyState
                    } else {
                        capsuleList
                    }
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
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        HStack(spacing: 12) {
            StatItem(icon: "capsule.fill", value: "\(dataManager.capsules.count)", label: "全部", color: Color(hex: "AF52DE"))
            StatItem(icon: "clock.fill", value: "\(dataManager.capsules.filter { !$0.isSent }.count)", label: "待发送", color: Color(hex: "FF9500"))
            StatItem(icon: "checkmark.circle.fill", value: "\(dataManager.capsules.filter { $0.isSent }.count)", label: "已发送", color: Color(hex: "34C759"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - 筛选按钮
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(text: "全部", systemImage: "square.grid.2x2", isActive: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                FilterButton(text: "文字", systemImage: "doc.text.fill", isActive: selectedFilter == .text) {
                    selectedFilter = .text
                }
                
                FilterButton(text: "语音", systemImage: "mic.fill", isActive: selectedFilter == .audio) {
                    selectedFilter = .audio
                }
                
                FilterButton(text: "视频", systemImage: "video.fill", isActive: selectedFilter == .video) {
                    selectedFilter = .video
                }
            }
            .padding(.horizontal, 4)
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
        .padding(.bottom, 20)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "capsule.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("暂无时光胶囊")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击右上角 + 创建您的第一个胶囊")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddModal = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("创建胶囊")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "AF52DE"))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - 统计项
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let text: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(text)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Color(hex: "AF52DE") : Color.white)
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.clear : Color(hex: "E5E5EA"), lineWidth: 1)
            )
            .shadow(color: isActive ? Color(hex: "AF52DE").opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
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
        HStack(spacing: 16) {
            // 图标
            Image(systemName: capsule.type.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 52, height: 52)
                .background(Color(hex: capsule.type.color).opacity(0.12))
                .foregroundColor(Color(hex: capsule.type.color))
                .cornerRadius(14)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(capsule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: capsule.isSent ? "checkmark.circle.fill" : "clock.fill")
                        .font(.system(size: 10))
                    Text(formatSendDate(capsule.sendDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: { showingDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
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
        formatter.dateFormat = capsule.isSent ? "yyyy/MM/dd 已发送" : "yyyy/MM/dd 发送"
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
                        Label("文字", systemImage: "doc.text.fill").tag(TimeCapsule.CapsuleType.text)
                        Label("语音", systemImage: "mic.fill").tag(TimeCapsule.CapsuleType.audio)
                        Label("视频", systemImage: "video.fill").tag(TimeCapsule.CapsuleType.video)
                    }
                    .pickerStyle(.segmented)
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
                            .tint(Color(hex: "AF52DE"))
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
