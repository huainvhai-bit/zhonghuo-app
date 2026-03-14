//
//  ContentView.swift
//  终活 - 主界面
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            NavigationView {
                HomeStatusView()
                    .navigationTitle("终活")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("首页")
            }
            .tag(0)
            
            // 时光胶囊
            TimeCapsuleView()
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("时光胶囊")
                }
                .tag(1)
            
            // 嘱托与资产
            WillAssetsView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("嘱托与资产")
                }
                .tag(2)
            
            // AI 助手
            SimplifiedAIView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("AI 助手")
                }
                .tag(3)
            
            // 我的
            SettingsView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("我的")
                }
                .tag(4)
        }
        .accentColor(.primaryPurple)
    }
}

#Preview {
    ContentView()
}
