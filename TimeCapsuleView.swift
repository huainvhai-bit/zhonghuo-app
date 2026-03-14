//
//  TimeCapsuleView.swift
//  终活 - 时光胶囊
//

import SwiftUI

struct TimeCapsuleView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddCapsule = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.timeCapsules) { capsule in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(capsule.title)
                                .font(.headline)
                            Spacer()
                            if capsule.isLocked {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Text(capsule.content)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                        
                        Text("开启日期：\(capsule.openDate, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.primaryPurple)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("时光胶囊")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCapsule = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCapsule) {
                AddCapsuleView()
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct AddCapsuleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 100)
                }
                
                Section(header: Text("开启时间")) {
                    DatePicker("开启日期", selection: .constant(Date()), displayedComponents: .date)
                }
            }
            .navigationTitle("新建胶囊")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TimeCapsuleView()
}
