//
//  VideoTextFiled.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/22.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VideoTextFiled;

/**
 字幕输入view，进行文字输入，拖动，放大，旋转等
 */

@protocol VideoTextFieldDelegate <NSObject>

- (void)onTextInputDone:(NSString*)text;
- (void)onRemoveTextField:(VideoTextFiled*)textField;

@end

@interface VideoTextFiled : UIView

@property (nonatomic, weak) id<VideoTextFieldDelegate> delegate;
@property (nonatomic, copy, readonly) NSString* text;
@property (nonatomic, readonly) UIImage* textImage;             //生成字幕image

- (CGRect)textFrameOnView:(UIView*)view;

//关闭键盘
- (void)resignFirstResponser;

@end
