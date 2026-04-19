//
//  ActivityAttributes.swift
//  PushTest
//
//  Created by jiguang on 29/7/2022.
//

import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct JGLAAttributes: ActivityAttributes {
    public typealias JGLAStatus = ContentState

    // ContentState 里 为可以动态更新的数据。
    public struct ContentState: Codable, Hashable {
      var eventStr: String // 事件名称
      var eventTime: Int // 事件时间
    }

    // 以下为静态数据，不可改变。
    var name: String // 展示的名字
    var number: Int  // 第几个
    var tag: String // 标签
    
}
