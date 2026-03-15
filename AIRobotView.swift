//
//  AIRobotView.swift
//  终活
//
//  悬浮 AI 机器人 - 靠边隐藏，露个头
//

import SwiftUI

struct AIRobotView: View {
    @State private var isExpanded = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 180)
    @State private var dragOffset: CGSize = .zero
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", text: "您好！我是您的终活助手 🤖", isUser: false)
    ]
    @State private var isPeeking = true // 是否只露出头
    
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
                                            .background(msg.isUser ? Color(hex: "AF52DE") : Color.gray.opacity(0.2))
                                            .foregroundColor(msg.isUser ? .white : .primary)
                                            .cornerRadius(16)
                                        
                                        if !msg.isUser {
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 300)
                        
                        // 输入框
                        HStack(spacing: 8) {
                            TextField("输入消息...", text: $message)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "AF52DE"))
                                    .padding(12)
                                    .background(Color(hex: "AF52DE").opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom))
            }
            
            // 小机器人 - 靠边隐藏，露个头
            ZStack {
                // 机器人头部（始终可见）
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(hex: "AF52DE").opacity(0.4), radius: 6, x: 0, y: 3)
                    .overlay(
                        // 机器人眼睛
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                        .offset(y: -4)
                    )
                    .overlay(
                        // 机器人嘴巴
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 12, height: 3)
                            .offset(y: 6)
                    )
                
                // 机器人身体（展开时显示）
                if isExpanded {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE").opacity(0.8), Color(hex: "007AFF").opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 36, height: 30)
                        .offset(y: 35)
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
                            withAnimation(.spring()) {
                                position.x = 35 // 左边，只露出头
                            }
                        } else {
                            withAnimation(.spring()) {
                                position.x = screenWidth - 35 // 右边，只露出头
                            }
                        }
                        
                        // 确保不超出边界
                        position.y = max(50, min(position.y, UIScreen.main.bounds.height - 50))
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
