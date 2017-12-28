
//
//  PlayViewController.m
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "PlayViewController.h"
#import "ScanQRController.h"
//#import "TXUGCPublish.h"
#import "TXLiveRecordListener.h"
//#import "TXUGCPublishListener.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <mach/mach.h>
#import "AppLogMgr.h"
#import "AFNetworkReachabilityManager.h"
#import "UIView+Additions.h"
#import "UIImage+Additions.h"
#define TEST_MUTE   0

#define RTMP_URL    @"请输入或扫二维码获取播放地址"//请输入或扫二维码获取播放地址"

typedef NS_ENUM(NSInteger, ENUM_TYPE_CACHE_STRATEGY)
{
    CACHE_STRATEGY_FAST           = 1,  //极速
    CACHE_STRATEGY_SMOOTH         = 2,  //流畅
    CACHE_STRATEGY_AUTO           = 3,  //自动
};

#define CACHE_TIME_FAST             1.0f
#define CACHE_TIME_SMOOTH           5.0f

#define CACHE_TIME_AUTO_MIN         5.0f
#define CACHE_TIME_AUTO_MAX         10.0f

@interface PlayViewController ()<
UITextFieldDelegate,
TXLiveRecordListener,
TXLivePlayListener,
//TXVideoPublishListener,
TXVideoCustomProcessDelegate,
ScanQRDelegate
>

@end

@implementation PlayViewController
{
    BOOL        _bHWDec;
    UISlider*   _playProgress;
    UISlider*   _playableProgress;
    UILabel*    _playDuration;
    UILabel*    _playStart;
    UIButton*   _btnPlayMode;
    UIButton*   _btnHWDec;
    UIButton*   _btnMute;
    long long   _trackingTouchTS;
    BOOL        _startSeek;
    BOOL        _videoPause;
    CGRect      _videoWidgetFrame; //改变videoWidget的frame时候记得对其重新进行赋值
    UIImageView * _loadingImageView;
    BOOL        _appIsInterrupt;
    float       _sliderValue;
    TX_Enum_PlayType _playType;
    long long	_startPlayTS;
    UIView *    mVideoContainer;
    NSString    *_playUrl;
    UIButton    *_btnRecordVideo;
    UIButton    *_btnPublishVideo;
    UILabel     *_labProgress;
    
    BOOL                _recordStart;
    float               _recordProgress;
//    TXPublishParam       *_publishParam;
//    TXUGCPublish         *_videoPublish;
    TXRecordResult       *_recordResult;
    BOOL                _enableCache;
}

- (void)viewDidLoad {
    _recordStart = NO;
    _recordProgress = 0.f;
    
    [super viewDidLoad];
    [self initUI];
    
//    _videoPublish = [[TXUGCPublish alloc] init];
//    _videoPublish.delegate = self;
}

- (void)statusBarOrientationChanged:(NSNotification *)note  {
//    CGRect frame = self.view.frame;
//    switch ([[UIDevice currentDevice] orientation]) {
//        case UIDeviceOrientationPortrait:        //activity竖屏模式，竖屏推流
//        {
//            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.width*9/16);
//        }
//            break;
//        case UIDeviceOrientationLandscapeRight:   //activity横屏模式，home在左横屏推流
//        {
//            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.height);
//        }
//            break;
//        case UIDeviceOrientationLandscapeLeft:   //activity横屏模式，home在左横屏推流
//        {
//            mVideoContainer.frame = CGRectMake(0, 0,frame.size.width,frame.size.height);
//        }
//            break;
//        default:
//            break;
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)initUI {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
//    self.wantsFullScreenLayout = YES;
    if (self.isLivePlay) {
        self.title = @"直播";
    } else {
        self.title = @"点播";
    }
    
    _videoWidgetFrame = [UIScreen mainScreen].bounds;
    
    [self.view setBackgroundImage:[UIImage imageNamed:@"background.jpg"]];
    
    // remove all subview
    for (UIView *view in [self.view subviews]) {
        [view removeFromSuperview];
    }
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    int icon_size = size.width / 10;
        
    _cover = [[UIView alloc]init];
    _cover.frame  = CGRectMake(10.0f, 55 + 2*icon_size, size.width - 20, size.height - 75 - 3 * icon_size);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha  = 0.5;
    _cover.hidden = YES;
    [self.view addSubview:_cover];
    
    int logheadH = 65;
    _statusView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size, size.width - 20,  logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self.view addSubview:_statusView];
    
    _logViewEvt = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 55 + 2*icon_size + logheadH, size.width - 20, size.height - 75 - 3 * icon_size - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self.view addSubview:_logViewEvt];
    
    self.txtRtmpUrl = [[UITextField alloc] initWithFrame:CGRectMake(10, 30 + icon_size + 10, size.width- 25 - icon_size, icon_size)];
    [self.txtRtmpUrl setBorderStyle:UITextBorderStyleRoundedRect];
    self.txtRtmpUrl.placeholder = RTMP_URL;
    self.txtRtmpUrl.text = @"";
    self.txtRtmpUrl.background = [UIImage imageNamed:@"Input_box"];
    self.txtRtmpUrl.alpha = 0.5;
    self.txtRtmpUrl.autocapitalizationType = UITextAutocorrectionTypeNo;
    self.txtRtmpUrl.delegate = self;
    [self.view addSubview:self.txtRtmpUrl];
    
    UIButton* btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame = CGRectMake(size.width - 10 - icon_size , 30 + icon_size + 10, icon_size, icon_size);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self action:@selector(clickScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnScan];

    int icon_length = 7;
    if (!self.isLivePlay)
        icon_length = 8;
    
    int icon_gap = (size.width - icon_size*(icon_length-1))/icon_length;
    int hh = [[UIScreen mainScreen] bounds].size.height - icon_size - 50;
    _playStart = [[UILabel alloc]init];
    _playStart.frame = CGRectMake(20, hh, 50, 30);
    [_playStart setText:@"00:00"];
    [_playStart setTextColor:[UIColor whiteColor]];
    _playStart.hidden = YES;
    [self.view addSubview:_playStart];
    
    _playDuration = [[UILabel alloc]init];
    _playDuration.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-70, hh, 50, 30);
    [_playDuration setText:@"00:00"];
    [_playDuration setTextColor:[UIColor whiteColor]];
    _playDuration.hidden = YES;
    [self.view addSubview:_playDuration];

    _playableProgress=[[UISlider alloc]initWithFrame:CGRectMake(70, hh-1, [[UIScreen mainScreen] bounds].size.width-132, 30)];
    _playableProgress.maximumValue = 0;
    _playableProgress.minimumValue = 0;
    _playableProgress.value = 0;
    [_playableProgress setThumbImage:[UIImage imageWithColor:[UIColor clearColor] size:CGSizeMake(20, 10)] forState:UIControlStateNormal];
    [_playableProgress setMaximumTrackTintColor:[UIColor clearColor]];
    _playableProgress.userInteractionEnabled = NO;
    _playableProgress.hidden = YES;
    
    [self.view addSubview:_playableProgress];
    
    _playProgress=[[UISlider alloc]initWithFrame:CGRectMake(70, hh, [[UIScreen mainScreen] bounds].size.width-140, 30)];
    _playProgress.maximumValue = 0;
    _playProgress.minimumValue = 0;
    _playProgress.value = 0;
    _playProgress.continuous = NO;
//    _playProgress.maximumTrackTintColor = UIColor.clearColor;
    [_playProgress addTarget:self action:@selector(onSeek:) forControlEvents:(UIControlEventValueChanged)];
    [_playProgress addTarget:self action:@selector(onSeekBegin:) forControlEvents:(UIControlEventTouchDown)];
    [_playProgress addTarget:self action:@selector(onDrag:) forControlEvents:UIControlEventTouchDragInside];
    _playProgress.hidden = YES;

    [self.view addSubview:_playProgress];
    
    int btn_index = 0;
    _play_switch = NO;
    _btnPlay = [self createBottomBtnIndex:btn_index++ Icon:@"start" Action:@selector(clickPlay:) Gap:icon_gap Size:icon_size];

    if(_playType == PLAY_TYPE_LIVE_RTMP || _playType == PLAY_TYPE_LIVE_FLV)
    {
        _btnRecordVideo = [self createBottomBtnIndexEx:0 Icon:@"start" Action:@selector(clickRecord) Gap:icon_gap Size:icon_size];
        _btnPublishVideo = [self createBottomBtnIndexEx:1 Icon:@"log" Action:@selector(clickPublish) Gap:icon_gap Size:icon_size];
        _btnMute = [self createBottomBtnIndexEx:5 Icon:@"mic" Action:@selector(clickMute:) Gap:icon_gap Size:icon_size];
        _btnRecordVideo.hidden = YES;
        _btnPublishVideo.hidden = YES;
        _btnMute.hidden = YES;
    }
    
    _labProgress = [[UILabel alloc]init];
    _labProgress.frame = CGRectMake(_btnPublishVideo.frame.origin.x + icon_size + 10, _btnPublishVideo.frame.origin.y , 100, 30);
    [_labProgress setText:@"test"];
    [_labProgress setTextAlignment:NSTextAlignmentLeft];
    [_labProgress setTextColor:[UIColor redColor]];
    _labProgress.hidden = YES;
    [self.view addSubview:_labProgress];
    
    if (self.isLivePlay) {
        _btnClose = nil;
    } else {
        _btnClose = [self createBottomBtnIndex:btn_index++ Icon:@"close" Action:@selector(clickClose:) Gap:icon_gap Size:icon_size];
    }

    _log_switch = NO;
    [self createBottomBtnIndex:btn_index++ Icon:@"log" Action:@selector(clickLog:) Gap:icon_gap Size:icon_size];

    _bHWDec = NO;
    _btnHWDec = [self createBottomBtnIndex:btn_index++ Icon:@"quick2" Action:@selector(onClickHardware:) Gap:icon_gap Size:icon_size];

    _screenPortrait = NO;
    [self createBottomBtnIndex:btn_index++ Icon:@"portrait" Action:@selector(clickScreenOrientation:) Gap:icon_gap Size:icon_size];

    _renderFillScreen = YES;
    [self createBottomBtnIndex:btn_index++ Icon:@"adjust" Action:@selector(clickRenderMode:) Gap:icon_gap Size:icon_size];
    

    
    _txLivePlayer = [[TXLivePlayer alloc] init];
    _txLivePlayer.recordDelegate = self;
    
    if (!self.isLivePlay) {
        _btnCacheStrategy = nil;
    } else {
        _btnCacheStrategy = [self createBottomBtnIndex:btn_index++ Icon:@"cache_time" Action:@selector(onAdjustCacheStrategy:) Gap:icon_gap Size:icon_size];
    }
    [self setCacheStrategy:CACHE_STRATEGY_AUTO];

    if (!self.isLivePlay) {
        [self createBottomBtnIndex:btn_index++ Icon:@"cache2" Action:@selector(cacheEnable:) Gap:icon_gap Size:icon_size];
    }
    
    _videoPause = NO;
    _trackingTouchTS = 0;
    
    if (!self.isLivePlay) {
        _playStart.hidden = NO;
        _playDuration.hidden = NO;
        _playProgress.hidden = NO;
        _playableProgress.hidden = NO;
    } else {
        _playStart.hidden = YES;
        _playDuration.hidden = YES;
        _playProgress.hidden = YES;
        _playableProgress.hidden = YES;
    }
    
    //loading imageview
    float width = 34;
    float height = 34;
    float offsetX = (self.view.frame.size.width - width) / 2;
    float offsetY = (self.view.frame.size.height - height) / 2;
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:[UIImage imageNamed:@"loading_image0.png"],[UIImage imageNamed:@"loading_image1.png"],[UIImage imageNamed:@"loading_image2.png"],[UIImage imageNamed:@"loading_image3.png"],[UIImage imageNamed:@"loading_image4.png"],[UIImage imageNamed:@"loading_image5.png"],[UIImage imageNamed:@"loading_image6.png"],[UIImage imageNamed:@"loading_image7.png"], nil];
    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, offsetY, width, height)];
    _loadingImageView.animationImages = array;
    _loadingImageView.animationDuration = 1;
    _loadingImageView.hidden = YES;
    [self.view addSubview:_loadingImageView];
    
    _vCacheStrategy = [[UIView alloc]init];
    _vCacheStrategy.frame = CGRectMake(0, size.height-120, size.width, 120);
    [_vCacheStrategy setBackgroundColor:[UIColor whiteColor]];
    
    UILabel* title= [[UILabel alloc]init];
    title.frame = CGRectMake(0, 0, size.width, 50);
    [title setText:@"缓存策略"];
    title.textAlignment = NSTextAlignmentCenter;
    [title setFont:[UIFont fontWithName:@"" size:14]];
    
    [_vCacheStrategy addSubview:title];
    
    int gap = 30;
    int width2 = (size.width - gap*2 - 20) / 3;
    _radioBtnFast = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnFast.frame = CGRectMake(10, 60, width2, 40);
    [_radioBtnFast setTitle:@"极速" forState:UIControlStateNormal];
    [_radioBtnFast addTarget:self action:@selector(onAdjustFast:) forControlEvents:UIControlEventTouchUpInside];
    
    _radioBtnSmooth = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnSmooth.frame = CGRectMake(10 + gap + width2, 60, width2, 40);
    [_radioBtnSmooth setTitle:@"流畅" forState:UIControlStateNormal];
    [_radioBtnSmooth addTarget:self action:@selector(onAdjustSmooth:) forControlEvents:UIControlEventTouchUpInside];
    
    _radioBtnAUTO = [UIButton buttonWithType:UIButtonTypeCustom];
    _radioBtnAUTO.frame = CGRectMake(size.width - 10 - width2, 60, width2, 40);
    [_radioBtnAUTO setTitle:@"自动" forState:UIControlStateNormal];
    [_radioBtnAUTO addTarget:self action:@selector(onAdjustAuto:) forControlEvents:UIControlEventTouchUpInside];
    
    [_vCacheStrategy addSubview:_radioBtnFast];
    [_vCacheStrategy addSubview:_radioBtnSmooth];
    [_vCacheStrategy addSubview:_radioBtnAUTO];
    _vCacheStrategy.hidden = YES;
    [self.view addSubview:_vCacheStrategy];
    
    CGRect VideoFrame = self.view.bounds;
    mVideoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VideoFrame.size.width, VideoFrame.size.height)];
    [self.view insertSubview:mVideoContainer atIndex:0];
    mVideoContainer.center = self.view.center;
}

- (UIButton*)createBottomBtnIndex:(int)index Icon:(NSString*)icon Action:(SEL)action Gap:(int)gap Size:(int)size
{
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index+1)*gap + index*size, [[UIScreen mainScreen] bounds].size.height - size - 10, size, size);
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

- (UIButton*)createBottomBtnIndexEx:(int)index Icon:(NSString*)icon Action:(SEL)action Gap:(int)gap Size:(int)size
{
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index+1)*gap + index*size, [[UIScreen mainScreen] bounds].size.height - 2*(size + 10), size, size);
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

//在低系统（如7.1.2）可能收不到这个回调，请在onAppDidEnterBackGround和onAppWillEnterForeground里面处理打断逻辑
- (void) onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_play_switch == YES && _appIsInterrupt == NO) {
//            if ([self isVODType:_playType]) {
//                if (!_videoPause) {
//                    [_txLivePlayer pause];
//                }
//            }
            _appIsInterrupt = YES;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            // 收到该事件不能调用resume，因为此时可能还在后台
            /*
            if (_play_switch == YES && _appIsInterrupt == YES) {
                if ([self isVODType:_playType]) {
                    if (!_videoPause) {
                        [_txLivePlayer resume];
                    }
                }
                _appIsInterrupt = NO;
            }
             */
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if (_play_switch == YES) {
        if ([self isVODType:_playType]) {
            if (!_videoPause) {
                [_txLivePlayer pause];
            }
        }
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app {
    if (_play_switch == YES) {
        if ([self isVODType:_playType]) {
            if (!_videoPause) {
                [_txLivePlayer resume];
            }
        }
    }
}

- (void)onAppDidBecomeActive:(UIApplication*)app {
    if (_play_switch == YES && _appIsInterrupt == YES) {
        if ([self isVODType:_playType]) {
            if (!_videoPause) {
                [_txLivePlayer resume];
            }
        }
        _appIsInterrupt = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_play_switch == YES) {
        [self stopRtmp];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma -- example code bellow
- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_statusView setText:@""];
    [_logViewEvt setText:@""];
    _startTime = [[NSDate date]timeIntervalSince1970]*1000;
    _lastTime = _startTime;
}

-(BOOL)isVODType:(int)playType {
    if (playType == PLAY_TYPE_VOD_FLV || playType == PLAY_TYPE_VOD_HLS || playType == PLAY_TYPE_VOD_MP4 || playType == PLAY_TYPE_LOCAL_VIDEO) {
        return YES;
    }
    return NO;
}

-(BOOL)checkPlayUrl:(NSString*)playUrl {
    if (self.isLivePlay) {
        if ([playUrl hasPrefix:@"rtmp:"]) {
            _playType = PLAY_TYPE_LIVE_RTMP;
        } else if (([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) && [playUrl rangeOfString:@".flv"].length > 0) {
            _playType = PLAY_TYPE_LIVE_FLV;
        } else{
            [self toastTip:@"播放地址不合法，直播目前仅支持rtmp,flv播放方式!"];
            return NO;
        }
    } else {
        if ([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) {
            if ([playUrl rangeOfString:@".flv"].length > 0) {
                _playType = PLAY_TYPE_VOD_FLV;
            } else if ([playUrl rangeOfString:@".m3u8"].length > 0){
                _playType= PLAY_TYPE_VOD_HLS;
            } else if ([playUrl rangeOfString:@".mp4"].length > 0){
                _playType= PLAY_TYPE_VOD_MP4;
            } else {
                [self toastTip:@"播放地址不合法，点播目前仅支持flv,hls,mp4播放方式!"];
                return NO;
            }
            
        } else {
            _playType = PLAY_TYPE_LOCAL_VIDEO;
        }
    }
    
    return YES;
}
-(BOOL)startRtmp{
    NSString* playUrl = self.txtRtmpUrl.text;
    if (playUrl.length == 0) {
        playUrl = @"http://baobab.wdjcdn.com/1456117847747a_x264.mp4";
    }
    
    if (![self checkPlayUrl:playUrl]) {
        return NO;
    }
    
    [self clearLog];
    
    // arvinwu add. 增加播放按钮事件的时间打印。
    unsigned long long recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    int mil = recordTime%1000;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:[NSDate date]];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] 点击播放按钮", time, mil];
    
    NSString *ver = [TXLiveBase getSDKVersionStr];
    _logMsg = [NSString stringWithFormat:@"liteav sdk version: %@\n%@", ver, log];
    [_logViewEvt setText:_logMsg];

    
    if(_txLivePlayer != nil)
    {
        _txLivePlayer.delegate = self;
//        _txLivePlayer.recordDelegate = self;
//        _txLivePlayer.videoProcessDelegate = self;
        if (self.isLivePlay) {
            [_txLivePlayer setupVideoWidget:CGRectMake(0, 0, 0, 0) containView:mVideoContainer insertIndex:0];
        }
        
        if (_config == nil)
        {
            _config = [[TXLivePlayConfig alloc] init];
        }
        
        if (_enableCache) {
            _config.cacheFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            _config.maxCacheItems = 2;
            
        } else {
            _config.cacheFolderPath = nil;
        }
        
        [_txLivePlayer setConfig:_config];
        
        //设置播放器缓存策略
        //这里将播放器的策略设置为自动调整，调整的范围设定为1到4s，您也可以通过setCacheTime将播放器策略设置为采用
        //固定缓存时间。如果您什么都不调用，播放器将采用默认的策略（默认策略为自动调整，调整范围为1到4s）
        //[_txLivePlayer setCacheTime:5];
        //[_txLivePlayer setMinCacheTime:1];
        //[_txLivePlayer setMaxCacheTime:4];
//        _txLivePlayer.isAutoPlay = NO;
//        [_txLivePlayer setRate:1.5];
        int result = [_txLivePlayer startPlay:playUrl type:_playType];
        if( result != 0)
        {
            NSLog(@"播放器启动失败");
            return NO;
        }
        
        if (_screenPortrait) {
            [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
        } else {
            [_txLivePlayer setRenderRotation:HOME_ORIENTATION_DOWN];
        }
        if (_renderFillScreen) {
            [_txLivePlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
        } else {
            [_txLivePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
        }
        
        [self startLoadingAnimation];
        
        _videoPause = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
    }
    [self startLoadingAnimation];
    _startPlayTS = [[NSDate date]timeIntervalSince1970]*1000;
    
    _playUrl = playUrl;
    
    return YES;
}


- (void)stopRtmp{
    _playUrl = @"";
    [self stopLoadingAnimation];
    if(_txLivePlayer != nil)
    {
        [_txLivePlayer stopPlay];
        [_btnMute setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
        [_btnMute setHighlighted:NO];
        [_txLivePlayer removeVideoWidget];
        _txLivePlayer.delegate = nil;
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
}

#pragma - ui event response.
- (void) clickPlay:(UIButton*) sender {
    //-[UIApplication setIdleTimerDisabled:]用于控制自动锁屏，SDK内部并无修改系统锁屏的逻辑
    if (_play_switch == YES)
    {
        if ([self isVODType:_playType]) {
            if (_videoPause) {
                [_txLivePlayer resume];
                [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            } else {
                [_txLivePlayer pause];
                [sender setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            }
            _videoPause = !_videoPause;
            
            
        } else {
            _play_switch = NO;
            [self stopRtmp];
            [sender setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }
        
    }
    else
    {
        if (![self startRtmp]) {
            return;
        }
        
        [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _play_switch = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

//- (void)clickRecord
//{
//    _recordStart = !_recordStart;
//    _btnRecordVideo.selected = NO;
//    if (!_recordStart) {
//        [_btnRecordVideo setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
//        _labProgress.text = @"";
//        [_txLivePlayer stopRecord];
//        
//        _publishParam = [[TXPublishParam alloc] init];
//    } else {
//        [_btnRecordVideo setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"开始录流" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//        [alertView show];
//    }
//}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (0 == buttonIndex) {
//         [_txLivePlayer startRecord:RECORD_TYPE_STREAM_SOURCE];
//    }
//    _publishParam = nil;
//}

//- (void)clickPublish
//{
//    NSError* error;
//    NSDictionary* dictParam = @{@"Action" : @"GetVodSignatureV2"};
//    NSData *data = [NSJSONSerialization dataWithJSONObject:dictParam options:0 error:&error];
//    
//    NSMutableString *strUrl = [[NSMutableString alloc] initWithString:@"https://livedemo.tim.qq.com/interface.php"];
//    
//    NSURL *URL = [NSURL URLWithString:strUrl];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
//    
//    if (data)
//    {
//        [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
//        [request setHTTPMethod:@"POST"];
//        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
//        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
//        
//        [request setHTTPBody:data];
//    }
//    
//    [request setTimeoutInterval:30];
//    
//    
//    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        
//        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
//        NSError *err = nil;
//        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&err];
//        
//        int errCode = -1;
//        NSDictionary* dataDict = nil;
//        if (resultDict)
//        {
//            if (resultDict[@"returnValue"]) {
//                errCode = [resultDict[@"returnValue"] intValue];
//            }
//            
//            if (0 == errCode && resultDict[@"returnData"]) {
//                dataDict = resultDict[@"returnData"];
//            }
//        }
//        
//        if (dataDict && _publishParam && _videoPublish) {
//            _publishParam.signature  = dataDict[@"signature"];
//            _publishParam.coverImage = _recordResult.coverImage;
//            _publishParam.videoPath  = _recordResult.videoPath;
//            [_videoPublish publishVideo:_publishParam];
//        }
//    }];
//    
//    [task resume];
//}


#pragma mark - TXLiveRecordListener
-(void) onRecordProgress:(NSInteger)milliSecond
{
    int progress = (int)milliSecond/1000;
    _labProgress.text = [NSString stringWithFormat:@"%d", progress];
}

-(void) onRecordComplete:(TXRecordResult*)result
{
    if(result == nil || result.retCode != 0)
    {
        NSLog(@"Error, record failed:%ld %@", (long)result.retCode, result.descMsg);
        [self toastTip:[NSString stringWithFormat:@"录制失败!![%ld]", (long)result.retCode]];
        return;
    }
    _labProgress.text = @"录制成功";
    _recordResult = result;
    
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:result.videoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
//        if (error != nil) {
//            NSLog(@"save video fail:%@", error);
//        }
//    }];
}

//-(void) onPublishProgress:(NSInteger)uploadBytes totalBytes: (NSInteger)totalBytes
//{
//    _labProgress.text = [NSString stringWithFormat:@"%d%%", (int)(uploadBytes*100/totalBytes)];
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
//        
//         _labProgress.text = @"";
//        
//    } else {
//        [self toastTip:[NSString stringWithFormat:@"发布失败啦![%d]", result.retCode]];
//    }
//}

- (void)clickClose:(UIButton*)sender {
    if (_play_switch) {
        _play_switch = NO;
        [self stopRtmp];
        [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _playStart.text = @"00:00";
        [_playDuration setText:@"00:00"];
        [_playProgress setValue:0];
        [_playProgress setMaximumValue:0];
        [_playableProgress setValue:0];
        [_playableProgress setMaximumValue:0];
        
        [_btnRecordVideo setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _labProgress.text = @"";
    }
}

- (void) clickLog:(UIButton*) sender {
    if (_log_switch == YES)
    {
        _statusView.hidden = YES;
        _logViewEvt.hidden = YES;
        [sender setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _cover.hidden = YES;
        _log_switch = NO;
    }
    else
    {
        _statusView.hidden = NO;
        _logViewEvt.hidden = NO;
        [sender setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _cover.hidden = NO;
        _log_switch = YES;
    }
    
//    [_txLivePlayer snapshot:^(UIImage *img) {
//        img = img;
//    }];
}

- (void) clickScreenOrientation:(UIButton*) sender {
    _screenPortrait = !_screenPortrait;
    
    if (_screenPortrait) {
        [sender setImage:[UIImage imageNamed:@"landscape"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
    } else {
        [sender setImage:[UIImage imageNamed:@"portrait"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderRotation:HOME_ORIENTATION_DOWN];
    }
}

- (void) clickRenderMode:(UIButton*) sender {
    _renderFillScreen = !_renderFillScreen;
    
    if (_renderFillScreen) {
        [sender setImage:[UIImage imageNamed:@"adjust"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
    } else {
        [sender setImage:[UIImage imageNamed:@"fill"] forState:UIControlStateNormal];
        [_txLivePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    }
}

- (void)clickMute:(UIButton*)sender
{
    if (sender.isSelected) {
        [_txLivePlayer setMute:NO];
        [sender setSelected:NO];
        [sender setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
    }
    else {
        [_txLivePlayer setMute:YES];
        [sender setSelected:YES];
        [sender setImage:[UIImage imageNamed:@"vodplay"] forState:UIControlStateNormal];
    }
}

- (void) setCacheStrategy:(NSInteger) nCacheStrategy
{
    if (_btnCacheStrategy == nil || _cacheStrategy == nCacheStrategy)    return;
    
    if (_config == nil)
    {
        _config = [[TXLivePlayConfig alloc] init];
    }
    
    _cacheStrategy = nCacheStrategy;
    switch (_cacheStrategy) {
        case CACHE_STRATEGY_FAST:
            _config.bAutoAdjustCacheTime = YES;
            _config.minAutoAdjustCacheTime = CACHE_TIME_FAST;
            _config.maxAutoAdjustCacheTime = CACHE_TIME_FAST;
            [_txLivePlayer setConfig:_config];
            break;
            
        case CACHE_STRATEGY_SMOOTH:
            _config.bAutoAdjustCacheTime = NO;
            _config.cacheTime = CACHE_TIME_SMOOTH;
            [_txLivePlayer setConfig:_config];
            break;
            
        case CACHE_STRATEGY_AUTO:
            _config.bAutoAdjustCacheTime = YES;
            _config.minAutoAdjustCacheTime = CACHE_TIME_FAST;
            _config.maxAutoAdjustCacheTime = CACHE_TIME_SMOOTH;
            [_txLivePlayer setConfig:_config];
            break;
            
        default:
            break;
    }
}

- (void) onAdjustCacheStrategy:(UIButton*) sender
{
#if TEST_MUTE
    static BOOL flag = YES;
    [_txLivePlayer setMute:flag];
    flag = !flag;
#else
    _vCacheStrategy.hidden = NO;
    switch (_cacheStrategy) {
        case CACHE_STRATEGY_FAST:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
            
        case CACHE_STRATEGY_SMOOTH:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
            
        case CACHE_STRATEGY_AUTO:
            [_radioBtnFast setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnFast setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnSmooth setBackgroundImage:[UIImage imageNamed:@"white"] forState:UIControlStateNormal];
            [_radioBtnSmooth setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_radioBtnAUTO setBackgroundImage:[UIImage imageNamed:@"black"] forState:UIControlStateNormal];
            [_radioBtnAUTO setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
#endif
}

- (void) onAdjustFast:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_FAST];
}

- (void) onAdjustSmooth:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_SMOOTH];
}

- (void) onAdjustAuto:(UIButton*) sender
{
    _vCacheStrategy.hidden = YES;
    [self setCacheStrategy:CACHE_STRATEGY_AUTO];
}

- (void) onClickHardware:(UIButton*) sender {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self toastTip:@"iOS 版本低于8.0，不支持硬件加速."];
        return;
    }
    
    if (_play_switch == YES)
    {
        [self stopRtmp];
    }

    _txLivePlayer.enableHWAcceleration = !_bHWDec;
    
    _bHWDec = _txLivePlayer.enableHWAcceleration;
    
    if(_bHWDec)
    {
        [sender setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
    }
    else
    {
        [sender setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
    }
    
    if (_play_switch == YES) {
        if (_bHWDec) {
            
            [self toastTip:@"切换为硬解码. 重启播放流程"];
        }
        else
        {
            [self toastTip:@"切换为软解码. 重启播放流程"];
            
        }

        [self startRtmp];
    }

}


-(void) clickScan:(UIButton*) btn
{
    [self stopRtmp];
    _play_switch = NO;
    [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    ScanQRController* vc = [[ScanQRController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma -- UISlider - play seek
-(void)onSeek:(UISlider *)slider{
    [_txLivePlayer seek:_sliderValue];
    _trackingTouchTS = [[NSDate date]timeIntervalSince1970]*1000;
    _startSeek = NO;
    NSLog(@"vod seek drag end");
}

-(void)onSeekBegin:(UISlider *)slider{
    _startSeek = YES;
    NSLog(@"vod seek drag begin");
}

-(void)onDrag:(UISlider *)slider {
    float progress = slider.value;
    int intProgress = progress + 0.5;
    _playStart.text = [NSString stringWithFormat:@"%02d:%02d",(int)(intProgress / 60), (int)(intProgress % 60)];
    _sliderValue = slider.value;
}

#pragma -- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.txtRtmpUrl resignFirstResponder];
    _vCacheStrategy.hidden = YES;
}


#pragma mark -- ScanQRDelegate
- (void)onScanResult:(NSString *)result
{
    self.txtRtmpUrl.text = result;
}

- (void)cacheEnable:(id)sender {
    _enableCache = !_enableCache;
    if (_enableCache) {
        [sender setImage:[UIImage imageNamed:@"cache"] forState:UIControlStateNormal];
    } else {
        [sender setImage:[UIImage imageNamed:@"cache2"] forState:UIControlStateNormal];
    }
}
/**
 @method 获取指定宽度width的字符串在UITextView上的高度
 @param textView 待计算的UITextView
 @param Width 限制字符串显示区域的宽度
 @result float 返回的高度
 */
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

#pragma ###TXLivePlayListener
-(void) appendLog:(NSString*) evt time:(NSDate*) date mills:(int)mil
{
    if (evt == nil) {
        return;
    }
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* time = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log ];
    [_logViewEvt setText:_logMsg];
}

-(void) onPlayEvent:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (EvtID == PLAY_EVT_RCV_FIRST_I_FRAME) {

//            _publishParam = nil;
            if (!self.isLivePlay)
                [_txLivePlayer setupVideoWidget:CGRectMake(0, 0, 0, 0) containView:mVideoContainer insertIndex:0];
        }
        
        if (EvtID == PLAY_EVT_PLAY_BEGIN) {
            [self stopLoadingAnimation];
            long long playDelay = [[NSDate date]timeIntervalSince1970]*1000 - _startPlayTS;
            AppDemoLog(@"AutoMonitor:PlayFirstRender,cost=%lld", playDelay);
        } else if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            if (_startSeek) {
                return;
            }
            // 避免滑动进度条松开的瞬间可能出现滑动条瞬间跳到上一个位置
            long long curTs = [[NSDate date]timeIntervalSince1970]*1000;
            if (llabs(curTs - _trackingTouchTS) < 500) {
                return;
            }
            _trackingTouchTS = curTs;
            
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            
            int intProgress = progress + 0.5;
            _playStart.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intProgress / 60), (int)(intProgress % 60)];
            [_playProgress setValue:progress];
            
            int intDuration = duration + 0.5;
            if (duration > 0 && _playProgress.maximumValue != duration) {
                [_playProgress setMaximumValue:duration];
                [_playableProgress setMaximumValue:duration];
                _playDuration.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
            }
            
            [_playableProgress setValue:[dict[EVT_PLAYABLE_DURATION] floatValue]];
            return ;
        } else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END) {
            [self stopRtmp];
            _play_switch = NO;
            [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            [_playProgress setValue:0];
             _playStart.text = @"00:00";
            _videoPause = NO;
            
            if (EvtID == PLAY_ERR_NET_DISCONNECT) {
                NSString* Msg = (NSString*)[dict valueForKey:EVT_MSG];
                [self toastTip:Msg];
            }
            
        } else if (EvtID == PLAY_EVT_PLAY_LOADING){
            [self startLoadingAnimation];
        }
        else if (EvtID == PLAY_EVT_CONNECT_SUCC) {
            BOOL isWifi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
            if (!isWifi) {
                __weak __typeof(self) weakSelf = self;
                [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                    if (_playUrl.length == 0) {
                        return;
                    }
                    if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                                       message:@"您要切换到Wifi再观看吗?"
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
                            [weakSelf stopRtmp];
                            [weakSelf startRtmp];
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [weakSelf presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
        }
//        NSLog(@"evt:%d,%@", EvtID, dict);
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
        float cpu_app_usage = [(NSNumber*)[dict valueForKey:NET_STATUS_CPU_USAGE_D] floatValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        int codecCacheSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber*)[dict valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
        int nCahcedSize = [(NSNumber*)[dict valueForKey:NET_STATUS_CACHE_SIZE] intValue]/1000;
        
         NSString* log = [NSString stringWithFormat:@"CPU:%.1f%%|%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t\tCAH:%d kb",
                        cpu_app_usage*100,
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
                         serverIP,
                         nCahcedSize];
        [_statusView setText:log];
        AppDemoLogOnlyFile(@"Current status, VideoBitrate:%d, AudioBitrate:%d, FPS:%d, RES:%d*%d, netspeed:%d", vbitrate, abitrate, fps, width, height, netspeed);
    });
}

-(void) startLoadingAnimation
{
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = NO;
        [_loadingImageView startAnimating];
    }
}

-(void) stopLoadingAnimation
{
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = YES;
        [_loadingImageView stopAnimating];
    }
}

//- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    return NO;
//}
@end
