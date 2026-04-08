//
//  Family/FamilyGuardView.swift
//  终活
//
//  家人守护视图
//

import SwiftUI

struct FamilyGuardView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddMember = false
    @State private var showingFilter = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.familyMembers) { member in
                    NavigationLink {
                        FamilyMemberDetailView(member: member)
                    } label: {
                        FamilyMemberRow(member: member)
                    }
                }
                .onDelete(perform: deleteMembers)
            }
            .navigationTitle("家人守护")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilter = true }) {
                        Image(systemName: "filter")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                BindFamilyView()
            }
            .sheet(isPresented: $showingFilter) {
                Text("Filter view")
            }
        }
    }
    
    private func deleteMembers(offsets: IndexSet) {
        // TODO: 实现删除逻辑
    }
}

// MARK: - 家庭成员行
struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack {
            Text(member.name)
                .font(.body)
            Spacer()
            Text(member.relation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FamilyGuardView()
}
