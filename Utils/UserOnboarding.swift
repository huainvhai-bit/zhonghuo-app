//
//  UserOnboarding.swift
//  终活
//
//  用户引导系统
//

import SwiftUI

/// 引导页面模型
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let actionText: String?
}

/// 引导页面数据
class OnboardingData: ObservableObject {
    static let shared = OnboardingData()
    
    @Published var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "时光胶囊",
            description: "录制视频、语音或文字，定时发送给家人",
            imageName: "capsule.fill",
            actionText: "开始体验"
        ),
        OnboardingPage(
            title: "遗嘱管理",
            description: "编写和管理遗嘱模块，保障家人权益",
            imageName: "doc.fill",
            actionText: "了解更多"
        ),
        OnboardingPage(
            title: "签到系统",
            description: "定期签到证明安全，超时自动通知紧急联系人",
            imageName: "checkmark.circle.fill",
            actionText: "立即开始"
        ),
        OnboardingPage(
            title: "家人守护",
            description: "绑定家人，共享重要信息，互相守护",
            imageName: "person.3.fill",
            actionText: "开始使用"
        )
    ]
    
    private init() {}
    
    func markAsCompleted() {
        hasCompletedOnboarding = true
    }
}

/// 引导视图
struct OnboardingView: View {
    @StateObject private var data = OnboardingData.shared
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<data.pages.count, id: \.self) { index in
                OnboardingPageView(page: data.pages[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("跳过") {
                    data.markAsCompleted()
                    dismiss()
                }
            }
        }
    }
}

/// 单个引导页面视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(Color(hex: "6366F1"))
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionText = page.actionText {
                Button(actionText) {
                    OnboardingData.shared.markAsCompleted()
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "6366F1"))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.bottom, 40)
    }
}
