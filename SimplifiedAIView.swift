//
//  SimplifiedAIView.swift
//  终活 - AI 助手
//

import SwiftUI

struct SimplifiedAIView: View {
    @State private var question = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // AI 介绍
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryPurple)
                    
                    Text("AI 助手")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("有任何关于终活规划的问题，都可以问我哦")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 输入框
                HStack(spacing: 12) {
                    TextField("输入你的问题...", text: $question)
                        .padding()
                        .background(Color.backgroundLight)
                        .cornerRadius(20)
                    
                    Button(action: {
                        // TODO: 发送问题
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.primaryPurple)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .navigationTitle("AI 助手")
        }
    }
}

#Preview {
    SimplifiedAIView()
}
