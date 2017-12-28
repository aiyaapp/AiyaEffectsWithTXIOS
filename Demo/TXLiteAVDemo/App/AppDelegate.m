//
//  AppDelegate.m
//  RTMPiOSDemo
//
//  Created by kuenzhang on 16/3/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "AppDelegate.h"
#include "MainViewController.h"
#import "TXLiveBase.h"
#import "AppLogMgr.h"
#import <Bugly/Bugly.h>
#include "AFNetworkReachabilityManager.h"

#define BUGLY_APP_ID @"18a2342254"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //启动bugly组件，bugly组件为腾讯提供的用于crash上报和分析的开放组件，如果您不需要该组件，可以自行移除
    BuglyConfig * config = [[BuglyConfig alloc] init];
    config.version = [TXLiveBase getSDKVersionStr];

#if DEBUG
    config.debugMode = YES;
#endif
    
    config.channel = @"LiteAV Demo";
    
    [Bugly startWithAppId:BUGLY_APP_ID config:config];
    
    NSLog(@"rtmp demo init crash report");

    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    //初始化log模块
    [TXLiveBase sharedInstance].delegate = [AppLogMgr shareInstance];
    
    MainViewController* vc = [[MainViewController alloc] init];
    
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [[UINavigationBar appearance] setBarTintColor:UIColor.blackColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"transparent.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];

    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];

    
    nc.navigationBar.hidden = YES;
    
    self.window.rootViewController = nc;
    
    [self.window makeKeyAndVisible];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
