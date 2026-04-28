//
//  HomeAnnouncementBar.swift
//  终活
//
//  首页公告：管理员在后台「系统设置 → App 对外联系方式」中编辑，经 getConfig 下发。
//

import SwiftUI

struct HomeAnnouncementBar: View {
    let text: String

    private static let defaultText = "欢迎使用终活，多一点爱就多一点温暖。"

    private var displayText: String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? Self.defaultText : t
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "megaphone.fill")
                .font(.caption)
                .foregroundColor(.orange)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(displayText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("公告")
        .accessibilityValue(displayText)
    }
}
