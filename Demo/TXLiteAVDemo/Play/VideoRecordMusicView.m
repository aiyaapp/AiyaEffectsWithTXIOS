//
//  VideoRecordMusicView.m
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/13.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "VideoRecordMusicView.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"

@implementation VideoRecordMusicView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

-(void)initUI{
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    
    //***
    //BGM
    UIButton *btnSelectBGM = [[UIButton alloc] initWithFrame:CGRectMake(10, 15, 50, 20)];
    btnSelectBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    btnSelectBGM.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;
    [btnSelectBGM.layer setMasksToBounds:YES];
    [btnSelectBGM.layer setCornerRadius:6];
    [btnSelectBGM.layer setBorderWidth:1.0];
    [btnSelectBGM setTitle:@"伴奏" forState:UIControlStateNormal];
    [btnSelectBGM setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [btnSelectBGM addTarget:self action:@selector(onBtnMusicSelected) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnStopBGM = [[UIButton alloc] initWithFrame:CGRectMake(btnSelectBGM.right + 10, 15, 50, 20)];
    btnStopBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    btnStopBGM.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;
    [btnStopBGM.layer setMasksToBounds:YES];
    [btnStopBGM.layer setCornerRadius:6];
    [btnStopBGM.layer setBorderWidth:1.0];
    [btnStopBGM setTitle:@"结束" forState:UIControlStateNormal];
    [btnStopBGM setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
    [btnStopBGM addTarget:self action:@selector(onBtnMusicStoped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *labVolumeForBGM = [[UILabel alloc] initWithFrame:CGRectMake(15, btnSelectBGM.bottom + 25, 30, 20)];
    [labVolumeForBGM setText:@"伴奏"];
    [labVolumeForBGM setFont:[UIFont systemFontOfSize:12.f]];
    labVolumeForBGM.textColor = UIColorFromRGB(0x0ACCAC);
    //    [_labVolumeForBGM sizeToFit];
    
    UISlider *sldVolumeForBGM = [[UISlider alloc] initWithFrame:CGRectMake(labVolumeForBGM.right + 40, labVolumeForBGM.y, 300, 20)];
    sldVolumeForBGM.minimumValue = 0;
    sldVolumeForBGM.maximumValue = 2;
    sldVolumeForBGM.value = 1;
    [sldVolumeForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [sldVolumeForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [sldVolumeForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [sldVolumeForBGM addTarget:self action:@selector(onBGMValueChange:) forControlEvents:UIControlEventValueChanged];
    
    UILabel *labVolumeForVoice = [[UILabel alloc] initWithFrame:CGRectMake(15, sldVolumeForBGM.bottom + 15, 30, 20)];
    [labVolumeForVoice setText:@"人声"];
    [labVolumeForVoice setFont:[UIFont systemFontOfSize:12.f]];
    labVolumeForVoice.textColor = UIColorFromRGB(0x0ACCAC);
    //    [_labVolumeForVoice sizeToFit];
    
    UISlider *sldVolumeForVoice = [[UISlider alloc] initWithFrame:CGRectMake(labVolumeForVoice.right + 40, labVolumeForVoice.y, 300, 20)];
    sldVolumeForVoice.minimumValue = 0;
    sldVolumeForVoice.maximumValue = 2;
    sldVolumeForVoice.value = 1;
    [sldVolumeForVoice setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [sldVolumeForVoice setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [sldVolumeForVoice setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [sldVolumeForVoice addTarget:self action:@selector(onVoiceValueChange:) forControlEvents:UIControlEventValueChanged];
    
    [self addSubview:btnSelectBGM];
    [self addSubview:btnStopBGM];
    [self addSubview:labVolumeForBGM];
    [self addSubview:sldVolumeForBGM];
    [self addSubview:labVolumeForVoice];
    [self addSubview:sldVolumeForVoice];
}

-(void)onBtnMusicSelected
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBtnMusicSelected)]) {
        [_delegate onBtnMusicSelected];
    }
}

-(void)onBtnMusicStoped
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBtnMusicStoped)]) {
        [_delegate onBtnMusicStoped];
    }
}

-(void)onBGMValueChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMValueChange:)]) {
        [_delegate onBGMValueChange:slider];
    }
}

-(void)onVoiceValueChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onVoiceValueChange:)]) {
        [_delegate onVoiceValueChange:slider];
    }
}
@end
