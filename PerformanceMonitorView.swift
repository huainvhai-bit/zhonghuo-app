//
//  PerformanceMonitorView.swift
//  终活 - 性能监控页面
//

import SwiftUI

struct PerformanceMonitorView: View {
    @ObservedObject var deviceMonitor = DeviceMonitor.shared
    @State private var performanceHistory: [PerformanceRecord] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            // 实时性能卡片
            Section(header: Text("实时性能")) {
                // CPU 使用率
                PerformanceRow(
                    icon: "cpu",
                    title: "CPU 使用率",
                    value: "\(deviceMonitor.cpuUsage, specifier: "%.1f")%",
                    color: colorForUsage(deviceMonitor.cpuUsage)
                )
                
                // 内存使用
                PerformanceRow(
                    icon: "memorychip",
                    title: "内存使用",
                    value: "\(deviceMonitor.memoryUsage) MB",
                    color: colorForUsage(Double(deviceMonitor.memoryUsage) / 100.0)
                )
                
                // 电池温度
                PerformanceRow(
                    icon: "thermometer",
                    title: "电池温度",
                    value: "\(deviceMonitor.batteryTemperature, specifier: "%.1f")°C",
                    color: .orange
                )
                
                // 网络信号
                PerformanceRow(
                    icon: "wifi",
                    title: "网络信号",
                    value: deviceMonitor.networkSignal,
                    color: .green
                )
            }
            
            // 设备信息
            Section(header: Text("设备信息")) {
                Label("设备型号", systemImage: "iphone")
                    .foregroundColor(.primary)
                Text(UIDevice.current.model)
                    .foregroundColor(.secondary)
                
                Label("系统版本", systemImage: "info.circle")
                    .foregroundColor(.primary)
                Text("\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                    .foregroundColor(.secondary)
                
                Label("可用存储", systemImage: "externaldrive")
                    .foregroundColor(.primary)
                Text("\(deviceMonitor.availableStorage) GB")
                    .foregroundColor(.secondary)
            }
            
            // 性能历史
            Section(header: Text("性能历史")) {
                if performanceHistory.isEmpty {
                    Text("暂无历史记录")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(performanceHistory) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.timestamp, formatter: timeFormatter)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("CPU: \(record.cpuUsage, specifier: "%.1f")%")
                                    .font(.system(size: 13))
                                Spacer()
                                Text("内存：\(record.memoryUsage) MB")
                                    .font(.system(size: 13))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // 操作按钮
            Section {
                Button(action: refreshPerformance) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                        Text("刷新数据")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Button(action: exportReport) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                        Text("导出报告")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("性能监控")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            deviceMonitor.startPerformanceMonitoring()
            loadPerformanceHistory()
        }
        .onDisappear {
            deviceMonitor.stopPerformanceMonitoring()
        }
    }
    
    // MARK: - Methods
    
    private func refreshPerformance() {
        deviceMonitor.updateCPUUsage()
        deviceMonitor.updateMemoryUsage()
        deviceMonitor.updateStorageInfo()
        
        // 添加到历史记录
        let record = PerformanceRecord(
            timestamp: Date(),
            cpuUsage: deviceMonitor.cpuUsage,
            memoryUsage: deviceMonitor.memoryUsage
        )
        performanceHistory.insert(record, at: 0)
        
        // 保持最近 20 条记录
        if performanceHistory.count > 20 {
            performanceHistory.removeLast()
        }
    }
    
    private func loadPerformanceHistory() {
        // 从本地加载历史记录（示例）
        // TODO: 从服务器加载
    }
    
    private func exportReport() {
        // TODO: 导出性能报告
        print("📊 导出性能报告")
    }
    
    private func colorForUsage(_ usage: Double) -> Color {
        if usage < 0.5 {
            return .green
        } else if usage < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Models

struct PerformanceRecord: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Int
}

// MARK: - Subviews

struct PerformanceRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PerformanceMonitorView()
    }
}
