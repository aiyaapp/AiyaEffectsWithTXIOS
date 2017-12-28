//
//  VideoRangeSlider.h
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RangeContent.h"

/**
 视频缩略条拉条
 */

@protocol VideoRangeSliderDelegate;

@interface VideoRangeSlider : UIView

@property (weak) id<VideoRangeSliderDelegate> delegate;

@property (nonatomic) UIScrollView  *bgScrollView;
@property (nonatomic) UIImageView   *middleLine;
@property (nonatomic) RangeContentConfig* appearanceConfig;
@property (nonatomic) RangeContent *rangeContent;
@property (nonatomic) CGFloat        durationMs;
@property (nonatomic) CGFloat        currentPos;
@property (readonly)  CGFloat        leftPos;
@property (readonly)  CGFloat        rightPos;

- (void)setImageList:(NSArray *)images;
- (void)updateImage:(UIImage *)image atIndex:(NSUInteger)index;

@end


@protocol VideoRangeSliderDelegate <NSObject>
- (void)onVideoRangeLeftChanged:(VideoRangeSlider *)sender;
- (void)onVideoRangeLeftChangeEnded:(VideoRangeSlider *)sender;
- (void)onVideoRangeRightChanged:(VideoRangeSlider *)sender;
- (void)onVideoRangeRightChangeEnded:(VideoRangeSlider *)sender;
- (void)onVideoRangeLeftAndRightChanged:(VideoRangeSlider *)sender;
- (void)onVideoRange:(VideoRangeSlider *)sender seekToPos:(CGFloat)pos;
@end
