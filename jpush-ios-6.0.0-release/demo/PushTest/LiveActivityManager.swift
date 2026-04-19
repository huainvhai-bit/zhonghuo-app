//
//  LiveActivityManager.swift
//  PushTest
//
//  Created by jiguang on 2022/8/31.
//

import UIKit
import Foundation
import ActivityKit

@available(iOS 16.1, *)
@objcMembers class LiveActivityManager: NSObject {
  
  static let shared = LiveActivityManager()
  
  var seqIndex = 0
  
  private override init() {
    super.init()
  }
  
  override class func copy() -> Any {
    return self
  }
  
  override class func mutableCopy() -> Any {
    return self
  }
  
  func startManager() {
    authUpdate()
    pushToStart()
    observeLiveActivity()
  }
  
  /**
   * 上报pushToStartToken
   */
  func pushToStart() {
    Task {
      if #available(iOS 17.2, *) {
        var beforeToken = "";
        for await pushtoken in Activity<JGLAAttributes>.pushToStartTokenUpdates {
          let pushtokenstr = pushtoken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
//          print("pushToStartToken: JGLAAttributes -> \(pushtokenstr)")
          // 建议在这里做个去重处理，因为这里的回调可能会有多次，且值没有变化。
          if (beforeToken == pushtokenstr) {
            return
          }
          beforeToken = pushtokenstr
          
          // 向jiguang上报pushToStartToken
          JPUSHService.registerLiveActivity("JGLAAttributes", pushToStartToken: pushtoken, completion: { code, alias, token, seq in
            print("register JGLAAttributes pushToStartToken result: \(pushtokenstr) result:\(code) seq:\(seq)")
          }, seq: seq())
          
          
        }
      } else {
        // Fallback on earlier versions
      }
    }
    
  }
  
  /**
   * 监听LiveActivity的变化
   */
  func observeLiveActivity() {
    Task {
      for await activity in Activity<JGLAAttributes>.activityUpdates {
          Task {
            for await pushtoken in activity.pushTokenUpdates {
              let pushtokenstr = pushtoken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
//              print("observeLiveActivity - pushtoken - \(pushtokenstr)")
              // 向极光注册liveactivity，在推送平台通过liveactivityId推送通知进行更新
              JPUSHService.registerLiveActivity(activity.attributes.tag, pushToken: pushtoken, completion: { code, liveactivityId, token, seq in
                print("observeLiveActivity : registerLiveActivity liveactivityTagId:\(String(describing: liveactivityId)) token: \(pushtokenstr) result:\(code) seq:\(seq)")
              }, seq: seq())
              
            }
          }
      }
    }
  }
  
  
  func authObserve() {
    // 监听live activity 权限变化
    authUpdate()
  }
  
  func authUpdate() {
    
    // liveActivity的权限监听
    let authInfo = ActivityAuthorizationInfo.init()
    let enable = authInfo.areActivitiesEnabled
    print("liveactivity enable = \(enable)")
    
    Task {
      for await authState in authInfo.activityEnablementUpdates {
        print("liveactivity enable change - \(authState)")
      }
    }
  }
  
  // MARK: - Functions
  func startALiveActivity() {
    
    Task {
      
      var number = UserDefaults.standard.integer(forKey: "number")
      number = number + 1
      UserDefaults.standard.set(number, forKey: "number")
      UserDefaults.standard.synchronize()
      let liveactivityId = "LiveActivity-\(number)"
      
      // 初始状态
      let initialContentState = JGLAAttributes.ContentState(eventStr: "begin", eventTime: 1)
      let activityAttributes = JGLAAttributes(name: "LiveActivity", number: number, tag: liveactivityId)
      
      do {
        
        // 创建Activity
        let jgActivity = try Activity.request(attributes: activityAttributes, contentState: initialContentState, pushType:PushType.token)
        
        // 监听pushToken变化
        Task {
          for await pushtoken in jgActivity.pushTokenUpdates {
            let pushtokenstr = pushtoken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
            print("\(liveactivityId) pushtoken -> \(pushtokenstr)")
            
            // 向极光注册liveactivity，在推送平台通过liveactivityId推送通知进行更新
            JPUSHService.registerLiveActivity(liveactivityId, pushToken: pushtoken, completion: { code, liveactivityId, token, seq in
              print("registerLiveActivity liveactivityId:\(String(describing: liveactivityId)) token: \(pushtokenstr) result:\(code) seq:\(seq)")
            }, seq: seq())
          }
        }
        
        // activity的状态变化
        Task {
          for await stateUpdate in jgActivity.activityStateUpdates {
            print("\(jgActivity.attributes.name) activityStateUpdates - \(String(describing: stateUpdate))")
            if stateUpdate == .dismissed || stateUpdate == .ended {
              // 当liveactivity结束时，向极光注册清除pushtoken
              let liveactivityId = "\(jgActivity.attributes.name)-\(jgActivity.attributes.number)"
              JPUSHService.registerLiveActivity(liveactivityId, pushToken: nil, completion: { code, liveActivityId, token, seq in
                print("registerLiveActivity liveactivityId:\(String(describing: liveActivityId)) token: nil result:\(code) seq:\(seq)")
              }, seq: seq());
            }
          }
        }
        
        // activity的内容变化
        Task {
          for await contentUpdate in jgActivity.contentStateUpdates {
            print("contentStateUpdates - \(contentUpdate)")
          }
        }
        print("Requested a Live Activity \(String(describing: jgActivity.id)).")
      } catch (let error) {
        print("Error requesting Live Activity \(error.localizedDescription).")
      }
    
    }
    
  }
  
  
  func updateLiveActivity() {
    Task {
      let updatedStatus = JGLAAttributes.JGLAStatus(eventStr: "update", eventTime: 2)
      // 这里是把所有的liveActivity更新
      for activity in Activity<JGLAAttributes>.activities {
        await activity.update(using: updatedStatus, alertConfiguration: nil)
      }
    }
  }
  
  func stopLiveActivity() {
    Task {
      for activity in Activity<JGLAAttributes>.activities{
        
        let finalStatus = JGLAAttributes.JGLAStatus(eventStr: "end", eventTime: 3)
        await activity.end(using: finalStatus,dismissalPolicy: .default)
        let liveactivityId = "LiveActivity-\(activity.attributes.number)"
        // 当liveactivity结束时，向极光注册清除pushtoken
        JPUSHService.registerLiveActivity(liveactivityId, pushToken: nil, completion: { code, liveactivityId, token, seq in
          print("registerLiveActivity liveactivityId:\(String(describing: liveactivityId)) token: nil result:\(code) seq:\(seq)")
        }, seq: seq());
        
      }
    }
  }
  
  func seq() -> Int {
    seqIndex = seqIndex + 1
    return seqIndex
  }
  
}
