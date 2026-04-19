//
//  DemoWidgetServiceBundle.swift
//  DemoWidgetService
//
//  Created by jiguang on 2022/10/26.
//  Copyright © 2022 hxhg. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct DemoWidgetServiceBundle: WidgetBundle {
  var body: some Widget {
//    DemoWidgetService()
    if #available(iOS 16.1, *) {
      PizzaDeliveryActivityWidget()
    }
  }
}
