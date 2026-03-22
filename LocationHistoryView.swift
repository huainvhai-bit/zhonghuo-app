//
//  LocationHistoryView.swift
//  终活 - 用户位置历史轨迹
//

import SwiftUI
import MapKit

struct LocationHistoryView: View {
    @ObservedObject var userManager = UserManager.shared
    @State private var locationHistory: [LocationRecord] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var selectedLocation: LocationRecord?
    @State private var showingMap = false
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if locationHistory.isEmpty {
                emptyView
            } else {
                locationListView
            }
        }
        .navigationTitle("位置历史")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await loadLocationHistory()
            }
        }
        .refreshable {
            await loadLocationHistory()
        }
        .sheet(isPresented: $showingMap) {
            if let location = selectedLocation {
                LocationMapView(location: location)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无位置记录")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("开启定位服务后，位置记录将显示在这里")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    // MARK: - Location List View
    
    private var locationListView: some View {
        List {
            Section(header: Text("最近位置")) {
                ForEach(locationHistory) { location in
                    LocationRow(location: location)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLocation = location
                            showingMap = true
                        }
                }
            }
            
            Section(footer: Text("位置记录仅保留最近 30 天")) {
                Button(action: clearHistory) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("清除历史记录")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadLocationHistory() async {
        isLoading = true
        
        guard let token = UserDefaults.standard.string(forKey: "userToken"), !token.isEmpty else {
            errorMessage = "请先登录"
            showingError = true
            isLoading = false
            return
        }
        
        guard !DataManager.apiURL.isEmpty else {
            errorMessage = "API 未配置"
            showingError = true
            isLoading = false
            return
        }
        
        do {
            // 调用后端 API 获取位置历史
            let urlString = "\(DataManager.apiURL)/api/location.php?action=list&token=\(token)"
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "Invalid URL", code: -1)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "HTTP Error", code: -1)
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let dataArray = json["data"] as? [[String: Any]] {
                
                var records: [LocationRecord] = []
                let formatter = ISO8601DateFormatter()
                
                for item in dataArray {
                    guard let id = item["id"] as? String,
                          let latitude = item["latitude"] as? Double,
                          let longitude = item["longitude"] as? Double,
                          let createdAtStr = item["created_at"] as? String,
                          let createdAt = formatter.date(from: createdAtStr) else {
                        continue
                    }
                    
                    let address = item["address"] as? String ?? ""
                    let accuracy = item["accuracy"] as? Double ?? 0
                    
                    let record = LocationRecord(
                        id: id,
                        latitude: latitude,
                        longitude: longitude,
                        address: address,
                        accuracy: accuracy,
                        createdAt: createdAt
                    )
                    records.append(record)
                }
                
                await MainActor.run {
                    self.locationHistory = records
                    self.isLoading = false
                }
            } else {
                throw NSError(domain: "JSON Parse Error", code: -1)
            }
            
        } catch {
            print("❌ 加载位置历史失败：\(error)")
            await MainActor.run {
                errorMessage = "加载失败：\(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }
    
    private func clearHistory() {
        // TODO: 实现清除历史功能
        print("🗑️ 清除位置历史")
    }
}

// MARK: - Models

struct LocationRecord: Identifiable, Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    let address: String
    let accuracy: Double
    let createdAt: Date
}

// MARK: - Subviews

struct LocationRow: View {
    let location: LocationRecord
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: location.createdAt)
    }
    
    private var accuracyText: String {
        if location.accuracy < 10 {
            return "精确"
        } else if location.accuracy < 50 {
            return "良好"
        } else {
            return "粗略"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 地址
            Text(location.address.isEmpty ? "未知位置" : location.address)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(2)
            
            HStack(spacing: 12) {
                // 时间
                Label(timeString, systemImage: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                // 精度
                Label(accuracyText, systemImage: "location.fill")
                    .font(.system(size: 13))
                    .foregroundColor(colorForAccuracy(location.accuracy))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForAccuracy(_ accuracy: Double) -> Color {
        if accuracy < 10 {
            return .green
        } else if accuracy < 50 {
            return .orange
        } else {
            return .red
        }
    }
}

struct LocationMapView: View {
    let location: LocationRecord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: .constant(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ), annotationItems: [location]) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("位置详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LocationHistoryView()
    }
}
