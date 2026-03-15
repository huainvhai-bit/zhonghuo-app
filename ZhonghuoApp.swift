//
//  ZhonghuoApp.swift
//  终活 App 入口
//

import SwiftUI

@main
struct ZhonghuoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
// class AppDelegate: NSObject, UIApplicationDelegate {
//     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//         // 初始化通知
//         NotificationManager.shared.requestAuthorization()
//         NotificationManager.shared.registerCategories()
//         UNUserNotificationCenter.current().delegate = NotificationManager.shared
//         
//         print("✅ 终活 App 启动完成")
//         return true
//     }
// }
