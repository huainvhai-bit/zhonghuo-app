//
//  HomeAnnouncementBar.swift
//  终活
//
//  首页公告：管理员在后台「系统设置 → App 对外联系方式」中编辑，经 getConfig 下发。
//  - 单行宽度超出可视区域时：自动跑马灯滚动
//  - 否则：静止一行展示（短句不会无故滚动）
//

import SwiftUI

struct HomeAnnouncementBar: View {
    let text: String

    private static let defaultText = "欢迎使用终活，多一点爱就多一点温暖。"

    /// 两段文字之间的间隔（与循环周期 segment 对齐）
    private let segmentGap: CGFloat = 40
    /// 滚动速度（点/秒）
    private let scrollSpeed: CGFloat = 32

    @State private var measuredTextWidth: CGFloat = 0

    private var displayText: String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? Self.defaultText : t
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "megaphone.fill")
                .font(.caption)
                .foregroundColor(.orange)

            GeometryReader { geo in
                let containerW = max(1, geo.size.width)
                let needsMarquee = measuredTextWidth > 0 && measuredTextWidth > containerW + 2

                Group {
                    if needsMarquee {
                        MarqueeTicker(
                            text: displayText,
                            containerWidth: containerW,
                            textWidth: measuredTextWidth,
                            segmentGap: segmentGap,
                            speed: scrollSpeed
                        )
                    } else {
                        Text(displayText)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width: containerW, alignment: .leading)
                .background(textMeasureLayer)
            }
            .frame(height: 22)
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
        .onPreferenceChange(AnnouncementTextWidthKey.self) { measuredTextWidth = $0 }
    }

    /// 与展示/Marquee 使用相同字体，用于测量真实占用宽度
    private var textMeasureLayer: some View {
        Text(displayText)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .hidden()
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: AnnouncementTextWidthKey.self, value: g.size.width)
                }
            )
    }
}

private struct AnnouncementTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 无缝循环：两段相同文字 + 间隔，offset 按周期取模
private struct MarqueeTicker: View {
    let text: String
    let containerWidth: CGFloat
    let textWidth: CGFloat
    let segmentGap: CGFloat
    let speed: CGFloat

    var body: some View {
        let period = max(textWidth + segmentGap, 1)

        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let travelled = CGFloat(t * Double(speed))
            let offset = -travelled.truncatingRemainder(dividingBy: CGFloat(Double(period)))

            HStack(spacing: segmentGap) {
                line
                line
            }
            .offset(x: offset)
            .frame(width: containerWidth, alignment: .leading)
            .clipped()
        }
    }

    private var line: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary.opacity(0.9))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}
