//
//  CloudStorageStatusView.swift
//  终活
//
//  云存储状态显示组件
//

import SwiftUI

/// 云存储状态指示器（小图标）
struct CloudStorageIndicatorView: View {
    let status: TimeCapsule.CloudBackupStatus
    let url: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(status.icon)
                .font(.system(size: 12))
            
            if status == .backedUp && !url.isEmpty {
                Text("已备份")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: status.color))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(hex: status.color).opacity(0.1))
        .cornerRadius(4)
    }
}

/// 云存储详情弹窗
struct CloudStorageDetailView: View {
    let status: TimeCapsule.CloudBackupStatus
    let url: String
    let backupAt: Date?
    let onRetry: () -> Void
    let onViewCloud: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("云存储详情")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            // 状态
            VStack(spacing: 12) {
                Text(status.icon)
                    .font(.system(size: 48))
                
                Text(status.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: status.color))
                
                if let backupAt = backupAt {
                    Text("备份时间：\(backupAt.formatted())")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: status.color).opacity(0.1))
            .cornerRadius(12)
            
            // URL
            if !url.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("云存储地址")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(url)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                if status == .failed {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("重试")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                if !url.isEmpty && status == .backedUp {
                    Button(action: onViewCloud) {
                        HStack {
                            Image(systemName: "cloud.fill")
                            Text("查看云端")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "007AFF"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
    }
}

/// 云存储状态按钮（显示在胶囊/遗嘱列表项中）
struct CloudStorageButton: View {
    let status: TimeCapsule.CloudBackupStatus
    let url: String
    let backupAt: Date?
    let onRetry: () -> Void
    let onViewCloud: () -> Void
    
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            CloudStorageIndicatorView(status: status, url: url)
        }
        .sheet(isPresented: $showingDetail) {
            CloudStorageDetailView(
                status: status,
                url: url,
                backupAt: backupAt,
                onRetry: onRetry,
                onViewCloud: onViewCloud
            )
        }
    }
}

// MARK: - 预览

struct CloudStorageStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CloudStorageIndicatorView(
                status: .pending,
                url: ""
            )
            
            CloudStorageIndicatorView(
                status: .uploading,
                url: ""
            )
            
            CloudStorageIndicatorView(
                status: .backedUp,
                url: "https://example.com/file.txt"
            )
            
            CloudStorageIndicatorView(
                status: .failed,
                url: ""
            )
        }
        .padding()
    }
}
