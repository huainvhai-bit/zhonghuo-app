//
//  DemoWidgetService.swift
//  DemoWidgetService
//
//  Created by jiguang on 2022/10/14.
//  Copyright © 2022 hxhg. All rights reserved.
//


import ActivityKit
import WidgetKit
import SwiftUI
import Intents

struct PizzaDeliveryActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: JGLAAttributes.self) { context in
      // Create the view that appears on the Lock Screen and as a
      // banner on the Home Screen of devices that don't support the
      // Dynamic Island.
      LockScreenLiveActivityView(context: context)
    } dynamicIsland: { context in
      // Create the views that appear in the Dynamic Island.
      DynamicIsland {
        // Create the expanded view.
        DynamicIslandExpandedRegion(.leading) {
          Text("L")
        }
        
        DynamicIslandExpandedRegion(.trailing) {
          Text("T")
        }
        
        DynamicIslandExpandedRegion(.center) {
          Text("C")
        }
        
        DynamicIslandExpandedRegion(.bottom) {
          Text("B")
        }
        
      } compactLeading: {
        // Create the compact leading view.
        Text("CL")
      } compactTrailing: {
        // Create the compact trailing view.
        Text("CT")
      } minimal: {
        // Create the minimal view.
        Text("M")
      }
      .keylineTint(.white)
    }
  }
}


struct LockScreenLiveActivityView: View {
  let context: ActivityViewContext<JGLAAttributes>
  
  var body: some View {
    VStack {
      Spacer()
      Text("JIGUANG: \(context.attributes.name)-\(context.attributes.number)")
      Spacer()
      HStack {
        Spacer()
        Text("eventStr: \(context.state.eventStr) , eventTime: \(context.state.eventTime)")
        Spacer()
      }
      Spacer()
    }
    .activitySystemActionForegroundColor(.indigo)
    .activityBackgroundTint(.cyan)
  }
}

