
#import <Foundation/Foundation.h>
#import "VideoRecordViewController.h"
#import "TXRTMPSDK/TXUGCRecord.h"
//#import "TCVideoPublishController.h"
#import "VideoPreviewViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ColorMacro.h"
#import "UIView+Additions.h"
#import "BeautySettingPanel.h"

#define BUTTON_RECORD_SIZE          65
#define BUTTON_CONTROL_SIZE         40
#define MAX_RECORD_TIME             60
#define MIN_RECORD_TIME             5


@interface VideoRecordViewController()<TXVideoRecordListener, BeautySettingPanelDelegate>
{
    BOOL                            _cameraFront;
    BOOL                            _lampOpened;
    BOOL                            _bottomViewShow;
    
    int                             _beautyDepth;
    int                             _whitenDepth;
    
    BOOL                            _cameraPreviewing;
    BOOL                            _videoRecording;
    UIView *                        _videoRecordView;
    UIButton *                      _btnStartRecord;
    UIButton *                      _btnCamera;
    UIButton *                      _btnLamp;
    UIButton *                      _btnBeauty;
    UIProgressView *                _progressView;
    UILabel *                       _recordTimeLabel;
    int                             _currentRecordTime;
    
    BeautySettingPanel*             _vBeauty;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    BOOL                            _appForeground;
    
    UIView*                         _tmplBar;
}
@end


@implementation VideoRecordViewController

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _cameraFront = YES;
        _lampOpened = NO;
        _bottomViewShow = NO;
        
        _beautyDepth = 6.3;
        _whitenDepth = 2.7;
        
        _cameraPreviewing = NO;
        _videoRecording = NO;

        _currentRecordTime = 0;
        
        [TXUGCRecord shareInstance].recordDelegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAudioSessionEvent:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        _appForeground = YES;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    [self initBeautyUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    self.navigationController.navigationBar.hidden = NO;

//    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
//    [self.navigationController setNavigationBarHidden:YES];
//    self.navigationController.navigationBar.hidden = NO;
//    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    [self startCameraPreview];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.hidden = _navigationBarHidden;
    
    [self stopCameraPreview];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)onAudioSessionEvent:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        // 在10.3及以上的系统上，分享跳其它app后再回来会收到AVAudioSessionInterruptionWasSuspendedKey的通知，不处理这个事件。
        if ([info objectForKey:@"AVAudioSessionInterruptionWasSuspendedKey"]) {
            return;
        }
        _appForeground = NO;
        
        if (_videoRecording)
        {
            _videoRecording = NO;
        }
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            _appForeground = YES;
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication*)app
{
    _appForeground = NO;
    
    if (_videoRecording)
    {
        _videoRecording = NO;
    }
}

- (void)onAppWillEnterForeground:(UIApplication*)app
{
    _appForeground = YES;
}


#pragma mark ---- Common UI ----
-(void)initUI
{
    self.title = @"视频录制";
    _videoRecordView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_videoRecordView];
    
//    UIImageView* mask_top = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_CONTROL_SIZE)];
//    [mask_top setImage:[UIImage imageNamed:@"video_record_mask_top"]];
//    [self.view addSubview:mask_top];
    
    UIImageView* mask_buttom = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 100)];
    [mask_buttom setImage:[UIImage imageNamed:@"video_record_mask_buttom"]];
    [self.view addSubview:mask_buttom];
    
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnCamera.center = CGPointMake(self.view.frame.size.width / 4 , self.view.frame.size.height - BUTTON_RECORD_SIZE + 10);
    [_btnCamera setImage:[UIImage imageNamed:@"cameraex"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(onBtnCameraClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];

    _btnStartRecord = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_RECORD_SIZE, BUTTON_RECORD_SIZE)];
    _btnStartRecord.center = CGPointMake(self.view.frame.size.width / 2, _btnCamera.center.y);
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord_press"] forState:UIControlStateSelected];
    [_btnStartRecord addTarget:self action:@selector(onBtnRecordStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartRecord];
    
    _btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.bounds = CGRectMake(0, 0, 30, 30);
    _btnBeauty.center = CGPointMake(self.view.frame.size.width * 3 / 4 , _btnStartRecord.center.y);
    [_btnBeauty setImage:[UIImage imageNamed:@"beautyex"] forState:UIControlStateNormal];
    [_btnBeauty addTarget:self action:@selector(onBtnBeautyClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBeauty];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 20)];
    _progressView.center = CGPointMake(self.view.frame.size.width / 2, _btnStartRecord.frame.origin.y - 20);
    _progressView.progressTintColor = UIColorFromRGB(0X0ACCAC);
    _progressView.tintColor = UIColorFromRGB(0XBBBBBB);
    _progressView.progress = _currentRecordTime / MAX_RECORD_TIME;
    [self.view addSubview:_progressView];
    
    UIView * minimumView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 6)];
    minimumView.backgroundColor = UIColorFromRGB(0X0ACCAC);
    minimumView.center = CGPointMake(_progressView.frame.origin.x + _progressView.width*MIN_RECORD_TIME/MAX_RECORD_TIME, _progressView.center.y);
    [self.view addSubview:minimumView];
    
    UILabel * minimumLabel = [[UILabel alloc]init];
    minimumLabel.frame = CGRectMake(5, 1, 150, 150);
    [minimumLabel setText:@"至少要录到这里"];
    [minimumLabel setFont:[UIFont fontWithName:@"" size:14]];
    [minimumLabel setTextColor:[UIColor whiteColor]];
    [minimumLabel sizeToFit];
    UIImageView * minumumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, minimumLabel.frame.size.width + 10, minimumLabel.frame.size.height + 5)];
    minumumImageView.image = [UIImage imageNamed:@"bubble"];
    [minumumImageView addSubview:minimumLabel];
    minumumImageView.center = CGPointMake(minimumView.center.x + 13, minimumView.frame.origin.y - minimumLabel.frame.size.height);
    [self.view addSubview:minumumImageView];
    minumumImageView.hidden = YES;
    minimumLabel.hidden = YES;
    
    _recordTimeLabel = [[UILabel alloc]init];
    _recordTimeLabel.frame = CGRectMake(0, 0, 100, 100);
    [_recordTimeLabel setText:@"00:00"];
    _recordTimeLabel.font = [UIFont systemFontOfSize:10];
    _recordTimeLabel.textColor = [UIColor whiteColor];
    _recordTimeLabel.textAlignment = NSTextAlignmentLeft;
    [_recordTimeLabel sizeToFit];
    _recordTimeLabel.center = CGPointMake(CGRectGetMaxX(_progressView.frame) - _recordTimeLabel.frame.size.width / 2, _progressView.frame.origin.y - _recordTimeLabel.frame.size.height);
    [self.view addSubview:_recordTimeLabel];
    
}

-(void)onBtnRecordStartClicked
{
    _videoRecording = !_videoRecording;
    
    if (_videoRecording)
    {
        [self startVideoRecord];
    }
    else
    {
        [self stopVideoRecord];
    }
}

-(void)startCameraPreview
{

    if (_cameraPreviewing == NO)
    {
        //简单设置
        //        TXUGCSimpleConfig * param = [[TXUGCSimpleConfig alloc] init];
        //        param.videoQuality = VIDEO_QUALITY_MEDIUM;
        //        [[TXUGCRecord shareInstance] startCameraSimple:param preview:_videoRecordView];
        //自定义设置
        TXUGCCustomConfig * param = [[TXUGCCustomConfig alloc] init];
        param.videoResolution =  VIDEO_RESOLUTION_540_960;
        param.videoFPS = 20;
        param.videoBitratePIN = 1200;
        [[TXUGCRecord shareInstance] startCameraCustom:param preview:_videoRecordView];

        [_vBeauty resetValues];
        _cameraPreviewing = YES;
    }

}

-(void)stopCameraPreview
{
    if (_cameraPreviewing == YES)
    {
        [[TXUGCRecord shareInstance] stopCameraPreview];
        _cameraPreviewing = NO;
    }
}

-(void)startVideoRecord
{
    [self refreshRecordTime:0];
    [self startCameraPreview];
    [[TXUGCRecord shareInstance] startRecord];
    
    [_btnStartRecord setImage:[UIImage imageNamed:@"stoprecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"stoprecord_press"] forState:UIControlStateSelected];

}

-(void)stopVideoRecord
{
    [[TXUGCRecord shareInstance] stopRecord];
    
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord"] forState:UIControlStateNormal];
    [_btnStartRecord setImage:[UIImage imageNamed:@"startrecord_press"] forState:UIControlStateSelected];
}

//-(void)onBtnCloseClicked
//{
//    [self stopCameraPreview];
//    [self stopVideoRecord];
//    
//    [self.navigationController popViewControllerAnimated:YES];
//}

-(void)onBtnCameraClicked
{
    _cameraFront = !_cameraFront;
    
    if (_cameraFront)
    {
        [_btnCamera setImage:[UIImage imageNamed:@"cameraex"] forState:UIControlStateNormal];
    }
    else
    {
        [_btnCamera setImage:[UIImage imageNamed:@"cameraex_press"] forState:UIControlStateNormal];
    }
    
    [[TXUGCRecord shareInstance] switchCamera:_cameraFront];
}

//-(void)onBtnLampClicked
//{
//    _lampOpened = !_lampOpened;
//    
//    BOOL result = [[TXUGCRecord shareInstance] toggleTorch:_lampOpened];
//    if (result == NO)
//    {
//        _lampOpened = !_lampOpened;
//        [self toastTip:@"闪光灯启动失败"];
//    }
//    
//    if (_lampOpened)
//    {
//        [_btnLamp setImage:[UIImage imageNamed:@"lamp_press"] forState:UIControlStateNormal];
//    }
//    else
//    {
//        [_btnLamp setImage:[UIImage imageNamed:@"lamp"] forState:UIControlStateNormal];
//    }
//    
//}

-(void)onBtnBeautyClicked
{
    _bottomViewShow = !_bottomViewShow;
    
    if (_bottomViewShow)
    {
        [_btnBeauty setImage:[UIImage imageNamed:@"beautyex_press"] forState:UIControlStateNormal];
    }
    else
    {
        [_btnBeauty setImage:[UIImage imageNamed:@"beautyex"] forState:UIControlStateNormal];
    }
    
    _vBeauty.hidden = !_bottomViewShow;
//    [_vBeauty resetValues];
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_bottomViewShow)
    {
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint _touchPoint = [touch locationInView:self.view];
        if (NO == CGRectContainsPoint(_vBeauty.frame, _touchPoint))
        {
            [self onBtnBeautyClicked];
        }
    }
}

#pragma mark - BeautySettingPanelDelegate
- (void)onSetBeautyDepth:(float)beautyDepth WhiteningDepth:(float)whiteningDepth
{
    [[TXUGCRecord shareInstance] setBeautyDepth:beautyDepth WhiteningDepth:whiteningDepth];
}

- (void)onSetEyeScaleLevel:(float)eyeScaleLevel
{
    [[TXUGCRecord shareInstance] setEyeScaleLevel:eyeScaleLevel];
}

- (void)onSetFaceScaleLevel:(float)faceScaleLevel
{
    [[TXUGCRecord shareInstance] setFaceScaleLevel:faceScaleLevel];
}

- (void)onSetFilter:(UIImage*)filterImage
{
    [[TXUGCRecord shareInstance] setFilter:filterImage];
}

- (void)onSetGreenScreenFile:(NSURL *)file
{
    [[TXUGCRecord shareInstance] setGreenScreenFile:file];
}

- (void)onSelectMotionTmpl:(NSString *)tmplName inDir:(NSString *)tmplDir
{
    [[TXUGCRecord shareInstance] selectMotionTmpl:tmplName inDir:tmplDir];
}

#pragma mark ---- Video Beauty UI ----
-(void)initBeautyUI
{
    _vBeauty = [[BeautySettingPanel alloc] init];
    _vBeauty.hidden = YES;
    _vBeauty.delegate = self;
    [self.view addSubview:_vBeauty];
}


-(void)refreshRecordTime:(int)second
{
    _currentRecordTime = second;
    _progressView.progress = (float)_currentRecordTime / MAX_RECORD_TIME;
    int min = second / 60;
    int sec = second % 60;
    
    [_recordTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d", min, sec]];
    [_recordTimeLabel sizeToFit];
}

#pragma mark ---- VideoRecordListener ----
-(void) onRecordProgress:(NSInteger)milliSecond;
{
    if (milliSecond > MAX_RECORD_TIME * 1000)
    {
        [self onBtnRecordStartClicked];
    }
    else
    {
        [self refreshRecordTime: milliSecond / 1000];
    }
}

-(void) onRecordComplete:(TXRecordResult*)result;
{
    if (_appForeground)
    {
        if (_currentRecordTime >= MIN_RECORD_TIME)
        {
            if (result.retCode == RECORD_RESULT_OK) {
                VideoPreviewViewController* vc = [[VideoPreviewViewController alloc] initWithCoverImage:result.coverImage videoPath:result.videoPath];
                UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self presentViewController:nav animated:YES completion:nil];
            }
            else {
                [self toastTip:@"录制失败"];
            }
        } else {
            [self toastTip:@"至少要录够5秒"];
        }
    }
    
    [self refreshRecordTime:0];
}

#pragma mark - Misc Methods

- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 100;
    frameRC.size.height -= 100;
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

@end
