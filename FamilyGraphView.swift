//
//  FamilyGraphView.swift
//  终活
//
//  亲属关系图谱（V1.1.0 P1 重要）
//  功能：可视化家人关系展示
//

import SwiftUI

struct FamilyGraphView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    @State private var selectedPerson: User?
    @State private var showDetail = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // 标题
                Text("亲属关系图谱")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                // 关系图谱
                FamilyGraph(dataManager: dataManager)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(hex: "F6F6F8"))
        .navigationTitle("家人守护")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showDetail = true }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            FamilyGraphLegend()
        }
    }
}

// MARK: - 关系图谱核心

struct FamilyGraph: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        VStack(spacing: 30) {
            // 核心节点：用户自己
            FamilyNodeView(user: dataManager.currentUser, isSelf: true)
            
            // 关联节点
            HStack(spacing: 40) {
                // 配偶
                if let spouse = dataManager.familyMembers.first(where: { $0.relationType == .spouse })?.relatedUser {
                    FamilyNodeView(user: spouse, relation: .spouse)
                }
                
                // 直系亲属（父母、子女）
                ForEach(filteredFamilyMembers(.parent)) { member in
                    FamilyNodeView(user: member, relation: .parent)
                }
                
                ForEach(filteredFamilyMembers(.child)) { member in
                    FamilyNodeView(user: member, relation: .child)
                }
            }
            
            // 旁系亲属（兄弟姐妹、祖父母等）
            VStack(spacing: 20) {
                ForEach(filteredFamilyMembers(.sibling)) { member in
                    FamilyNodeView(user: member, relation: .sibling)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    /// 过滤家庭成员
    private func filteredFamilyMembers(_ relation: User.FamilyRelation) -> [User] {
        return dataManager.familyMembers
            .filter { $0.relationType == relation }
            .compactMap { $0.relatedUser }
    }
}

// MARK: - 家人节点视图

struct FamilyNodeView: View {
    let user: User?
    let isSelf: Bool = false
    let relation: User.FamilyRelation?
    
    @State private var showDetail = false
    
    var body: some View {
        if let user = user {
            VStack(spacing: 8) {
                // 头像
                Circle()
                    .fill(user.avatarColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: isSelf ? "person.fill" : relation?.icon ?? "person")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .onTapGesture {
                        showDetail = true
                    }
                
                // 名称
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                // 关系标签
                if let relation = relation, !isSelf {
                    Text(relation.label)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        } else {
            // 占位符（没有该类型家人）
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                )
                .overlay(
                    Text("无")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .offset(y: 28)
                )
        }
    }
}

// MARK: - 关系类型扩展

extension User.FamilyRelation {
    /// 关系图标
    var icon: String {
        switch self {
        case .spouse:
            return "heart.fill"
        case .parent:
            return "person.2.fill"
        case .child:
            return "person.fill.bubble.left"
        case .sibling:
            return "person.2.fill.back"
        case .grandparent:
            return "person.wave.2.fill"
        case .grandchild:
            return "person.fill.bubble.right"
        case .uncle:
            return "person.fill.badge.plus"
        case .aunt:
            return "person.fill.badge.minus"
        case .cousin:
            return "person.fill.badge.clock"
        default:
            return "person.fill"
        }
    }
    
    /// 关系标签
    var label: String {
        switch self {
        case .spouse:
            return "配偶"
        case .parent:
            return "父母"
        case .child:
            return "子女"
        case .sibling:
            return "兄弟姐妹"
        case .grandparent:
            return "祖父母"
        case .grandchild:
            return "孙辈"
        case .uncle:
            return "叔伯"
        case .aunt:
            return "姑姨"
        case .cousin:
            return "堂表"
        default:
            return "亲属"
        }
    }
}

// MARK: - 关系图例

struct FamilyGraphLegend: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("关系图例")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, 10)
                
                LegendItem(icon: "heart.fill", label: "配偶")
                LegendItem(icon: "person.2.fill", label: "父母")
                LegendItem(icon: "person.fill.bubble.left", label: "子女")
                LegendItem(icon: "person.2.fill.back", label: "兄弟姐妹")
                LegendItem(icon: "person.fill.badge.plus", label: "叔伯/姑姨")
                LegendItem(icon: "person.fill.badge.clock", label: "堂表兄弟姐妹")
                LegendItem(icon: "person.wave.2.fill", label: "祖父母")
                LegendItem(icon: "person.fill.bubble.right", label: "孙辈")
                
                Divider()
                
                Text("💡 提示")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("• 点击节点可查看详情")
                    .font(.system(size: 13))
                Text("• 拖拽可调整布局（未来版本）")
                    .font(.system(size: 13))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("关闭")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "AF52DE"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color.white)
            .navigationTitle("关系图例")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LegendItem: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "AF52DE"))
            Text(label)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(hex: "F6F6F8"))
        .cornerRadius(8)
    }
}

// MARK: - 预览

struct FamilyGraphView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyGraphView()
    }
}
