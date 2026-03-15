//
//  AIRobotView.swift
//  终活
//
//  悬浮 AI 机器人 - 靠边隐藏，露个头
//

import SwiftUI

struct AIRobotView: View {
    @State private var isExpanded = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - 160)
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", text: "您好！我是您的终活助手 🤖", isUser: false)
    ]
    @State private var isOnRightSide = true
    
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
                                            .background(msg.isUser ? Color(hex: "AF52DE") : Color.gray.opacity(0.15))
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
                                    .background(Color(hex: "AF52DE"))
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
            
            // 小机器人 - 靠边隐藏，只露出一半
            ZStack {
                // 机器人头部
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color(hex: "AF52DE").opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    // 机器人脸部
                    VStack(spacing: 4) {
                        // 眼睛
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                        }
                        .offset(y: -2)
                        
                        // 嘴巴
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 14, height: 3)
                    }
                    .offset(y: 2)
                }
                .offset(x: isOnRightSide ? -12 : 12) // 让一半隐藏在屏幕边缘
                
                // 机器人身体（展开时显示）
                if isExpanded {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE").opacity(0.9), Color(hex: "007AFF").opacity(0.9)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 35)
                        .offset(y: 38)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .position(x: position.x, y: position.y)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
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
                                position.x = 38 // 左边，一半隐藏
                            }
                        } else {
                            isOnRightSide = true
                            withAnimation(.spring()) {
                                position.x = screenWidth - 38 // 右边，一半隐藏
                            }
                        }
                        
                        // 确保不超出边界
                        position.y = max(60, min(position.y, UIScreen.main.bounds.height - 60))
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
