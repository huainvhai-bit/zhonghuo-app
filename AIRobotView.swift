//
//  AIRobotView.swift
//  终活 - AI 悬浮机器人
//

import SwiftUI

struct AIRobotView: View {
    @State private var isChatOpen = false
    @State private var offset: CGSize = .zero
    
    let onChatOpened: () -> Void
    let onChatClosed: () -> Void
    
    var body: some View {
        ZStack {
            if isChatOpen {
                ChatView(onClose: {
                    isChatOpen = false
                    onChatClosed()
                })
            }
            
            // 悬浮按钮
            Button(action: {
                isChatOpen = true
                onChatOpened()
            }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.primaryPurple)
                    .clipShape(Circle())
                    .shadow(color: .primaryPurple.opacity(0.4), radius: 10)
            }
            .offset(x: offset.width, y: offset.height)
            .position(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 150)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { value in
                        withAnimation {
                            offset = .zero
                        }
                    }
            )
        }
    }
}

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            // 聊天头部
            HStack {
                Text("AI 助手")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.cardLight)
            
            // 聊天内容
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    MessageBubble(text: "你好！我是你的终活助手，有什么可以帮你的吗？", isFromAI: true)
                }
                .padding()
            }
            
            // 输入框
            HStack {
                TextField("输入消息...", text: $message)
                    .padding()
                    .background(Color.backgroundLight)
                    .cornerRadius(20)
                
                Button(action: {
                    // 发送消息
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryPurple)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
    }
}

struct MessageBubble: View {
    let text: String
    let isFromAI: Bool
    
    var body: some View {
        HStack {
            if isFromAI {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.primaryPurple)
            }
            
            Text(text)
                .padding()
                .background(isFromAI ? Color.primaryPurple.opacity(0.1) : Color.primaryPurple)
                .foregroundColor(isFromAI ? .textPrimary : .white)
                .cornerRadius(16)
            
            if !isFromAI {
                Image(systemName: "bubble.right.fill")
                    .foregroundColor(.primaryPurple)
            }
        }
    }
}

#Preview {
    AIRobotView(onChatOpened: {}, onChatClosed: {})
}
