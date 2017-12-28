//
//  BottomTabBar.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 视频编辑底栏
 */

@protocol BottomTabBarDelegate <NSObject>

- (void)onCutBtnClicked;
- (void)onFilterBtnClicked;
- (void)onMusicBtnClicked;
- (void)onTextBtnClicked;

@end

@interface BottomTabBar : UIView

@property (nonatomic, weak) id<BottomTabBarDelegate> delegate;

@end
