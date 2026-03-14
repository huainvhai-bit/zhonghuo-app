//
//  AIRobotView.swift
//  终活
//
//  悬浮 AI 机器人 - 可拖拽、自动贴边
//

import SwiftUI

struct AIRobotView: View {
    @State private var isExpanded = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 200)
    @State private var dragOffset: CGSize = .zero
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(id: "1", text: "您好！我是您的终活助手，有什么可以帮您？", isUser: false)
    ]
    
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
            
            // 悬浮按钮
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "AF52DE").opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isExpanded ? "xmark" : "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .position(x: position.x, y: position.y)
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
                                position.x = 70
                            }
                        } else {
                            withAnimation(.spring()) {
                                position.x = screenWidth - 70
                            }
                        }
                        
                        // 确保不超出边界
                        position.y = max(70, min(position.y, UIScreen.main.bounds.height - 70))
                    }
            )
        }
    }
    
    private func sendMessage() {
        guard !message.isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID().uuidString, text: message, isUser: true)
        messages.append(userMessage)
        
        let userText = message
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
