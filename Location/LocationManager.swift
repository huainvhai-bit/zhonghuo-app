//
//  LocationManager.swift
//  终活
//
//  位置服务管理器
//  职责：CoreLocation 集成、位置上传、定位权限管理
//

import Foundation
import CoreLocation
import Combine

/// 位置服务管理器
/// 职责：CoreLocation 集成、位置上传、定位权限管理
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    // MARK: - 定位管理
    
    /// 位置管理器
    private let locationManager = CLLocationManager()
    
    /// 定位授权状态
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    /// 当前位置
    @Published var currentLocation: CLLocation?
    
    /// 持续上传定时器
    private var continuousUploadTimer: Timer?
    
    // MARK: - 初始化
    
    /// 初始化
    /// - 自动配置定位管理器
    override init() {
        super.init()
        setupLocationManager()
    }
    
    /// 配置定位管理器
    /// - 授权级别：导航级精度（kCLLocationAccuracyBestForNavigation）
    /// - 距离过滤器：50 米（移动 50 米以上才更新）
    /// - 活动类型：其他导航（自动优化定位策略）
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation  // 导航级精度
        locationManager.distanceFilter = 50  // 移动 50 米以上再更新
        locationManager.activityType = .otherNavigation  // 自动优化定位策略
        
        locationAuthStatus = CLLocationManager.authorizationStatus()
    }
    
    // MARK: - 定位权限管理
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorizationIfNeeded() {
        // 如果用户修改了签到间隔（不是测试模式），请求后台定位
        guard locationAuthStatus == .authorizedWhenInUse else {
            return
        }
        
        if DebugConfig.enableLogs {
            print("🔔 请求后台定位权限")
        }
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        print("🛰️ 开始定位")
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> String? {
        guard let location = currentLocation else { return nil }
        return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    /// 授权状态变化
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 定位授权状态变化：\(status)")
        currentLocation = manager.location
        locationAuthStatus = status
    }
    
    /// 位置更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        print("📍 位置更新：\(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 上传位置到服务器
        Task {
            await uploadLocation(latitude: location.coordinate.latitude,
                               longitude: location.coordinate.longitude,
                               accuracy: location.horizontalAccuracy)
        }
    }
    
    /// 位置错误
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 位置错误：\(error.localizedDescription)")
    }
    
    // MARK: - 位置上传
    
    /// 批量上传位置（定时任务）
    private func startContinuousUploadTimer() {
        // 每 5 分钟上传一次位置（减少 API 调用）
        continuousUploadTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else { return }
            
            Task {
                await self.uploadLocation(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude,
                                        accuracy: location.horizontalAccuracy)
            }
        }
    }
    
    /// 上传位置到服务器
    func uploadLocation(latitude: Double, longitude: Double, accuracy: Double?) async {
        let manager = APIClient.shared
        
        let query = """
        mutation {
            uploadLocation(
                latitude: \(latitude)
                longitude: \(longitude)
                accuracy: \(accuracy ?? 0)
            ) {
                success
            }
        }
        """
        
        do {
            let response = try await manager.query(query)
            
            if let data = response["data"] as? [String: Any],
               let uploadResult = data["uploadLocation"] as? [String: Any],
               let success = uploadResult["success"] as? Bool,
               success {
                print("📍 位置上传成功：\(latitude), \(longitude)")
            } else {
                print("❌ 位置上传失败")
            }
        } catch {
            print("❌ 位置上传失败：\(error)")
        }
    }
    
    // MARK: - 清理
    
    deinit {
        continuousUploadTimer?.invalidate()
        continuousUploadTimer = nil
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        print("♻️ LocationManager 已释放")
    }
}
