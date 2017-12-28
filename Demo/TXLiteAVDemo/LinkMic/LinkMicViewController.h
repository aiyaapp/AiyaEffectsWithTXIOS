//
//  LinkMicViewController.h
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TXLivePush.h"
#import "StreamUrlScanner.h"
#import "BeautySettingPanel.h"

@interface LinkMicViewController : UIViewController
{
    BOOL _publish_switch;
    BOOL _log_switch;
    BOOL _camera_switch;


    
    UIButton*    _btnPublish;
    UIButton*    _btnCamera;
    UIButton*    _btnBeauty;
    UIButton*    _btnLog;
    UIButton*    _btnPushType;
    
    BeautySettingPanel* _vBeauty;
    
    TXLivePush * _txLivePublisher;
    
    UIView*             _cover;
    UITextView*         _statusView;
    UITextView*         _logViewEvt;
    unsigned long long  _startTime;
    unsigned long long  _lastTime;
    
    NSString*       _logMsg;
    NSString*       _tipsMsg;
    NSString*       _testPath;
    BOOL            _isPreviewing;
    
    StreamUrlScanner* _playUrlScanner;
}

@property (nonatomic, retain) UITextField* txtRtmpUrl;

@end
