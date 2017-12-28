//
//  VideoCutView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoRangeSlider.h"

/**
 视频编辑的裁剪view
 */

@protocol VideoCutViewDelegate <NSObject>

- (void)onVideoLeftCutChanged:(VideoRangeSlider*)sender;
- (void)onVideoRightCutChanged:(VideoRangeSlider*)sender;
- (void)onVideoCutChangedEnd:(VideoRangeSlider*)sender;
- (void)onVideoCutChange:(VideoRangeSlider*)sender seekToPos:(CGFloat)pos;

- (void)onSetSpeedUp:(BOOL)isSpeedUp;
- (void)onSetSpeedUpLevel:(CGFloat)level;

@end

@interface VideoCutView : UIView

@property (nonatomic, strong)  VideoRangeSlider *videoRangeSlider;  //缩略图条
@property (nonatomic, weak) id<VideoCutViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame videoPath:(NSString*)videoPath;
- (void)setPlayTime:(CGFloat)time;

@end
