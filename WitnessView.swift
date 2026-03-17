//
//  WitnessView.swift
//  终活
//
//  见证人管理页面
//

import SwiftUI

struct WitnessView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddModal = false
    @State private var selectedWitness: Witness?
    @State private var showingEditModal = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 进度卡片
            progressCard
            
            // 见证人列表
            if dataManager.witnesses.isEmpty {
                emptyState
            } else {
                witnessList
            }
        }
        .background(Color(hex: "F6F6F8"))
        .navigationTitle("见证人")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("见证人")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(Color(hex: "AF52DE"))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddModal = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "AF52DE"))
                }
            }
        }
        .sheet(isPresented: $showingAddModal) {
            AddWitnessModal(isPresented: $showingAddModal)
        }
        .sheet(isPresented: $showingEditModal) {
            if let witness = selectedWitness {
                EditWitnessModal(isPresented: $showingEditModal, witness: witness)
            }
        }
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                    Text("见证人进度")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(dataManager.witnesses.count) 人")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FF9500"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "FF9500").opacity(0.7), Color(hex: "FF9500")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * dataManager.getWitnessProgress(), height: 8)
                        .shadow(color: Color(hex: "FF9500").opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            .frame(height: 8)
            
            HStack {
                Label("\(dataManager.witnesses.filter { $0.isConfirmed }.count) 已确认", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "34C759"))
                
                Spacer()
                
                Label("\(dataManager.witnesses.count) 总计", systemImage: "person.2")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF9500").opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "FF9500"))
            }
            
            VStack(spacing: 8) {
                Text("暂无见证人")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("添加见证人来增强遗嘱的法律效力")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddModal = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("添加见证人")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(hex: "FF9500"))
                .cornerRadius(12)
                .shadow(color: Color(hex: "FF9500").opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            // 提示信息
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "FF9500"))
                    Text("为什么需要见证人？")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("见证人可以证明遗嘱的真实性和有效性，在法律纠纷中提供重要证据。建议选择 2 名以上无利害关系的成年人作为见证人。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(Color(hex: "FF9500").opacity(0.06))
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .padding(.top, 80)
    }
    
    // MARK: - 见证人列表
    private var witnessList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dataManager.witnesses) { witness in
                    WitnessCard(witness: witness, onEdit: {
                        selectedWitness = witness
                        showingEditModal = true
                    }, onDelete: {
                        deleteWitness(witness)
                    })
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
    
    private func deleteWitness(_ witness: Witness) {
        dataManager.deleteWitness(witness)
    }
}

// MARK: - 见证人卡片
struct WitnessCard: View {
    let witness: Witness
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(witness.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label(witness.role, systemImage: "person.crop.rectangle")
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        statusBadge
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "AF52DE"))
                    }
                    
                    Button(action: { showingDeleteConfirm = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "FF3B30"))
                    }
                }
            }
            
            // 联系信息
            VStack(spacing: 8) {
                if !witness.phone.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(witness.phone)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                if !witness.idNumber.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "card.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(maskIDNumber(witness.idNumber))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 备注
            if !witness.notes.isEmpty {
                Text(witness.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(12)
                    .background(Color(hex: "F2F2F7"))
                    .cornerRadius(10)
            }
            
            // 时间信息
            HStack(spacing: 12) {
                Label(formatDate(witness.createdAt), systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                if witness.isConfirmed {
                    Label(formatDate(witness.confirmedAt ?? Date()), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "34C759"))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .confirmationDialog("删除见证人", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除见证人\"\(witness.name)\"吗？此操作不可恢复。")
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(witness.isConfirmed ? Color(hex: "34C759") : Color(hex: "FF9500"))
                .frame(width: 6, height: 6)
            
            Text(witness.isConfirmed ? "已确认" : "待确认")
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(witness.isConfirmed ? Color(hex: "34C759").opacity(0.12) : Color(hex: "FF9500").opacity(0.12))
        .foregroundColor(witness.isConfirmed ? Color(hex: "34C759") : Color(hex: "FF9500"))
        .cornerRadius(8)
    }
    
    private func maskIDNumber(_ idNumber: String) -> String {
        guard idNumber.count >= 8 else { return idNumber }
        let start = idNumber.prefix(6)
        let end = idNumber.suffix(2)
        return "\(start)****\(end)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 添加见证人弹窗
struct AddWitnessModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = DataManager.shared
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var phone = ""
    @State private var idNumber = ""
    @State private var notes = ""
    @State private var isConfirmed = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("姓名 *", text: $name)
                    TextField("与立遗嘱人关系 *", text: $relationship)
                        .textContentType(.namePrefix)
                }
                
                Section(header: Text("联系信息")) {
                    TextField("电话号码", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    TextField("身份证号", text: $idNumber)
                        .textContentType(.fullStreetAddress)
                }
                
                Section(header: Text("备注")) {
                    TextField("备注信息（可选）", text: $notes)
                        .lineLimit(6)
                }
                
                Section(header: Text("确认状态")) {
                    Toggle("已确认见证意愿", isOn: $isConfirmed)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "007AFF"))
                            Text("提示")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        
                        Text("建议见证人确认后再标记为已确认状态。见证人应该是无利害关系的成年人。")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("添加见证人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveWitness()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
    
    private func saveWitness() {
        let witness = Witness(
            id: UUID().uuidString,
            name: name,
            role: relationship,
            phone: phone,
            isConfirmed: isConfirmed,
            order: 0
        )
        
        dataManager.addWitness(witness)
        isPresented = false
    }
}

// MARK: - 编辑见证人弹窗
struct EditWitnessModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = DataManager.shared
    @Binding var isPresented: Bool
    let witness: Witness
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var phone = ""
    @State private var idNumber = ""
    @State private var notes = ""
    @State private var isConfirmed = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("姓名 *", text: $name)
                    TextField("与立遗嘱人关系 *", text: $relationship)
                }
                
                Section(header: Text("联系信息")) {
                    TextField("电话号码", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("身份证号", text: $idNumber)
                }
                
                Section(header: Text("备注")) {
                    TextField("备注信息（可选）", text: $notes)
                        .lineLimit(6)
                }
                
                Section(header: Text("确认状态")) {
                    Toggle("已确认见证意愿", isOn: $isConfirmed)
                }
            }
            .navigationTitle("编辑见证人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateWitness()
                    }
                    .disabled(name.isEmpty || relationship.isEmpty)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .onAppear {
            name = witness.name
            relationship = witness.relationship
            phone = witness.phone
            idNumber = witness.idNumber
            notes = witness.notes
            isConfirmed = witness.isConfirmed
        }
    }
    
    private func updateWitness() {
        var updatedWitness = witness
        updatedWitness.name = name
        updatedWitness.relationship = relationship
        updatedWitness.phone = phone
        updatedWitness.idNumber = idNumber
        updatedWitness.notes = notes
        updatedWitness.isConfirmed = isConfirmed
        updatedWitness.confirmedAt = isConfirmed ? (witness.confirmedAt ?? Date()) : nil
        
        dataManager.updateWitness(updatedWitness)
        isPresented = false
    }
}

#Preview {
    WitnessView()
}
