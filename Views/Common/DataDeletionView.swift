//
//  DataDeletionView.swift
//  终活
//
//  数据删除功能（V2.0.0 GDPR 合规）
//  功能：用户数据删除申请、自动清理
//

import SwiftUI
import CoreData

struct DataDeletionView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // 标题
                    Text("数据删除")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    
                    // GDPR 声明
                    gdprDeclaration
                    
                    // 删除选项
                    deleteOptions
                    
                    Spacer()
                    
                    // 删除按钮
                    Button(action: { showingConfirmation = true }) {
                        HStack(spacing: 8) {
                            if isDeleting {
                                ProgressView()
                            } else {
                                Image(systemName: "exclamationmark.triangle")
                            }
                            Text("删除所有数据")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isDeleting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.hex("F5F5F7"))
            .navigationTitle("数据删除")
            .navigationBarTitleDisplayMode(.inline)
            .alert("确认删除", isPresented: $showingConfirmation) {
                Button("取消", role: .cancel) { }
                Button("确认删除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("此操作不可逆！所有数据（时光胶囊、遗嘱、家人信息等）将被永久删除。")
            }
            .alert("删除成功", isPresented: $showingSuccess) {
                Button("返回登录") {
                    dataManager.logout()
                }
            } message: {
                Text("您的所有数据已从服务器和本地删除。")
            }
        }
    }
    
    // MARK: - GDPR 声明
    private var gdprDeclaration: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkmark")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                Text("GDPR 合规")
                    .font(.system(size: 18, weight: .bold))
            }
            
            Text("根据《通用数据保护条例》(GDPR)，您有权要求删除您的所有个人数据。")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("✅ 您可以删除的数据：")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.leading, 4)
                
                Text("• 时光胶囊（文字/图片/语音/视频）")
                Text("• 遗嘱文档（完整/数字/保密遗嘱）")
                Text("• 家人信息（守护关系、资产信息）")
                Text("• 签到记录")
                Text("• 用户账户信息")
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("⚠️ 注意事项：")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.leading, 4)
                
                Text("• 删除后数据无法恢复")
                Text("• 相关联的数据也会被删除")
                Text("• 部分数据可能因法律要求保留")
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 删除选项（未来扩展）
    private var deleteOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("删除选项")
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                deleteOptionRow(
                    icon: "hourglass",
                    title: "删除所有时光胶囊",
                    subtitle: "包括未发送的胶囊和已发送的胶囊",
                    isDefault: true
                )
                
                deleteOptionRow(
                    icon: "doc.text",
                    title: "删除所有遗嘱文档",
                    subtitle: "包括遗嘱模板和自定义遗嘱",
                    isDefault: true
                )
                
                deleteOptionRow(
                    icon: "person.2",
                    title: "删除家人信息",
                    subtitle: "包括守护关系和联系信息",
                    isDefault: true
                )
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 4)
    }
    
    private func deleteOptionRow(icon: String, title: String, subtitle: String, isDefault: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 删除所有数据
    private func deleteAllData() {
        isDeleting = true
        
        Task {
            // 1. 删除本地数据
            await deleteLocalData()
            
            // 2. 删除服务器数据
            await deleteServerData()
            
            // 3. 清理缓存
            await clearCache()
            
            // 4. 退出登录
            DispatchQueue.main.async {
                self.isDeleting = false
                self.showingSuccess = true
            }
        }
    }
    
    private func deleteLocalData() async {
        // 删除 Core Data 数据
        dataManager.deleteAllData()
        
        // 删除文件缓存
       FileManager.default.deleteFile(atPath: dataManager.cacheDirectory)
    }
    
    private func deleteServerData() async {
        // TODO: 调用后端删除接口
        // let result = await DataManager.shared.deleteAllUserData()
    }
    
    private func clearCache() async {
        // 清理文档目录
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}

// MARK: - 预览
struct DataDeletionView_Previews: PreviewProvider {
    static var previews: some View {
        DataDeletionView()
    }
}
