//
//  LinkMicViewController.m
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//
#import "ScanQRController.h"
#import "LinkMicViewController.h"
#import <Foundation/Foundation.h>
#import "TXLiveSDKTypeDef.h"
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import "LinkMicPlayItem.h"
#import "CWStatusBarNotification.h"
#import "UIView+Additions.h"
#import "TXLiveBase.h"
#define RTMP_PUBLISH_URL    @"请输入或扫二维码获取推流地址"

@interface LinkMicViewController ()<
UITextFieldDelegate,
TXLivePushListener,
StreamUrlScannerDelegate,
BeautySettingPanelDelegate,
ScanQRDelegate
>

@end

@implementation LinkMicViewController
{
    BOOL                _isMainPublisher;
    BOOL                _appIsInterrupt;
    UIView *            _videoPreview;
    NSString *          _strPublisUrl;
    NSMutableArray*     _arrayPlayItems;
    CWStatusBarNotification *_notification;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
#if !TARGET_IPHONE_SIMULATOR
    //是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
        return;
    }
#endif
    [_txLivePublisher resumePush];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated;
{
    [super viewDidDisappear:animated];
    [_txLivePublisher pausePush];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)onAppWillResignActive:(NSNotification*)notification
{
    [_txLivePublisher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification*)notification
{
    [_txLivePublisher resumePush];
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification
{
    NSLog(@"onAppDidEnterBackGround");
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    [_txLivePublisher pausePush];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification
{
    NSLog(@"onAppWillEnterForeground");
    [_txLivePublisher resumePush];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self stopAll];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isMainPublisher = YES;
    _arrayPlayItems = [NSMutableArray new];
    
    TXLivePushConfig* _config = [[TXLivePushConfig alloc] init];
    _config.frontCamera = YES;
    _txLivePublisher = [[TXLivePush alloc] initWithConfig:_config];
    
    [self initUI];
    [_vBeauty resetValues];
}

#pragma mark - initUI
-(void) initUI
{
    _notification = [CWStatusBarNotification new];
    _notification.notificationLabelBackgroundColor = [UIColor redColor];
    _notification.notificationLabelTextColor = [UIColor whiteColor];
    //主界面排版
    self.title = @"连麦演示";
    
//    self.view.backgroundColor = UIColor.blackColor;
    [self.view setBackgroundImage:[UIImage imageNamed:@"background.jpg"]];

    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = size.width / 10;
    
    [self initLogView];
    
    UIButton* btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame = CGRectMake(size.width - 10 - ICON_SIZE - (5 + ICON_SIZE) * 1, 30 + ICON_SIZE + 10, ICON_SIZE, ICON_SIZE);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self action:@selector(clickScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnScan];
    
    UIButton* btnAdd = [UIButton buttonWithType:UIButtonTypeCustom];
    btnAdd.frame = CGRectMake(size.width - 10 - ICON_SIZE, 30 + ICON_SIZE + 10, ICON_SIZE, ICON_SIZE);
    [btnAdd setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [btnAdd addTarget:self action:@selector(clickAdd:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnAdd];

    self.txtRtmpUrl = [[UITextField alloc] initWithFrame:CGRectMake(10, 30 + ICON_SIZE + 10, size.width - 20 - (5 + ICON_SIZE) * 2, ICON_SIZE)];
    [self.txtRtmpUrl setBorderStyle:UITextBorderStyleRoundedRect];
    self.txtRtmpUrl.placeholder = RTMP_PUBLISH_URL;
    self.txtRtmpUrl.background = [UIImage imageNamed:@"Input_box"];
    self.txtRtmpUrl.alpha = 0.5;
    self.txtRtmpUrl.autocapitalizationType = UITextAutocorrectionTypeNo;
    self.txtRtmpUrl.delegate = self;
    self.txtRtmpUrl.text = @"";
    [self.view addSubview:self.txtRtmpUrl];
    
    float startSpace = 12;
    float centerInterVal = (size.width - 2*startSpace - ICON_SIZE) / 4;
    float iconY = size.height - ICON_SIZE/2 - 10;
    
    //start or stop 按钮
    _publish_switch = NO;
    _btnPublish = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnPublish.center = CGPointMake(startSpace + ICON_SIZE/2, iconY);
    _btnPublish.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [_btnPublish addTarget:self action:@selector(clickPublish:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnPublish];
    
    //前置后置摄像头切换
    _camera_switch = NO;
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 1, iconY);
    _btnCamera.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(clickCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];
    
    //美颜开关按钮
    _btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 2, iconY);
    _btnBeauty.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnBeauty setImage:[UIImage imageNamed:@"beauty"] forState:UIControlStateNormal];
    [_btnBeauty addTarget:self action:@selector(clickBeauty:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBeauty];
    
    //美颜设置区域
    NSUInteger controlHeight = [BeautySettingPanel getHeight];
    _vBeauty = [[BeautySettingPanel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - controlHeight, self.view.frame.size.width, controlHeight)];
    _vBeauty.delegate = self;
    _vBeauty.hidden = YES;
    [self.view addSubview: _vBeauty];
    
    //log显示或隐藏
    _log_switch = NO;
    _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnLog.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 3, iconY);
    _btnLog.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
    [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnLog];
    
    //主播类型
    _btnPushType = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnPushType.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 4, iconY);
    _btnPushType.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnPushType setImage:[UIImage imageNamed:@"mainpusher"] forState:UIControlStateNormal];
    [_btnPushType addTarget:self action:@selector(clickPushType:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnPushType];

#if TARGET_IPHONE_SIMULATOR
    [self toastTip:@"iOS模拟器不支持推流和播放，请使用真机体验"];
#endif
    
    CGRect previewFrame = self.view.bounds;
    _videoPreview = [[UIView alloc] initWithFrame:previewFrame];
    [self.view insertSubview:_videoPreview atIndex:0];
    
    //拉流播放UI初始化
    [self initPlayItem:0];
    [self initPlayItem:1];
    [self initPlayItem:2];
}

-(void) initLogView
{
    CGSize size = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = size.width / 10;
    
    _cover = [[UIView alloc]init];
    _cover.frame  = CGRectMake(10.0f, 55 + 2*ICON_SIZE, size.width - 20, size.height - 75 - 3 * ICON_SIZE);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha  = 0.5;
    _cover.hidden = YES;
    [self.view addSubview:_cover];
    
    int logheadH = 65;
    _statusView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*ICON_SIZE, size.width - 20,  logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self.view addSubview:_statusView];
    
    _logViewEvt = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*ICON_SIZE + logheadH, size.width - 20, size.height - 75 - 3 * ICON_SIZE - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self.view addSubview:_logViewEvt];
}

-(void) initPlayItem: (int)index
{
    int width = self.view.bounds.size.width / 3 - 10;
    int height = width / 3 * 4;
    UIView * videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [self.view addSubview:videoView];
    if (index == 0 || index == 1)
    {
        videoView.center = CGPointMake(self.view.bounds.size.width * (5 - index * 2) / 6, CGRectGetMinY(_btnPublish.frame) - 10 - height / 2);
    }
    else
    {
        videoView.center = CGPointMake(self.view.bounds.size.width * 5 / 6, CGRectGetMinY(_btnPublish.frame) - 10 - height / 2- height - 10);
    }

    LinkMicPlayItem * playItem = [[LinkMicPlayItem alloc] init];
    playItem.videoView = videoView;
    [_arrayPlayItems addObject:playItem];
}

#pragma mark - button click event
-(void) clickAdd:(UIButton*) btn
{
    if (_playUrlScanner == nil) {
        _playUrlScanner = [[StreamUrlScanner alloc] initWithFrame:self.view.frame];
        _playUrlScanner.delegate = self;
        _playUrlScanner.hostViewController = self;
        [self.view addSubview:_playUrlScanner];
    }
    
    BOOL hasFreePlay = NO;
    for (LinkMicPlayItem * item in _arrayPlayItems) {
        if (item.running == NO) {
            hasFreePlay = YES;
        }
    }
    
    if (hasFreePlay) {
        _playUrlScanner.hidden = NO;
    }
    else {
        [self toastTip:@"播放器数目已达上限"];
    }
}

-(void) clickScan:(UIButton*) btn
{
    [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    _publish_switch = NO;
    
    [self stopRtmp];
    
    ScanQRController* vc = [[ScanQRController alloc] init];
    vc.delegate = self;
//    vc.textField = self.txtRtmpUrl;
    [self.navigationController pushViewController:vc animated:NO];
}

-(void) clickPublish:(UIButton*) btn
{
    if (_publish_switch == YES) {
        [self stopRtmp];
        [_btnPublish setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _publish_switch = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    else
    {
        if(![self startRtmp])
        {
            return;
        }
        [_btnPublish setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _publish_switch = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

-(void) clickCamera:(UIButton*) btn
{
    _camera_switch = !_camera_switch;
    
    [btn setImage:[UIImage imageNamed:(_camera_switch? @"camera2" : @"camera")] forState:UIControlStateNormal];
    [_txLivePublisher switchCamera];
}

-(void) clickBeauty:(UIButton*) btn
{
    [_vBeauty removeFromSuperview];
    [self.view addSubview:_vBeauty];
    _vBeauty.hidden = NO;
    [self hideToolbarButtons:YES];
}

- (void)hideToolbarButtons:(BOOL)bHide
{
    _btnPublish.hidden = bHide;
    _btnCamera.hidden = bHide;
    _btnBeauty.hidden = bHide;
    _btnLog.hidden = bHide;
    _btnPushType.hidden = bHide;
}

-(void) clickLog:(UIButton*) btn
{
    if (_log_switch == YES)
    {
        _statusView.hidden = YES;
        _logViewEvt.hidden = YES;
        [btn setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _cover.hidden = YES;
        _log_switch = NO;
        
        for (LinkMicPlayItem * item in _arrayPlayItems) {
            [item showLog: NO];
        }
    }
    else
    {
        _statusView.hidden = NO;
        _logViewEvt.hidden = NO;
        [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _cover.hidden = NO;
        _log_switch = YES;
        
        for (LinkMicPlayItem * item in _arrayPlayItems) {
            [item showLog: YES];
        }
    }
}

-(void) clickPushType:(UIButton*) btn
{
    _isMainPublisher = !_isMainPublisher;
    if (_isMainPublisher) {
        [_btnPushType setImage:[UIImage imageNamed:@"mainpusher"] forState:UIControlStateNormal];
    }
    else {
        [_btnPushType setImage:[UIImage imageNamed:@"subpusher"] forState:UIControlStateNormal];
    }
    
    if ([_txLivePublisher isPublishing]) {
        if (_isMainPublisher) {
            [_txLivePublisher setVideoQuality:VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER adjustBitrate:YES adjustResolution:NO];
        }
        else {
            [_txLivePublisher setVideoQuality:VIDEO_QUALITY_LINKMIC_SUB_PUBLISHER adjustBitrate:YES adjustResolution:NO];
        }
    }
}

-(BOOL)startRtmp{
    [self clearLog];


    if (_strPublisUrl.length == 0) {
        _strPublisUrl = self.txtRtmpUrl.text;
    }
    if (_strPublisUrl.length == 0) {
        _strPublisUrl = RTMP_PUBLISH_URL;
    }
    
    if (!([_strPublisUrl hasPrefix:@"rtmp://"] )) {
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
    
    if(_txLivePublisher != nil)
    {
        _txLivePublisher.delegate = self;
        if (!_isPreviewing) {
            [_txLivePublisher startPreview:_videoPreview];
            _isPreviewing = YES;
        }
        
        TXLivePushConfig * pushConfig = _txLivePublisher.config;
        pushConfig.pauseFps = 10;
        pushConfig.pauseTime = 300;
        pushConfig.pauseImg = [UIImage imageNamed:@"pause_publish.jpg"];
        [_txLivePublisher setConfig:pushConfig];
        
        if (_isMainPublisher) {
            [_txLivePublisher setVideoQuality:VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER adjustBitrate:YES adjustResolution:NO];
        }
        else {
            [_txLivePublisher setVideoQuality:VIDEO_QUALITY_LINKMIC_SUB_PUBLISHER adjustBitrate:YES adjustResolution:NO];
        }
        
        if ([_txLivePublisher startPush:_strPublisUrl] != 0) {
            NSLog(@"推流器启动失败");
            return NO;
        }
    }
    
    [_vBeauty trigglerValues];
    return YES;
}

- (void)stopRtmp {
    _strPublisUrl = @"";
    if(_txLivePublisher != nil)
    {
        _txLivePublisher.delegate = nil;
        [_txLivePublisher stopPreview];
        _isPreviewing = NO;
        [_txLivePublisher stopPush];

    }
//    [_vBeauty resetValues];
}

- (void)stopAll
{
    [self stopRtmp];
    
    for (LinkMicPlayItem * item in _arrayPlayItems) {
        [item stopPlay];
    }
}

// RTMP 推流事件通知
#pragma mark - TXLivePushListener
-(void) onPushEvent:(int)EvtID withParam:(NSDictionary*)param;
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PUSH_ERR_NET_DISCONNECT) {
            [self clickPublish:_btnPublish];
        }else if(EvtID == PUSH_WARNING_HW_ACCELERATION_FAIL){
            _txLivePublisher.config.enableHWAcceleration = false;
        }  else if (EvtID == PUSH_WARNING_NET_BUSY) {
            [_notification displayNotificationWithMessage:@"您当前的网络环境不佳，请尽快更换网络保证正常直播" forDuration:5];
        }
        
        long long time = [(NSNumber*)[dict valueForKey:EVT_TIME] longLongValue];
        int mil = time % 1000;
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:time/1000];
        NSString* Msg = (NSString*)[dict valueForKey:EVT_MSG];
        [self appendLog:Msg time:date mills:mil];
    });
}

-(void) onNetStatus:(NSDictionary*) param
{
    NSDictionary* dict = param;
    
    NSString * streamID = [dict valueForKey:STREAM_ID];
    if ([streamID isEqualToString:_strPublisUrl] != YES)
    {        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int netspeed  = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_SPEED] intValue];
        int vbitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
        int abitrate  = [(NSNumber*)[dict valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
        int cachesize = [(NSNumber*)[dict valueForKey:NET_STATUS_CACHE_SIZE] intValue];
        int dropsize  = [(NSNumber*)[dict valueForKey:NET_STATUS_DROP_SIZE] intValue];
        int jitter    = [(NSNumber*)[dict valueForKey:NET_STATUS_NET_JITTER] intValue];
        int fps       = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_FPS] intValue];
        int width     = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height    = [(NSNumber*)[dict valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        float cpu_usage = [(NSNumber*)[dict valueForKey:NET_STATUS_CPU_USAGE] floatValue];
        int codecCacheSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        
        NSString* log = [NSString stringWithFormat:@"CPU:%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t",
                         cpu_usage*100,
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
                         serverIP];
        [_statusView setText:log];
        
    });
}

-(void) appendLog:(NSString*) evt time:(NSDate*) date mills:(int)mil
{
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log];
    [_logViewEvt setText:_logMsg];
}

- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_statusView setText:@""];
    [_logViewEvt setText:@""];
    _startTime = [[NSDate date]timeIntervalSince1970]*1000;
    _lastTime = _startTime;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - StreamUrlScannerDelegate
-(void) onStreamUrlScannerConfirm:(NSString*)streamUrl {
    _playUrlScanner.hidden = YES;
    if (streamUrl == nil || [self checkPlayUrl:streamUrl] == -1) {
        
    }
    else {
        for (LinkMicPlayItem * item in _arrayPlayItems) {
            if (item.running == NO) {
                [item startPlay:streamUrl];
                break;
            }
        }
    }
}

-(void) onStreamUrlScannerCancel {
    _playUrlScanner.hidden = YES;
}


- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.txtRtmpUrl resignFirstResponder];
    _vBeauty.hidden = YES;
    
    [self hideToolbarButtons:NO];
}

#pragma mark -- ScanQRDelegate
- (void)onScanResult:(NSString *)result
{
    self.txtRtmpUrl.text = result;
}

#pragma mark - BeautySettingPanelDelegate
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


/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
#pragma mark - misc func
- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

// iphone 6 及以上机型适合开启720p, 否则20帧的帧率可能无法达到, 这种"流畅不足,清晰有余"的效果并不好
-(BOOL) isSuitableMachine:(int)targetPlatNum
{
    int mib[2] = {CTL_HW, HW_MACHINE};
    size_t len = 0;
    char* machine;
    
    sysctl(mib, 2, NULL, &len, NULL, 0);
    
    machine = (char*)malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString* platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    if ([platform length] > 6) {
        NSString * platNum = [NSString stringWithFormat:@"%C", [platform characterAtIndex: 6 ]];
        return ([platNum intValue] >= targetPlatNum);
    } else {
        return NO;
    }
}

-(int)checkPlayUrl:(NSString*)playUrl {
    if (!([playUrl hasPrefix:@"http:"] || [playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"rtmp:"] )) {
        [self toastTip:@"播放地址不合法，目前仅支持rtmp,flv!"];
        return -1;
    }
    
    if ([playUrl hasPrefix:@"rtmp:"]) {
        return PLAY_TYPE_LIVE_RTMP;
    } else if (([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) && [playUrl rangeOfString:@".flv"].length > 0) {
        return PLAY_TYPE_LIVE_FLV;
    } else{
        [self toastTip:@"播放地址不合法，直播目前仅支持rtmp,flv播放方式!"];
        return -1;
    }
}

@end
