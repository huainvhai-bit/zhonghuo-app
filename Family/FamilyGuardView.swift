//
//  Family/FamilyGuardView.swift
//  终活
//
//  家人守护视图
//

import SwiftUI

struct FamilyGuardView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingAddMember = false
    
    var body: some View {
        NavigationView {
            List {
                Section("家人列表") {
                    Text("家人功能开发中...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("家人守护")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                BindFamilyView(onBound: nil)
            }
        }
    }
}

#Preview {
    FamilyGuardView()
}