//
//  OnboardingView.swift
//  终活
//
//  新手引导页面
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPageItem] = [
        OnboardingPageItem(
            icon: "hand.thumbsup.fill",
            title: "安全签到",
            description: "每 48 小时签到一次，让家人安心。如果忘记签到，紧急联系人会收到提醒。",
            color: Color(hex: "34C759")
        ),
        OnboardingPageItem(
            icon: "capsule.fill",
            title: "时光胶囊",
            description: "写下想说的话，设置未来的发送时间。让爱与关怀穿越时空，温暖每一个重要时刻。",
            color: Color(hex: "AF52DE")
        ),
        OnboardingPageItem(
            icon: "doc.text.fill",
            title: "遗嘱嘱托",
            description: "提前规划财产分配、丧葬意愿等身后事。内置模板帮助你快速完成，让家人少一份负担。",
            color: Color(hex: "007AFF")
        ),
        OnboardingPageItem(
            icon: "person.2.fill",
            title: "见证人",
            description: "邀请可信赖的人作为见证人，增强遗嘱的法律效力。支持多人管理，随时更新状态。",
            color: Color(hex: "FF9500")
        ),
        OnboardingPageItem(
            icon: "heart.fill",
            title: "温暖陪伴",
            description: "终活不是终点，而是对生命的尊重。我们陪你规划每一天，让爱没有遗憾。",
            color: Color(hex: "FF3B30")
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "F6F6F8")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color(hex: "AF52DE") : Color(hex: "D1D1D6"))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 40)
                
                // 内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 底部按钮
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("下一页")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "AF52DE"))
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }) {
                            Text("跳过")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                isFirstLaunch = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("开始使用")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "34C759"))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 引导页数据
struct OnboardingPageItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - 引导页视图
struct OnboardingPageView: View {
    let page: OnboardingPageItem
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundColor(page.color)
            }
            
            Spacer()
            
            // 文字
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
}
