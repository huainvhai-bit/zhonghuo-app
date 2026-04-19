//	            __    __                ________
//	| |    | |  \ \  / /  | |    | |   / _______|
//	| |____| |   \ \/ /   | |____| |  / /
//	| |____| |    \  /    | |____| |  | |   _____
//	| |    | |    /  \    | |    | |  | |  |____ |
//  | |    | |   / /\ \   | |    | |  \ \______| |
//  | |    | |  /_/  \_\  | |    | |   \_________|
//
//	Copyright (c) 2012年 HXHG. All rights reserved.
//	http://www.jpush.cn
//  Created by Zhanghao
//

#import "AppDelegate.h"
#import "JPUSHService.h"
#import "RootViewController.h"
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <CoreLocation/CoreLocation.h>
#import <PushKit/PushKit.h>
#import "PushTest-Swift.h"
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

@interface AppDelegate ()<JPUSHRegisterDelegate,JPUSHGeofenceDelegate,JPUSHInAppMessageDelegate,PKPushRegistryDelegate>{
  CLLocationManager * _locationManager;

}
@end

@implementation AppDelegate {
  RootViewController *rootViewController;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  // Override point for customization after application launch.
  __block NSString *advertisingId = @"";
  if (@available(iOS 14, *)) {
      //设置Info.plist中 NSUserTrackingUsageDescription 需要广告追踪权限，用来定位唯一用户标识
      [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
          if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
            advertisingId = [[ASIdentifierManager sharedManager] advertisingIdentifier].UUIDString;
          }
      }];
  } else {
      // 使用原方式访问 IDFA
    advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
  }
  
  // 3.0.0及以后版本注册
  JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
  if (@available(iOS 12.0, *)) {
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound|JPAuthorizationOptionProvidesAppNotificationSettings;
  } else {
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
  }
  if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
    //可以添加自定义categories
//    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
//      NSSet<UNNotificationCategory *> *categories;
//      entity.categories = categories;
//    }
//    else {
//      NSSet<UIUserNotificationCategory *> *categories;
//      entity.categories = categories;
//    }
  }
  [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
  //如果使用地理围栏，请先获取地理位置权限。
  [self getLocationAuthority];
  //如果使用地理围栏功能，需要注册地理围栏代理
  [JPUSHService registerLbsGeofenceDelegate:self withLaunchOptions:launchOptions];
  //如果使用应用内消息功能，需要配置pageEnterTo:和pageLeave:接口，且可以通过设置该代理获取应用内消息的展示和点击事件
  [JPUSHService setInAppMessageDelegate:self];
  
  //如不需要使用IDFA，advertisingIdentifier 可为nil
  [JPUSHService setupWithOption:launchOptions appKey:appKey
                        channel:channel
               apsForProduction:isProduction
          advertisingIdentifier:advertisingId];
  
  //2.1.9版本新增获取registration id block接口。
  [JPUSHService registrationIDCompletionHandler:^(int resCode, NSString *registrationID) {
    if(resCode == 0){
      NSLog(@"registrationID获取成功：%@",registrationID);
      
    }
    else{
      NSLog(@"registrationID获取失败，code：%d",resCode);
    }
  }];
  
  //注册 voip
  [self voipRegistration];
  
  // 检测通知授权情况。可选项，不一定要放在此处，可以运行一定时间后再调用
  [self performSelector:@selector(checkNotificationAuthorization) withObject:nil afterDelay:10];
  
  
  // 监听实时活动
  if (@available(iOS 16.1, *)) {
    [[LiveActivityManager shared] startManager];
  } else {
    // Fallback on earlier versions
  }

  
  [[NSBundle mainBundle] loadNibNamed:@"JpushTabBarViewController"
                                owner:self
                              options:nil];
  self.window.rootViewController = self.rootController;
  [self.window makeKeyAndVisible];
  rootViewController = (RootViewController *)
      [self.rootController.viewControllers objectAtIndex:0];

  return YES;
}

/**
 注册Voip服务（以下示例代码，开发者可根据需要修改）JPush 3.3.2 JCore 2.2.4 及以上支持Voip功能
 */
- (void)voipRegistration{
  dispatch_queue_t mainQueue = dispatch_get_main_queue();
  PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:mainQueue];
  voipRegistry.delegate = self;
  // Set the push type to VoIP
  voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)applicationWillResignActive:(UIApplication *)application {
  //    [APService stopLogPageView:@"aa"];
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.

  [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [application setApplicationIconBadgeNumber:0];
  [application cancelAllLocalNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  const unsigned int *tokenBytes = [deviceToken bytes];
  NSString *tokenString = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                        ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                        ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                        ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
  rootViewController.deviceTokenValueLabel.text = tokenString;
  rootViewController.deviceTokenValueLabel.textColor =
      [UIColor colorWithRed:0.0 / 255
                      green:122.0 / 255
                       blue:255.0 / 255
                      alpha:1];
  NSLog(@"Device Token: %@", tokenString);
  [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:
        (UIUserNotificationSettings *)notificationSettings {
}

// Called when your app has been activated by the user selecting an action from
// a local notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
          forLocalNotification:(UILocalNotification *)notification
             completionHandler:(void (^)())completionHandler {
}

// Called when your app has been activated by the user selecting an action from
// a remote notification.
// A nil action identifier indicates the default action.
// You should call the completion handler as soon as you've finished handling
// the action.
- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)())completionHandler {
}
#endif

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [JPUSHService handleRemoteNotification:userInfo];
  NSLog(@"iOS6及以下系统，收到通知:%@", [self logDic:userInfo]);
  [rootViewController addNotificationCount];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:
              (void (^)(UIBackgroundFetchResult))completionHandler {
  [JPUSHService handleRemoteNotification:userInfo];
  NSLog(@"iOS7及以上系统，收到通知:%@", [self logDic:userInfo]);
  
  if ([[UIDevice currentDevice].systemVersion floatValue]<10.0 || application.applicationState>0) {
    [rootViewController addNotificationCount];
  }

  completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application
    didReceiveLocalNotification:(UILocalNotification *)notification {
  [JPUSHService showLocalNotificationAtFront:notification identifierKey:nil];
}

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#pragma mark- JPUSHRegisterDelegate
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger options))completionHandler {
  NSDictionary * userInfo = notification.request.content.userInfo;
  
  UNNotificationRequest *request = notification.request; // 收到推送的请求
  UNNotificationContent *content = request.content; // 收到推送的消息内容
  
  NSNumber *badge = content.badge;  // 推送消息的角标
  NSString *body = content.body;    // 推送消息体
  UNNotificationSound *sound = content.sound;  // 推送消息的声音
  NSString *subtitle = content.subtitle;  // 推送消息的副标题
  NSString *title = content.title;  // 推送消息的标题
  
  if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    [JPUSHService handleRemoteNotification:userInfo];
    NSLog(@"iOS10 前台收到远程通知:%@", [self logDic:userInfo]);

    [rootViewController addNotificationCount];

  }
  else {
    // 判断为本地通知
    NSLog(@"iOS10 前台收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
  }
  completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
}

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
  
  NSDictionary * userInfo = response.notification.request.content.userInfo;
  UNNotificationRequest *request = response.notification.request; // 收到推送的请求
  UNNotificationContent *content = request.content; // 收到推送的消息内容
  
  NSNumber *badge = content.badge;  // 推送消息的角标
  NSString *body = content.body;    // 推送消息体
  UNNotificationSound *sound = content.sound;  // 推送消息的声音
  NSString *subtitle = content.subtitle;  // 推送消息的副标题
  NSString *title = content.title;  // 推送消息的标题
  
  if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    [JPUSHService handleRemoteNotification:userInfo];
    NSLog(@"iOS10 收到远程通知:%@", [self logDic:userInfo]);
    [rootViewController addNotificationCount];

  }
  else {
    // 判断为本地通知
    NSLog(@"iOS10 收到本地通知:{\nbody:%@，\ntitle:%@,\nsubtitle:%@,\nbadge：%@，\nsound：%@，\nuserInfo：%@\n}",body,title,subtitle,badge,sound,userInfo);
  }
  
  completionHandler();  // 系统要求执行这个方法
}

- (void)jpushNotificationAuthorization:(JPAuthorizationStatus)status withInfo:(NSDictionary *)info {
  NSLog(@"receive notification authorization status:%lu, info:%@", status, info);
  [self alertNotificationAuthorization:status];
}

#endif

#pragma mark- PKPushRegistryDelegate

/// 系统返回VoipToken,上报给极光服务器
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type{
    [JPUSHService registerVoipToken:pushCredentials.token];
    NSLog(@"Voip Token: %@", pushCredentials.token);
}

/**
 * 接收到Voip推送信息，并向极光服务器上报（iOS 8.0 - 11.0）
 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type{
  // 提交回执给极光服务器
  [JPUSHService handleVoipNotification:payload.dictionaryPayload];
  NSLog(@"Voip Payload: %@, %@",payload,payload.dictionaryPayload);
  // [ 示例代码 ] 发起一个本地通知
  JPushNotificationContent *content = [[JPushNotificationContent alloc] init];;
  content.title = @"测试标题";
  content.body = @"测试内容";
  JPushNotificationTrigger *triggger = [[JPushNotificationTrigger alloc] init];
  triggger.timeInterval = 3;
  JPushNotificationRequest *request = [[JPushNotificationRequest alloc] init];
  request.content = content;
  request.trigger = triggger;
  request.requestIdentifier = @"test";
  request.completionHandler = ^(id result) {
    if (result) {
      NSLog(@"添加 timeInterval 通知成功 --- %@", result);
    }else {
      NSLog(@"添加 timeInterval 通知失败 --- %@", result);
    }
  };
  [JPUSHService addNotification:request];
}

/**
 * 接收到Voip推送信息，并向极光服务器上报（iOS 11.0 以后）
 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void(^)(void))completion{
  // 提交回执给极光服务器
  [JPUSHService handleVoipNotification:payload.dictionaryPayload];
  NSLog(@"Voip Payload: %@, %@",payload,payload.dictionaryPayload);
}

#ifdef __IPHONE_12_0
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
  NSString *title = nil;
  if (notification) {
    title = @"从通知界面直接进入应用";
  }else{
    title = @"从系统设置界面进入应用";
  }
  UIAlertView *test = [[UIAlertView alloc] initWithTitle:title
                                                 message:@"pushSetting"
                                                delegate:self
                                       cancelButtonTitle:@"yes"
                                       otherButtonTitles:nil, nil];
  [test show];
  
}
#endif

// log NSSet with UTF8
// if not ,log will be \Uxxx
- (NSString *)logDic:(NSDictionary *)dic {
  if (![dic count]) {
    return nil;
  }
  NSString *tempStr1 =
      [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                   withString:@"\\U"];
  NSString *tempStr2 =
      [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *tempStr3 =
      [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
  NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
  NSString *str =
      [NSPropertyListSerialization propertyListFromData:tempData
                                       mutabilityOption:NSPropertyListImmutable
                                                 format:NULL
                                       errorDescription:NULL];
  return str;
}
#pragma mark -JPUSHGeofenceDelegate
//进入地理围栏区域
- (void)jpushGeofenceIdentifer:(NSString *)geofenceId didEnterRegion:(NSDictionary *)userInfo error:(NSError *)error {
  NSLog(@"进入地理围栏区域");
  if (error) {
    NSLog(@"error = %@",error);
    return;
  }
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    [self testAlert:userInfo];
  }else{
    // 进入后台
    [self geofenceBackgroudTest:userInfo];
  }
}
//离开地理围栏区域
- (void)jpushGeofenceIdentifer:(NSString *)geofenceId didExitRegion:(NSDictionary *)userInfo error:(NSError *)error {
  NSLog(@"离开地理围栏区域");
  if (error) {
    NSLog(@"error = %@",error);
    return;
  }
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    [self testAlert:userInfo];
  }else{
    // 进入后台
    [self geofenceBackgroudTest:userInfo];
  }
}

- (void)jpushGeofenceRegion:(NSDictionary *)geofence error:(NSError *)error {
  NSLog(@"region:%@", geofence);
}

- (void)jpushCallbackGeofenceReceived:(NSArray<NSDictionary *> *)geofenceList {
  NSLog(@"region list:%@", geofenceList);
}

//
- (void)geofenceBackgroudTest:(NSDictionary * _Nullable)userInfo{
  //静默推送：
  if(!userInfo){
    NSLog(@"静默推送的内容为空");
    return;
  }
  //TODO
  
}

- (void)testAlert:(NSDictionary*)userInfo{
  if(!userInfo){
    NSLog(@"messageDict 为 nil ");
    return;
  }
  NSString *title = userInfo[@"title"];
  NSString *body = userInfo[@"content"];
  if (title &&  body ) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
  }
}
#pragma mark location
- (void)getLocationAuthority{
  _locationManager= [[CLLocationManager alloc] init];
  if(@available(iOS 8.0, *)) {
    [_locationManager requestAlwaysAuthorization];
  }else{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
      NSLog(@"kCLAuthorizationStatusNotDetermined");
    }
  }
  _locationManager.delegate = (id<CLLocationManagerDelegate>)self;
}
#pragma mark -CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
  if (status != kCLAuthorizationStatusNotDetermined) {
    NSLog(@"获取地理位置权限成功");
  }
}

#pragma mark - JPushInAppMessageDelegate
- (void)jPushInAppMessageDidShow:(JPushInAppMessage *)inAppMessage {
  NSString *messageId = inAppMessage.mesageId;
  NSString *title = inAppMessage.title;
  NSString *content = inAppMessage.content;
  // ... 更多参数获取请查看JPushInAppMessage
  NSLog(@"jPushInAppMessageDidShow - messageId:%@, title:%@, content:%@",messageId,title,content);
}

- (void)jPushInAppMessageDidClick:(JPushInAppMessage *)inAppMessage {
  NSString *messageId = inAppMessage.mesageId;
  NSString *title = inAppMessage.title;
  NSString *content = inAppMessage.content;
  // ... 更多参数获取请查看JPushInAppMessage
  NSLog(@"jPushInAppMessageDidClick - messageId:%@, title:%@, content:%@",messageId,title,content);
}

#pragma mark - 通知权限引导

// 检测通知权限授权情况
- (void)checkNotificationAuthorization {
  [JPUSHService requestNotificationAuthorization:^(JPAuthorizationStatus status) {
    // run in main thread, you can custom ui
    NSLog(@"notification authorization status:%lu", status);
    [self alertNotificationAuthorization:status];
  }];
}

// 通知未授权时提示，是否进入系统设置允许通知，仅供参考
- (void)alertNotificationAuthorization:(JPAuthorizationStatus)status {
  if (status < JPAuthorizationStatusAuthorized) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"允许通知" message:@"是否进入设置允许通知？" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    if(@available(iOS 8.0, *)) {
      [JPUSHService openSettingsForNotification:^(BOOL success) {
        NSLog(@"open settings %@", success?@"success":@"failed");
      }];
    }
  }
}

@end
