//
//  ZhonghuoApp.swift
//  终活 App 入口
//

import SwiftUI

@main
struct ZhonghuoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("🟢 App 进入前台 - ZhonghuoApp")
                // 触发实时同步
                RealTimeSyncManager.shared.appDidBecomeActive()
            }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 初始化通知
        NotificationManager.shared.requestPermission()
        
        // 设置全局导航栏样式
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color(hex: "6366F1")) // 优化为靛蓝色
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = .white
        
        // 调试：打印用户状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            print("🔵 ====== 用户状态 ======")
            print("📁 文档路径：\(docsPath)")
            print("👤 登录状态：\(UserManager.shared.isLoggedIn)")
            print("⏰ 签到间隔：\(UserManager.shared.checkInInterval.rawValue)")
            if let user = UserManager.shared.currentUser {
                print("📝 用户：\(user.name), 签到间隔：\(user.checkInInterval.rawValue)")
            }
            
            // 检查 user.json 是否存在
            let userFileURL = URL(fileURLWithPath: docsPath).appendingPathComponent("user.json")
            let exists = FileManager.default.fileExists(atPath: userFileURL.path)
            print("📄 user.json 存在：\(exists)")
            
            if exists {
                do {
                    let data = try Data(contentsOf: userFileURL)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📄 user.json 内容：\(json)")
                    }
                } catch {
                    print("❌ 读取 user.json 失败：\(error)")
                }
            }
        }
        
        print("✅ 终活 App 启动完成")
        return true
    }
}
