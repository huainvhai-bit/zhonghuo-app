//
//  AIRobotView.swift
//  终活
//
//  悬浮 AI 机器人 - 靠边隐藏，露个头
//

import SwiftUI

struct AIRobotView: View {
    @State private var isExpanded = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 25, y: UIScreen.main.bounds.height - 100)
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", text: "您好！我是您的终活助手 ✨", isUser: false)
    ]
    @State private var isOnRightSide = true
    @AppStorage("aiRobotPosition") private var savedPositionX: Double = -1
    @AppStorage("aiRobotPositionY") private var savedPositionY: Double = -1
    
    var body: some View {
        ZStack {
            if isExpanded {
                // 聊天界面
                VStack {
                    Spacer()
                    
                    // 聊天窗口
                    VStack(spacing: 12) {
                        // 消息列表
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(messages) { msg in
                                    HStack {
                                        if msg.isUser {
                                            Spacer()
                                        }
                                        
                                        Text(msg.text)
                                            .padding(12)
                                            .background(msg.isUser ? Color(hex: "6366F1") : Color.gray.opacity(0.15))
                                            .foregroundColor(msg.isUser ? .white : .primary)
                                            .cornerRadius(16)
                                        
                                        if !msg.isUser {
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 280)
                        
                        // 输入框
                        HStack(spacing: 8) {
                            TextField("输入消息...", text: $message)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(hex: "6366F1"))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 12)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 小机器人 - 靠边半隐藏，半透明
            ZStack {
                // 机器人图标
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "6366F1"), Color(hex: "FF6B6B")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 45)
                    .shadow(color: isExpanded ? Color(hex: "6366F1").opacity(0.4) : .clear, radius: isExpanded ? 8 : 0, x: 0, y: 4)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        // 未展开时半透明遮罩
                        isExpanded ? nil : Color.black.opacity(0.3)
                    )
                    .offset(x: isOnRightSide ? -20 : 20) // 让一半隐藏在屏幕边缘
                    .opacity(isExpanded ? 1 : 0.5) // 不使用时半透明
                    .scaleEffect(isExpanded ? 1 : 0.9)
            }
            .position(x: position.x, y: position.y)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
            }
            .onAppear {
                // 初始化位置
                if savedPositionX != -1 {
                    position = CGPoint(x: savedPositionX, y: savedPositionY)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = CGPoint(
                            x: value.startLocation.x + value.translation.width,
                            y: value.startLocation.y + value.translation.height
                        )
                    }
                    .onEnded { value in
                        // 自动贴边
                        let screenWidth = UIScreen.main.bounds.width
                        if position.x < screenWidth / 2 {
                            isOnRightSide = false
                            withAnimation(.spring()) {
                                position.x = 22 // 左边，一半隐藏
                            }
                        } else {
                            isOnRightSide = true
                            withAnimation(.spring()) {
                                position.x = screenWidth - 22 // 右边，一半隐藏
                            }
                        }
                        
                        // 确保不超出边界
                        position.y = max(60, min(position.y, UIScreen.main.bounds.height - 60))
                        
                        // 保存位置
                        savedPositionX = position.x
                        savedPositionY = position.y
                    }
            )
        }
    }
    
    private func sendMessage() {
        guard !message.isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID().uuidString, text: message, isUser: true)
        messages.append(userMessage)
        
        message = ""
        
        // 模拟 AI 回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responses = [
                "我明白了，这会帮您处理。",
                "这是个很好的问题，让我想想...",
                "您可以这样操作...",
                "需要我帮您设置提醒吗？",
                "好的，已经记录下来了。"
            ]
            let randomResponse = responses.randomElement() ?? "好的"
            let aiMessage = ChatMessage(id: UUID().uuidString, text: randomResponse, isUser: false)
            messages.append(aiMessage)
        }
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let isUser: Bool
}

#Preview {
    AIRobotView()
}
