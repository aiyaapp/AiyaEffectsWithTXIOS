//
//  PublishController.m
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "PublishViewController.h"
#import "ScanQRController.h"
#import <Foundation/Foundation.h>
#import "TXLiveSDKTypeDef.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import "AppLogMgr.h"
//#import "TXUGCPublish.h"
#import "UIView+Additions.h"
#import <MediaPlayer/MediaPlayer.h>

#import "AFNetworkReachabilityManager.h"
#import "CWStatusBarNotification.h"
// 清晰度定义
#define    HD_LEVEL_720P       1  // 1280 * 720
#define    HD_LEVEL_540P       2  //  960 * 540
#define    HD_LEVEL_360P       3  //  640 * 360
#define    HD_LEVEL_360_PLUS   4  //  640 * 360 且开启码率自适应

//#define    UGC_ACTIVITY

//#define CUSTOM_PROCESS  //在自定义处理回调出来的画面纹理

#ifdef CUSTOM_PROCESS
#import "CustomProcessFilter.h"
#endif

#define RTMP_PUBLISH_URL    @"rtmp://120.25.237.18:1935/live/823"  //调试期间您可以修改之以避免输入地址的麻烦

//----------哎吖科技添加 开始----------
#import <AiyaEffectSDK/AiyaEffectSDK.h>
//----------哎吖科技添加 结束----------

//void testHookVideoFunc(unsigned char * yuv_buffer, int len_buffer, int width, int height)
//{
//    NSLog(@"hook video %p %d %d %d", yuv_buffer, len_buffer, width, height);

//    //比如：画面镜像(左右颠倒画面)
//    unsigned char * des_yuv = (unsigned char*)malloc(len_buffer);
//
//    int hw = width / 2;
//    int hh = height / 2;
//
//    int fs = width * height;
//    int qfs = fs*5/4;
//
//    for(int j=0; j<height; ++j)
//    {
//        for(int i=0; i<width; ++i)
//        {
//            des_yuv[j*width + i] = yuv_buffer[j*width + width - i - 1];
//
//            if(i<hw && j<hh)
//            {
//                des_yuv[fs + j*hw + i] = yuv_buffer[fs + j*hw + hw - i -1];
//                des_yuv[qfs + j*hw + i] = yuv_buffer[qfs + j*hw + hw - i -1];
//            }
//        }
//    }
//
//    memcpy(yuv_buffer, des_yuv, len_buffer);
//
//    free(des_yuv);
//}

//void testHookAudioFunc(unsigned char * pcm_buffer, int len_buffer, int sample_rate, int channels, int bit_size)
//{
//    NSLog(@"hook audio %p %d %d %d %d", pcm_buffer, len_buffer, sample_rate, channels, bit_size);

//    // 比如：静音
//    memset(pcm_buffer, 0, len_buffer);
//}

@implementation PushMusicInfo


@end


@interface PublishViewController () <
UITextFieldDelegate,
TXLivePushListener,
TXVideoCustomProcessDelegate,
BeautySettingPanelDelegate,
ScanQRDelegate
>

@property (nonatomic, strong) TXLivePush * txLivePublisher;
@property (nonatomic, copy)    NSString *pushUrl;


@end

@implementation PublishViewController {
    BOOL _appIsInterrupt;
    BOOL _appIsInActive;
    BOOL _appIsBackground;
    UIView *preViewContainer;
    UIDeviceOrientation _deviceOrientation;
//    TXUGCPublish      *_videoPublish;
//    TXRecordResult      *_recordResult;
    CWStatusBarNotification *_notification;
    
#ifdef CUSTOM_PROCESS
    CustomProcessFilter*    _filter;
    UIButton*               _btnSwitchCustom;
#endif
//----------哎吖科技添加 开始----------
    AYEffectHandler *effectHandler;
//----------哎吖科技添加 结束----------
}

- (PublishViewController *)init {
    if (self = [super init]) {
//        [TXUGCRecord shareInstance].recordDelegate = self;
        _isPlayBgm = NO;
        _appIsInterrupt = NO;
        _appIsInActive = NO;
        _appIsBackground = NO;
//----------哎吖科技添加 开始----------
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(licenseMessage:) name:AiyaLicenseNotification object:nil];
        [AYLicenseManager initLicense:@"61841d5e72c14f72a3f7a46a34f7eefe"];
//----------哎吖科技添加 结束----------
    }

    return self;
}

//----------哎吖科技添加 开始----------
- (void)licenseMessage:(NSNotification *)notifi{
    
    AiyaLicenseResult result = [notifi.userInfo[AiyaLicenseNotificationUserInfoKey] integerValue];
    switch (result) {
        case AiyaLicenseSuccess:
            NSLog(@"License 验证成功");
            break;
        case AiyaLicenseFail:
            NSLog(@"License 验证失败");
            break;
    }
}
//----------哎吖科技添加 结束----------

- (void)dealloc {
    [self stopRtmp];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _deviceOrientation = UIDeviceOrientationPortrait;

    TXLivePushConfig *_config = [[TXLivePushConfig alloc] init];
    //_config.watermark = [UIImage imageNamed:@"watermark.png"];
    //_config.watermarkPos = (CGPoint) {10, 10};
//    _config.frontCamera = NO;
    _txLivePublisher = [[TXLivePush alloc] initWithConfig:_config];

//    _videoPublish = [[TXUGCPublish alloc] init];
//    _videoPublish.delegate = self;

    [self initUI];
    [_vBeauty resetValues];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

}

- (void)handleInterruption:(NSNotification *)notification {
    AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (AVAudioSessionInterruptionTypeBegan == type) {
        _appIsInterrupt = YES;
        [_txLivePublisher pausePush];
        NSLog(@"AVAudioSessionInterruptionTypeBegan");
    }
    if (AVAudioSessionInterruptionTypeEnded == type) {
        _appIsInterrupt = NO;
        if (!_appIsBackground && !_appIsInActive && !_appIsInterrupt)
            [_txLivePublisher resumePush];
        NSLog(@"AVAudioSessionInterruptionTypeEnd");
 
    }
}

- (void)viewDidDisappear:(BOOL)animated; {
    [super viewDidDisappear:animated];
}

- (void)onAppWillResignActive:(NSNotification *)notification {
    _appIsInActive = YES;
    [_txLivePublisher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification *)notification {
    _appIsInActive = NO;
    if (!_appIsBackground && !_appIsInActive && !_appIsInterrupt)
        [_txLivePublisher resumePush];
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification {
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{

    }];

    _appIsBackground = YES;
    [_txLivePublisher pausePush];

}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    _appIsBackground = NO;
    if (!_appIsBackground && !_appIsInActive && !_appIsInterrupt) [_txLivePublisher resumePush];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];


#if !TARGET_IPHONE_SIMULATOR
    //是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
        return;
    }

//    if (!_isPreviewing) {
//        [_txLivePublisher startPreview:preViewContainer];
//        _isPreviewing = YES;
//    }
#endif

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_statusView setText:@""];
    [_logViewEvt setText:@""];
    _startTime = (unsigned long long int) ([[NSDate date] timeIntervalSince1970] * 1000);
    _lastTime = _startTime;
}

- (BOOL)startRtmp {
    [self clearLog];
    NSString *rtmpUrl = self.txtRtmpUrl.text;
    if (!([rtmpUrl hasPrefix:@"rtmp://"])) {
        rtmpUrl = RTMP_PUBLISH_URL;
    }
    if (!([rtmpUrl hasPrefix:@"rtmp://"])) {
        [self toastTip:@"推流地址不合法，目前支持rtmp推流!"];
        return NO;
    }

    //是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
        return NO;
    }

    //是否有麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusDenied) {
        [self toastTip:@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限"];
        return NO;
    }

    NSString *ver = [TXLiveBase getSDKVersionStr];
    _logMsg = [NSString stringWithFormat:@"liteav sdk version: %@", ver];
    [_logViewEvt setText:_logMsg];
    

    if (_txLivePublisher != nil) {

        TXLivePushConfig *_config = _txLivePublisher.config;
//        _config.watermark = [UIImage imageNamed:@"watermark.png"];
//        _config.watermarkPos = (CGPoint){0,0};

        //【示例代码1】设置自定义视频采集逻辑（自定义视频采集逻辑不要调用startPreview）
//        _config.customModeType |= CUSTOM_MODE_VIDEO_CAPTURE;
//        _config.videoResolution= VIDEO_RESOLUTION_TYPE_1280_720;
//        [[[NSThread alloc] initWithTarget:self
//                                 selector:@selector(customVideoCaptureThread)
//                                   object:nil] start];

        //【示例代码2】设置自定义音频采集逻辑（音频采样位宽必须是16）
//        _config.customModeType |= CUSTOM_MODE_AUDIO_CAPTURE;
//        _config.audioSampleRate = AUDIO_SAMPLE_RATE_44100;
//        _config.audioChannels   = 1;
//        [[[NSThread alloc] initWithTarget:self
//                                 selector:@selector(customAudioCaptureThread)
//                                   object:nil] start];

        // 【示例代码3】设置自定义音频预处理逻辑
//        _config.customModeType |= CUSTOM_MODE_AUDIO_PREPROCESS;
//        _config.pAudioFuncPtr = testHookAudioFunc;

        //【示例代码4】设置自定义视频预处理逻辑
//        _config.customModeType |= CUSTOM_MODE_VIDEO_PREPROCESS;
//        _config.pVideoFuncPtr = testHookVideoFunc;


        _config.pauseFps = 10;
        _config.pauseTime = 300;
        _config.pauseImg = [UIImage imageNamed:@"pause_publish.jpg"];
        _config.enableNearestIP = _enableNearestIP;
        [_txLivePublisher setConfig:_config];

        _txLivePublisher.delegate = self;
//#ifdef CUSTOM_PROCESS
       _txLivePublisher.videoProcessDelegate = self;
//#endif

#ifdef  UGC_ACTIVITY
        if (!_isPreviewing) {
            TXUGCCustomConfig *param = [[TXUGCCustomConfig alloc] init];
            param.videoResolution = _config.videoResolution;
            param.videoFPS = _config.videoFPS;
            param.videoBitratePIN = _config.videoBitratePIN;
            param.watermark = [UIImage imageNamed:@"watermark.png"];
            param.watermarkPos = (CGPoint){10, 10};
            [[TXUGCRecord shareInstance] startCameraCustom:param preview:preViewContainer];
            _isPreviewing = YES;
        }
#else
        if (!_isPreviewing) {
            [_txLivePublisher startPreview:preViewContainer];
            _isPreviewing = YES;
        }

        if ([_txLivePublisher startPush:rtmpUrl] != 0) {
            NSLog(@"推流器启动失败");
            return NO;
        }
#endif

//        [_txLivePublisher setBeautyFilterDepth:6.3 setWhiteningFilterDepth:2.7];

    }

    _pushUrl = rtmpUrl;

    [_vBeauty trigglerValues];
    return YES;
}


- (void)stopRtmp {
    _pushUrl = @"";
    if (_txLivePublisher != nil) {
        _txLivePublisher.delegate = nil;
        [_txLivePublisher stopPreview];
#ifdef  UGC_ACTIVITY
        [[TXUGCRecord shareInstance] stopCameraPreview];
#endif
        _isPreviewing = NO;
        [_txLivePublisher stopPush];
    }
//    [_vBeauty resetValues];
}

// RTMP 推流事件通知
#pragma - TXLivePushListener

- (void)appendLog:(NSString *)evt time:(NSDate *)date mills:(int)mil {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString *time = [format stringFromDate:date];
    NSString *log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log];
    [_logViewEvt setText:_logMsg];
}

- (void)onPushEvent:(int)EvtID withParam:(NSDictionary *)param; {
    NSDictionary *dict = param;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PUSH_ERR_NET_DISCONNECT) {
            [self clickPublish:_btnPublish];
        } else if (EvtID == PUSH_WARNING_HW_ACCELERATION_FAIL) {
            _txLivePublisher.config.enableHWAcceleration = false;
            [_btnHardware setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
        } else if (EvtID == PUSH_ERR_OPEN_CAMERA_FAIL) {
            [self stopRtmp];
            [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            _publish_switch = NO;
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
        } else if (EvtID == PUSH_ERR_OPEN_MIC_FAIL) {
            [self stopRtmp];
            [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            _publish_switch = NO;
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [self toastTip:@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限"];
        } else if (EvtID == PUSH_EVT_CONNECT_SUCC) {
            BOOL isWifi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
            if (!isWifi) {
                __weak __typeof(self) weakSelf = self;
                [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                    if (weakSelf.pushUrl.length == 0) {
                        return;
                    }
                    if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                                       message:@"您要切换到WiFi再推流吗?"
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
//                            [weakSelf stopRtmp];
//                            [weakSelf startRtmp];
                            [weakSelf.txLivePublisher stopPush];
                            [weakSelf.txLivePublisher startPush:weakSelf.pushUrl];
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [weakSelf presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
        } else if (EvtID == PUSH_WARNING_NET_BUSY) {
            [_notification displayNotificationWithMessage:@"您当前的网络环境不佳，请尽快更换网络保证正常直播" forDuration:5];
        }


        //NSLog(@"evt:%d,%@", EvtID, dict);
        long long time = [(NSNumber *) [dict valueForKey:EVT_TIME] longLongValue];
        int mil = (int) (time % 1000);
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time / 1000];
        NSString *Msg = (NSString *) [dict valueForKey:EVT_MSG];
        [self appendLog:Msg time:date mills:mil];
    });
}

- (void)onNetStatus:(NSDictionary *)param {
    NSDictionary *dict = param;

    NSString *streamID = [dict valueForKey:STREAM_ID];
    if (![streamID isEqualToString:_pushUrl]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        int netspeed = [(NSNumber *) [dict valueForKey:NET_STATUS_NET_SPEED] intValue];
        int vbitrate = [(NSNumber *) [dict valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
        int abitrate = [(NSNumber *) [dict valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
        int cachesize = [(NSNumber *) [dict valueForKey:NET_STATUS_CACHE_SIZE] intValue];
        int dropsize = [(NSNumber *) [dict valueForKey:NET_STATUS_DROP_SIZE] intValue];
        int jitter = [(NSNumber *) [dict valueForKey:NET_STATUS_NET_JITTER] intValue];
        int fps = [(NSNumber *) [dict valueForKey:NET_STATUS_VIDEO_FPS] intValue];
        int width = [(NSNumber *) [dict valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height = [(NSNumber *) [dict valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        float cpu_usage = [(NSNumber *) [dict valueForKey:NET_STATUS_CPU_USAGE] floatValue];
        float cpu_usage_ = [(NSNumber *) [dict valueForKey:NET_STATUS_CPU_USAGE_D] floatValue];
        int codecCacheSize = [(NSNumber *) [dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber *) [dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        int nSetVideoBitrate = [(NSNumber *) [dict valueForKey:NET_STATUS_SET_VIDEO_BITRATE] intValue];
        NSString *log = [NSString stringWithFormat:@"CPU:%.1f%%|%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nAVRA:%dkb/s\tSVR:%@",
                                                   cpu_usage_ * 100,
                                                   cpu_usage * 100,
                                                   width,
                                                   height,
                                                   netspeed,
                                                   jitter,
                                                   fps,
                                                   abitrate,
                                                   codecCacheSize,
                                                   cachesize,
                                                   nCodecDropCnt,
                                                   dropsize,
                                                   vbitrate,
                                                   nSetVideoBitrate,
                                                   serverIP];
        [_statusView setText:log];
        AppDemoLogOnlyFile(@"Current status, VideoBitrate:%d, AudioBitrate:%d, FPS:%d, RES:%d*%d, netspeed:%d", vbitrate, abitrate, fps, width, height, netspeed);

    });
}


#pragma - ui util

- (void)initUI {

    _notification = [CWStatusBarNotification new];
    _notification.notificationLabelBackgroundColor = [UIColor redColor];
    _notification.notificationLabelTextColor = [UIColor whiteColor];

    //主界面排版
    if (self.enableNearestIP) {
        self.title = @"推流+";
    }
    else {
        self.title = @"推流";
    }
    
//    self.view.backgroundColor = UIColor.blackColor;
    [self.view setBackgroundImage:[UIImage imageNamed:@"background.jpg"]];


    CGSize size = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = (int) (size.width / 10);

    _cover = [[UIView alloc] init];
    _cover.frame = CGRectMake(10.0f, 55 + 2 * ICON_SIZE, size.width - 20, size.height - 75 - 3 * ICON_SIZE);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha = 0.5;
    _cover.hidden = YES;
    [self.view addSubview:_cover];

    int logheadH = 65;
    _statusView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2 * ICON_SIZE, size.width - 20, logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self.view addSubview:_statusView];

    _logViewEvt = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2 * ICON_SIZE + logheadH, size.width - 20, size.height - 75 - 3 * ICON_SIZE - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self.view addSubview:_logViewEvt];

    self.txtRtmpUrl = [[UITextField alloc] initWithFrame:CGRectMake(10, 30 + ICON_SIZE + 10, size.width - 25 - ICON_SIZE, ICON_SIZE)];
    [self.txtRtmpUrl setBorderStyle:UITextBorderStyleRoundedRect];
    self.txtRtmpUrl.placeholder = RTMP_PUBLISH_URL;
    self.txtRtmpUrl.text = @"";
    self.txtRtmpUrl.background = [UIImage imageNamed:@"Input_box"];
    self.txtRtmpUrl.alpha = 0.5;
    self.txtRtmpUrl.autocapitalizationType = (UITextAutocapitalizationType) UITextAutocorrectionTypeNo;
    self.txtRtmpUrl.delegate = self;
    [self.view addSubview:self.txtRtmpUrl];


    UIButton *btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame = CGRectMake(size.width - 10 - ICON_SIZE, 30 + ICON_SIZE + 10, ICON_SIZE, ICON_SIZE);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self action:@selector(clickScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnScan];

    float startSpace = 12;
    float centerInterVal = (size.width - 2 * startSpace - ICON_SIZE) / 7;
    float iconY = size.height - ICON_SIZE / 2 - 10;

    int icon_length = 7;
    int icon_size = (int) (size.width / 10);
    int icon_gap = (int) ((size.width - icon_size * (icon_length - 1)) / icon_length);
    _btnRecordVideo = [self createBottomBtnIndexEx:0 Icon:@"start" Action:@selector(clickRecord) Gap:icon_gap Size:icon_size];
    _btnPublishVideo = [self createBottomBtnIndexEx:1 Icon:@"log" Action:@selector(clickPublish) Gap:icon_gap Size:icon_size];
    _btnRecordVideo.hidden = YES;
    _btnPublishVideo.hidden = YES;

    _labProgress = [[UILabel alloc] init];
    _labProgress.frame = CGRectMake(_btnPublishVideo.frame.origin.x + icon_size + 10, _btnPublishVideo.frame.origin.y, 50, 30);
    [_labProgress setText:@""];
    [_labProgress setTextColor:[UIColor blackColor]];
    _labProgress.hidden = YES;
    [self.view addSubview:_labProgress];

    //start or stop 按钮
    _publish_switch = NO;
    _btnPublish = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnPublish.center = CGPointMake(startSpace + ICON_SIZE / 2, iconY);
    _btnPublish.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [_btnPublish addTarget:self action:@selector(clickPublish:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnPublish];


    //前置后置摄像头切换
    _camera_switch = NO;
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal, iconY);
    _btnCamera.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(clickCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];
    
    //美颜开关按钮
    _btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 2, iconY);
    _btnBeauty.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnBeauty setImage:[UIImage imageNamed:@"beauty"] forState:UIControlStateNormal];
    [_btnBeauty addTarget:self action:@selector(clickBeauty:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBeauty];

    //硬件加速
    _hardware_switch = NO;
    _btnHardware = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnHardware.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 3, iconY);
    _btnHardware.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnHardware setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
    [_btnHardware addTarget:self action:@selector(clickHardware:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnHardware];

    //开启横屏推流
    _screenPortrait = NO;
    _btnScreenOrientation = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnScreenOrientation.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 4, iconY);
    _btnScreenOrientation.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnScreenOrientation setImage:[UIImage imageNamed:@"portrait"] forState:UIControlStateNormal];
    [_btnScreenOrientation addTarget:self action:@selector(clickScreenOrientation:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnScreenOrientation];

    //log显示或隐藏
    _log_switch = NO;
    _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnLog.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 5, iconY);
    _btnLog.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
    [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnLog];

    //清晰度按钮
    _btnResolution = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnResolution.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 6, iconY);
    _btnResolution.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnResolution setImage:[UIImage imageNamed:@"SD"] forState:UIControlStateNormal];
    [_btnResolution addTarget:self action:@selector(clickHD:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnResolution];

    //镜像按钮
    _isMirror = NO;
    _btnMirror = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnMirror.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 7, iconY);
    _btnMirror.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnMirror setTitle:@"镜像" forState:UIControlStateNormal];
    _btnMirror.titleLabel.font = [UIFont systemFontOfSize:15];
    [_btnMirror setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btnMirror setBackgroundColor:[UIColor whiteColor]];
    _btnMirror.layer.cornerRadius = _btnMirror.frame.size.width / 2;
    [_btnMirror setAlpha:0.5];
    [_btnMirror addTarget:self action:@selector(clickMirror:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnMirror];
    
    //BGM
    _btnBgm = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBgm.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 6, iconY-ICON_SIZE*2);
    _btnBgm.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnBgm setTitle:@"音乐" forState:UIControlStateNormal];
    _btnBgm.titleLabel.font = [UIFont systemFontOfSize:15];
    [_btnBgm setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btnBgm setBackgroundColor:[UIColor whiteColor]];
    _btnBgm.layer.cornerRadius = _btnBgm.frame.size.width / 2;
    [_btnBgm setAlpha:0.5];
    [_btnBgm addTarget:self action:@selector(clickBgm:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBgm];
    _btnBgm.hidden = YES;
    
#ifdef CUSTOM_PROCESS
    _btnSwitchCustom = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnSwitchCustom.center = CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 7, iconY-ICON_SIZE*2);
    _btnSwitchCustom.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnSwitchCustom setTitle:@"定制" forState:UIControlStateNormal];
    _btnSwitchCustom.titleLabel.font = [UIFont systemFontOfSize:15];
    [_btnSwitchCustom setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btnSwitchCustom setBackgroundColor:[UIColor whiteColor]];
    _btnSwitchCustom.layer.cornerRadius = _btnSwitchCustom.frame.size.width / 2;
    [_btnSwitchCustom setAlpha:0.5];
    [_btnSwitchCustom addTarget:self action:@selector(clickCustom:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSwitchCustom];
#endif
    
    NSUInteger controlHeight = [BeautySettingPanel getHeight];
    _vBeauty = [[BeautySettingPanel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - controlHeight, self.view.frame.size.width, controlHeight)];
    _vBeauty.hidden = YES;
    _vBeauty.delegate = self;
    [self.view addSubview:_vBeauty];

    // 清晰度选项: 720p - 640 - 640+ (此处使用了三个普通按钮来模拟单选框, 目的是跟android demo 保持界面风格一致)
    _vHD = [[UIControl alloc] init];
    _vHD.frame = CGRectMake(0, size.height - 120, size.width, 120);
    [_vHD setBackgroundColor:[UIColor whiteColor]];

    UILabel *txtHD = [[UILabel alloc] init];
    txtHD.frame = CGRectMake(0, 0, size.width, 50);
    [txtHD setText:@"清晰度"];
    txtHD.textAlignment = NSTextAlignmentCenter;
    [txtHD setFont:[UIFont fontWithName:@"" size:14]];

    [_vHD addSubview:txtHD];

    int gap = 30;
    int width = (int) ((size.width - gap * 3 - 20) / 4);
    _radioBtnHD = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnHD.frame = CGRectMake(10, 60, width, 40);
    [_radioBtnHD setTitle:@"720p" forState:UIControlStateNormal];
    [_radioBtnHD addTarget:self action:@selector(changeHD:) forControlEvents:UIControlEventTouchUpInside];

    _radioBtnHD2 = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnHD2.frame = CGRectMake(10 + gap + width, 60, width, 40);
    [_radioBtnHD2 setTitle:@"540p" forState:UIControlStateNormal];
    [_radioBtnHD2 addTarget:self action:@selector(changeHD:) forControlEvents:UIControlEventTouchUpInside];

    _radioBtnSD = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnSD.frame = CGRectMake(10 + (gap + width) * 2, 60, width, 40);
    [_radioBtnSD setTitle:@"360p" forState:UIControlStateNormal];
    [_radioBtnSD addTarget:self action:@selector(changeHD:) forControlEvents:UIControlEventTouchUpInside];

    _radioBtnAUTO = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnAUTO.frame = CGRectMake(size.width - 10 - width, 60, width, 40);
    [_radioBtnAUTO setTitle:@"360+" forState:UIControlStateNormal];
    [_radioBtnAUTO addTarget:self action:@selector(changeHD:) forControlEvents:UIControlEventTouchUpInside];

    [_vHD addSubview:_radioBtnHD];
    [_vHD addSubview:_radioBtnHD2];
    [_vHD addSubview:_radioBtnSD];
    [_vHD addSubview:_radioBtnAUTO];

    _vHD.hidden = YES;
    [self.view addSubview:_vHD];

    // DEMO 默认采用 540 * 960 的分辨率
    _hd_level = HD_LEVEL_540P;
    [self setHDUI:_hd_level];
    [self changeHD:_radioBtnHD2];

#if TARGET_IPHONE_SIMULATOR
    [self toastTip:@"iOS模拟器不支持推流和播放，请使用真机体验"];
#endif

    CGRect previewFrame = self.view.bounds;
    preViewContainer = [[UIView alloc] initWithFrame:previewFrame];

    [self.view insertSubview:preViewContainer atIndex:0];
    preViewContainer.center = self.view.center;
}

- (UIButton *)createBottomBtnIndexEx:(int)index Icon:(NSString *)icon Action:(SEL)action Gap:(int)gap Size:(int)size {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index + 1) * gap + index * size, [[UIScreen mainScreen] bounds].size.height - 2 * (size + 10), size, size);
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}


- (void)clickRecord {
#ifdef  UGC_ACTIVITY
    _recordStart = !_recordStart;
    _btnRecordVideo.selected = NO;
    if (!_recordStart) {
        [_btnRecordVideo setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _labProgress.text = @"";
        [[TXUGCRecord shareInstance] stopRecord];

        _publishParam = [[TXPublishParam alloc] init];
    } else {
        [_btnRecordVideo setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];

        [[TXUGCRecord shareInstance] startRecord];
        _publishParam = nil;
    }
#endif
}

- (void)clickPublish {
#ifdef  UGC_ACTIVITY
    NSError* error;
    NSDictionary* dictParam = @{@"Action" : @"GetVodSignature"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictParam options:0 error:&error];

    NSMutableString *strUrl = [[NSMutableString alloc] initWithString:@"https://livedemo.tim.qq.com/interface.php"];

    NSURL *URL = [NSURL URLWithString:strUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];

    if (data)
    {
        [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

        [request setHTTPBody:data];
    }

    [request setTimeoutInterval:30];


    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err = nil;
        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&err];

        int errCode = -1;
        NSDictionary* dataDict = nil;
        if (resultDict)
        {
            if (resultDict[@"returnValue"]) {
                errCode = [resultDict[@"returnValue"] intValue];
            }

            if (0 == errCode && resultDict[@"returnData"]) {
                dataDict = resultDict[@"returnData"];
            }
        }

        if (dataDict && _publishParam && _videoPublish) {
            _publishParam.signature  = dataDict[@"signature"];
            _publishParam.coverImage = _recordResult.coverImage;
            _publishParam.videoPath  = _recordResult.videoPath;
            [_videoPublish publishVideo:_publishParam];
        }
    }];

    [task resume];
#endif
}


#pragma mark - TXVideoRecordListener
//-(void) onRecordProgress:(NSInteger)milliSecond
//{
//    int progress = (int)milliSecond/1000;
//    _labProgress.text = [NSString stringWithFormat:@"%d", progress];
//}
//
//-(void) onRecordComplete:(TXRecordResult*)result
//{
//    _recordResult = result;
//}
//
//-(void) onPublishProgress:(NSInteger)uploadBytes totalBytes: (NSInteger)totalBytes
//{
//    _labProgress.text = [NSString stringWithFormat:@"%02d%%", (int)(totalBytes*100/totalBytes)];
//}
//
//-(void) onPublishComplete:(TXPublishResult*)result
//{
//    if (!result.retCode) {
//        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//
//        if (result.videoURL == nil) {
//            [self toastTip:@"发布失败！请检查发布的流程是否正常"];
//        }else{
//            [pasteboard setString:result.videoURL];
//            [self toastTip:@"发布成功啦！播放地址已经复制到粘贴板"];
//        }
//        _labProgress.text = @"";
//
//    } else {
//        [self toastTip:[NSString stringWithFormat:@"发布失败啦![%d]", result.retCode]];
//    }
//}

#pragma mark - ScanQRDelegate

- (void)onScanResult:(NSString *)result {
    self.txtRtmpUrl.text = result;
}


- (void)setHDUI:(int)level {
    switch (level) {
        case HD_LEVEL_720P:
            [_radioBtnHD setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnHD2 setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnHD2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_btnResolution setImage:[UIImage imageNamed:@"HD"] forState:UIControlStateNormal];
            break;
        case HD_LEVEL_540P:
            [_radioBtnHD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD2 setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnSD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnHD2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnSD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_btnResolution setImage:[UIImage imageNamed:@"HD"] forState:UIControlStateNormal];
            break;
        case HD_LEVEL_360P:
            [_radioBtnHD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD2 setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSD setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnHD2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSD setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_btnResolution setImage:[UIImage imageNamed:@"SD"] forState:UIControlStateNormal];

            break;
        case HD_LEVEL_360_PLUS:
            [_radioBtnHD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnHD2 setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSD setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnHD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnHD2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSD setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_btnResolution setImage:[UIImage imageNamed:@"PU"] forState:UIControlStateNormal];
        default:
            break;
    }
}

- (void)clickScan:(UIButton *)btn {
    [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    _publish_switch = NO;
    [self stopRtmp];
    ScanQRController *vc = [[ScanQRController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:NO];
}

- (void)clickPublish:(UIButton *)btn {
    //-[UIApplication setIdleTimerDisabled:]用于控制自动锁屏，SDK内部并无修改系统锁屏的逻辑
    if (_publish_switch) {
        [self stopRtmp];
        [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _publish_switch = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

        [_btnRecordVideo setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _labProgress.text = @"";
    } else {
        if (![self startRtmp]) {
            return;
        }
        [_btnPublish setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _publish_switch = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}


- (void)clickCamera:(UIButton *)btn {
    _camera_switch = !_camera_switch;

    [btn setImage:[UIImage imageNamed:(_camera_switch ? @"camera2" : @"camera")] forState:UIControlStateNormal];
    [_txLivePublisher switchCamera];
//    [[TXUGCRecord shareInstance] switchCamera:_camera_switch];
}

- (void)clickBeauty:(UIButton *)btn {
    _vBeauty.hidden = NO;
    [self hideToolButtons:YES];
}

- (void)hideToolButtons:(BOOL)bHide
{
    _btnPublish.hidden = bHide;
    _btnCamera.hidden = bHide;
    _btnBeauty.hidden = bHide;
    _btnHardware.hidden = bHide;
    _btnLog.hidden = bHide;
    _btnResolution.hidden = bHide;
    _btnScreenOrientation.hidden = bHide;
    _btnMirror.hidden = bHide;
    _radioBtnHD.hidden = bHide;
    _radioBtnHD2.hidden = bHide;
    _radioBtnSD.hidden = bHide;
    _radioBtnAUTO.hidden = bHide;
}

/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo {
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView *toastView = [[UITextView alloc] init];

    toastView.editable = NO;
    toastView.selectable = NO;

    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];

    toastView.frame = frameRC;

    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;

    [self.view addSubview:toastView];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);

    dispatch_after(popTime, dispatch_get_main_queue(), ^() {
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

- (void)clickHardware:(UIButton *)btn {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self toastTip:@"iOS 版本低于8.0，不支持硬件加速."];
        return;
    }

    if (_txLivePublisher != nil) {
        TXLivePushConfig *configTmp = _txLivePublisher.config;
        if (!configTmp.enableHWAcceleration) {
            NSString *strTip = @"iOS SDK启用硬件加速.";
            if (_publish_switch) {
                strTip = @"iOS SDK启用硬件加速，切换后会重新开始推流";
            }

            [self toastTip:strTip];
            configTmp.enableHWAcceleration = YES;
            [btn setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
        } else {
            NSString *strTip = @"iOS SDK停止硬件加速.";
            if (_publish_switch) {
                strTip = @"iOS SDK停止硬件加速，切换后会重新开始推流";
            }

            [self toastTip:strTip];
            configTmp.enableHWAcceleration = NO;
            [btn setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
        }
        _txLivePublisher.config = configTmp;
    }
}

- (void)clickMirror:(UIButton *)btn {
    _isMirror = !_isMirror;
    [_txLivePublisher setMirror:_isMirror];

    if (_isMirror) {
        [_btnMirror setAlpha:1];
    } else {
        [_btnMirror setAlpha:0.5];
    }
}

- (void)clickBgm:(UIButton *)btn {
    _isPlayBgm = !_isPlayBgm;
    if (_isPlayBgm) {
        //创建播放器控制器
        MPMediaPickerController *mpc = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
        mpc.delegate = self;
        mpc.editing = YES;
        [self presentViewController:mpc animated:YES completion:nil];
    } else {
        [_txLivePublisher stopBGM];
    }
}

- (void)clickCustom:(UIButton*)btn
{
    if (_txLivePublisher.videoProcessDelegate != nil) {
        _txLivePublisher.videoProcessDelegate = nil;
    }
    else {
        _txLivePublisher.videoProcessDelegate = self;
    }
}

- (void)clickLog:(UIButton *)btn {
    if (_log_switch) {
        _statusView.hidden = YES;
        _logViewEvt.hidden = YES;
        [btn setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _cover.hidden = YES;
        _log_switch = NO;
    } else {
        _statusView.hidden = NO;
        _logViewEvt.hidden = NO;
        [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _cover.hidden = NO;
        _log_switch = YES;
    }

}

- (void)clickScreenOrientation:(UIButton *)btn {
    _screenPortrait = !_screenPortrait;

    if (_screenPortrait) {
        //activity竖屏模式，home在右横屏推流
        [btn setImage:[UIImage imageNamed:@"landscape"] forState:UIControlStateNormal];
        TXLivePushConfig *_config = _txLivePublisher.config;
        _config.homeOrientation = HOME_ORIENTATION_RIGHT;
        [_txLivePublisher setConfig:_config];
        [_txLivePublisher setRenderRotation:90];

        //activity竖屏模式，home在左横屏推流
//        [btn setImage:[UIImage imageNamed:@"landscape"] forState:UIControlStateNormal];
//        TXLivePushConfig* _config = _txLivePublisher.config;
//        _config.homeOrientation = HOME_ORIENTATION_LEFT;
//        [_txLivePublisher setConfig:_config];
//        [_txLivePublisher setRenderRotation:270];

    } else {
        //activity竖屏模式，竖屏推流
        [btn setImage:[UIImage imageNamed:@"portrait"] forState:UIControlStateNormal];
        TXLivePushConfig *_config = _txLivePublisher.config;
        _config.homeOrientation = HOME_ORIENTATION_DOWN;
        [_txLivePublisher setConfig:_config];
        [_txLivePublisher setRenderRotation:0];
    }
}


- (void)statusBarOrientationChanged:(NSNotification *)note {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:        //activity竖屏模式，竖屏推流
        {
            if (_deviceOrientation != UIDeviceOrientationPortrait) {
                TXLivePushConfig *_config = _txLivePublisher.config;
                _config.homeOrientation = HOME_ORIENTATION_DOWN;
                [_txLivePublisher setConfig:_config];
                [_txLivePublisher setRenderRotation:0];
                _deviceOrientation = UIDeviceOrientationPortrait;
            }
        }
            break;
        case UIDeviceOrientationLandscapeLeft:   //activity横屏模式，home在右横屏推流 注意：渲染view（demo里面是：preViewContainer）要跟着activity旋转
        {
            if (_deviceOrientation != UIDeviceOrientationLandscapeLeft) {
                TXLivePushConfig *_config = _txLivePublisher.config;
                _config.homeOrientation = HOME_ORIENTATION_RIGHT;
                [_txLivePublisher setConfig:_config];
                [_txLivePublisher setRenderRotation:0];
                _deviceOrientation = UIDeviceOrientationLandscapeLeft;
            }

        }
            break;
        case UIDeviceOrientationLandscapeRight:   //activity横屏模式，home在左横屏推流 注意：渲染view（demo里面是：preViewContainer）要跟着activity旋转
        {
            if (_deviceOrientation != UIDeviceOrientationLandscapeRight) {
                TXLivePushConfig *_config = _txLivePublisher.config;
                _config.homeOrientation = HOME_ORIENTATION_LEFT;
                [_txLivePublisher setConfig:_config];
                [_txLivePublisher setRenderRotation:0];
                _deviceOrientation = UIDeviceOrientationLandscapeRight;
            }
        }
            break;
        default:
            break;
    }
}

- (void)clickHD:(UIButton *)btn {
    _vHD.hidden = NO;
}

- (void)changeHD:(UIButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"720p"] && ![self isSuitableMachine:7]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"直播推流"
                                                        message:@"iphone 6 及以上机型适合开启720p!"
                                                       delegate:nil
                                              cancelButtonTitle:@"确认"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    if ([btn.titleLabel.text isEqualToString:@"540p"] && ![self isSuitableMachine:5]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"直播推流"
                                                        message:@"iphone 5 及以上机型适合开启540p!"
                                                       delegate:nil
                                              cancelButtonTitle:@"确认"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    if (_txLivePublisher == nil) return;

//    if (_publish_switch == YES) {
//        [self stopRtmp];
//    }

    if ([btn.titleLabel.text isEqualToString:@"720p"]) {
        _hd_level = HD_LEVEL_720P;
        [_txLivePublisher setVideoQuality:VIDEO_QUALITY_SUPER_DEFINITION adjustBitrate:NO adjustResolution:NO];
    } else if ([btn.titleLabel.text isEqualToString:@"540p"]) {
        _hd_level = HD_LEVEL_540P;
        [_txLivePublisher setVideoQuality:VIDEO_QUALITY_HIGH_DEFINITION adjustBitrate:NO adjustResolution:NO];
    } else if ([btn.titleLabel.text isEqualToString:@"360p"]) {
        _hd_level = HD_LEVEL_360P;
        [_txLivePublisher setVideoQuality:VIDEO_QUALITY_STANDARD_DEFINITION adjustBitrate:YES adjustResolution:YES];

    } else if ([btn.titleLabel.text isEqualToString:@"360+"]) {
        _hd_level = HD_LEVEL_360_PLUS;
        [_txLivePublisher setVideoQuality:VIDEO_QUALITY_STANDARD_DEFINITION
                            adjustBitrate:YES adjustResolution:YES];
    }

    TXLivePushConfig *configTmp = _txLivePublisher.config;
    if (!configTmp.enableHWAcceleration) {
        [_btnHardware setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
    } else {
        [_btnHardware setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
    }

    [self setHDUI:_hd_level];
    _vHD.hidden = YES;
}


// iphone 6 及以上机型适合开启720p, 否则20帧的帧率可能无法达到, 这种"流畅不足,清晰有余"的效果并不好
- (BOOL)isSuitableMachine:(int)targetPlatNum {
    int mib[2] = {CTL_HW, HW_MACHINE};
    size_t len = 0;
    char *machine;

    sysctl(mib, 2, NULL, &len, NULL, 0);

    machine = (char *) malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);

    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    if ([platform length] > 6) {
        NSString *platNum = [NSString stringWithFormat:@"%C", [platform characterAtIndex:6]];
        return ([platNum intValue] >= targetPlatNum);
    } else {
        return NO;
    }

}

#pragma mark - BeautySettingPanelDelegate
- (void)onSetBeautyStyle:(int)beautyStyle beautyLevel:(float)beautyLevel whitenessLevel:(float)whitenessLevel ruddinessLevel:(float)ruddinessLevel{
    [_txLivePublisher setBeautyStyle:beautyStyle beautyLevel:beautyLevel whitenessLevel:whitenessLevel ruddinessLevel:ruddinessLevel];
}

- (void)onSetEyeScaleLevel:(float)eyeScaleLevel {
    [_txLivePublisher setEyeScaleLevel:eyeScaleLevel];
}

- (void)onSetFaceScaleLevel:(float)faceScaleLevel {
    [_txLivePublisher setFaceScaleLevel:faceScaleLevel];
}

- (void)onSetFilter:(UIImage *)filterImage {
    [_txLivePublisher setFilter:filterImage];
}


- (void)onSetGreenScreenFile:(NSURL *)file {
    [_txLivePublisher setGreenScreenFile:file];
}

- (void)onSelectMotionTmpl:(NSString *)tmplName inDir:(NSString *)tmplDir {
    [_txLivePublisher selectMotionTmpl:tmplName inDir:tmplDir];
}

- (void)onSetFaceVLevel:(float)vLevel{
    [_txLivePublisher setFaceVLevel:vLevel];
}

- (void)onSetFaceShortLevel:(float)shortLevel{
    [_txLivePublisher setFaceShortLevel:shortLevel];
}

- (void)onSetNoseSlimLevel:(float)slimLevel{
    [_txLivePublisher setNoseSlimLevel:slimLevel];
}

- (void)onSetChinLevel:(float)chinLevel{
    [_txLivePublisher setChinLevel:chinLevel];
}

- (void)onSetMixLevel:(float)mixLevel{
    [_txLivePublisher setSpecialRatio:mixLevel / 10.0];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.txtRtmpUrl resignFirstResponder];
    _vHD.hidden = YES;
    _vBeauty.hidden = YES;
    [self hideToolButtons:NO];
}

//#ifdef CUSTOM_PROCESS
//////////////////////////////////// GPU 自定义处理 ////////////////////////////////////
- (GLuint)onPreProcessTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height
{
    NSLog(@"custom %d, %f, %f", texture, width, height);
    
//----------哎吖科技添加 开始----------
    if (!effectHandler) {
        effectHandler = [[AYEffectHandler alloc] init];
        effectHandler.slimFace = 0.2;
        effectHandler.bigEye = 0.2;
        effectHandler.effectPath = [[NSBundle mainBundle] pathForResource:@"meta" ofType:@"json" inDirectory:@"gougou"];
    }

    [effectHandler processWithTexture:texture width:width height:height];
    glFlush(); // 因为腾讯云使用的是共享纹理, 所以此行必须要加上
//----------哎吖科技添加 结束----------

    return texture;

//    if (_filter == nil) {
//        _filter = [[CustomProcessFilter alloc] init];
//    }
//    return [_filter renderToTextureWithSize:CGSizeMake(width, height) sourceTexture:texture];
}

- (void)onTextureDestoryed
{
    NSLog(@"onTextureDestoryed");
    
//----------哎吖科技添加 开始----------
    effectHandler = nil;
//----------哎吖科技添加 结束----------

//    [_filter destroyFramebuffer];
//    _filter = nil;
}

- (void)onDetectFacePoints:(NSArray *)points
{
    NSLog(@"%lu", (unsigned long)points.count);
}
//#endif

#pragma mark - bgm

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSArray *items = mediaItemCollection.items;
    MPMediaItem *songItem = [items objectAtIndex:0];
    
    NSURL *url = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSString* songName = [songItem valueForProperty: MPMediaItemPropertyTitle];
    NSString* authorName = [songItem valueForProperty:MPMediaItemPropertyArtist];
    NSNumber* duration = [songItem valueForKey:MPMediaItemPropertyPlaybackDuration];
    NSLog(@"MPMediaItemPropertyAssetURL = %@", url);
    
    PushMusicInfo* musicInfo = [PushMusicInfo new];
    musicInfo.duration = duration.floatValue;
    musicInfo.soneName = songName;
    musicInfo.singerName = authorName;
    
    if (mediaPicker.editing) {
        mediaPicker.editing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveAssetURLToFile:musicInfo assetURL:url];
        });
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// 将AssetURL(音乐)导出到app的文件夹并播放
- (void)saveAssetURLToFile:(PushMusicInfo*)musicInfo assetURL:(NSURL*)assetURL
{
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
    NSLog (@"created exporter. supportedFileTypes: %@", exporter.supportedFileTypes);
    exporter.outputFileType = @"com.apple.m4a-audio";
    
    [AVAssetExportSession exportPresetsCompatibleWithAsset:songAsset];
    NSString *docDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LocalMusics/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:docDir]) {
        [fileManager createDirectoryAtPath:docDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    //    NSString *exportFilePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.m4a", musicInfo.soneName, musicInfo.singerName]];
    NSString *exportFilePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.m4a", musicInfo.soneName, musicInfo.singerName]];
    
    exporter.outputURL = [NSURL fileURLWithPath:exportFilePath];
    musicInfo.filePath = exportFilePath;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportFilePath]) {
        [_txLivePublisher playBGM:musicInfo.filePath withBeginNotify:^(NSInteger errCode) {
            NSLog(@"start bgm with err %ld", (long)errCode);
        } withProgressNotify:^(NSInteger progressMS, NSInteger durationMS) {
            NSLog(@"bgm play progress %ld|%ld", progressMS, durationMS);
        } andCompleteNotify:^(NSInteger errCode) {
            NSLog(@"bgm play complete %ld", errCode);
        }];
        return;
    }
    
    //    MBProgressHUD* hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //    hub.label.text = @"音频读取中...";
    
    
    
    // do the export
    //__weak typeof(self) weakSelf = self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed: {
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exporter.error);
                break;
                
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"AVAssetExportSessionStatusCompleted: %@", exporter.outputURL);
                
                // 播放背景音乐
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_txLivePublisher playBGM:musicInfo.filePath withBeginNotify:^(NSInteger errCode) {
                        NSLog(@"start bgm with err %ld", (long)errCode);
                    } withProgressNotify:^(NSInteger progressMS, NSInteger durationMS) {
                        NSLog(@"bgm play progress %ld|%ld", progressMS, durationMS);
                    } andCompleteNotify:^(NSInteger errCode) {
                        NSLog(@"bgm play complete %ld", errCode);
                    }];
                });
                break;
            }
            case AVAssetExportSessionStatusUnknown: { NSLog (@"AVAssetExportSessionStatusUnknown"); break;}
            case AVAssetExportSessionStatusExporting: { NSLog (@"AVAssetExportSessionStatusExporting"); break;}
            case AVAssetExportSessionStatusCancelled: { NSLog (@"AVAssetExportSessionStatusCancelled"); break;}
            case AVAssetExportSessionStatusWaiting: { NSLog (@"AVAssetExportSessionStatusWaiting"); break;}
            default: { NSLog (@"didn't get export status"); break;}
        }
    }];
    
    _isPlayBgm = YES;
}

//点击取消时回调
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
