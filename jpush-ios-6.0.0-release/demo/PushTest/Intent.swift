//
//  Intent.swift
//  PushTesttest
//
//  Created by jiguang on 2022/9/9.
//

import Foundation
// 1. 导入 AppIntents framework
import AppIntents


@available(iOS 16.0, *)
// 2. 定义一个实现了 `SetFocusFilterIntent` 的结构体
struct ExampleChatAppFocusFilter: SetFocusFilterIntent {
  
  
  // 3. 设置标题
  static var title: LocalizedStringResource = "title"
  // 4. 和描述
  static var description: LocalizedStringResource? = "description"
  
  // 可选 String 参数，带默认值， title为显示标题。想要非可选，则将参数定义为非可选类型
  @Parameter(title: "focus_noti_filter_str", default: "fromwork")
  var focus_noti_filter_str: String?
  
  
  
  // 需要实现的属性，返回一个包含标题和副标题的 DisplayRepresentation 对象
  var displayRepresentation: DisplayRepresentation {
    
    // 返回 DisplayRepresentation 对象
    return DisplayRepresentation(title: "display_title", subtitle: "display_subtitle")
  }
  
  
  // 当在设置里面修改过滤条件属性内容的时候，就会触发该方法
  func perform() async throws -> some IntentResult {
    // 做更新应用的操作
    // ...
    return .result()
  }
  
  
  // 在 Intent 中设置 appContext
  var appContext: FocusFilterAppContext {
    // 设置一个过滤器谓词，匹配被允许的文本标识符
    let allowedAccountList = [focus_noti_filter_str]
    let predicate = NSPredicate(format: "SELF IN %@", allowedAccountList)
    // 返回一个包含过滤器谓词的 `FocusFilterAppContext` 对象，但通知没有匹配上过滤词的时候就会被静音
    return FocusFilterAppContext(notificationFilterPredicate: predicate)
  }
  
  
}
