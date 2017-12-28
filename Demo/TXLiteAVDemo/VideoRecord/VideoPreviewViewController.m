
#import <Foundation/Foundation.h>
#import "VideoPreviewViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "TXLivePlayer.h"
#import "MBProgressHUD.h"

#define BUTTON_PREVIEW_SIZE         65
#define BUTTON_CONTROL_SIZE         40

@interface VideoPreviewViewController()<TXLivePlayListener>
{
    UIView *                        _videoPreview;
    UIButton *                      _btnStartPreview;
    UISlider *                      _sdPreviewSlider;
    
    int                             _recordType;
    UIImage *                       _coverImage;
    BOOL                            _previewing;
    BOOL                            _startPlay;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    
    NSString*                       _videoPath;
    TXLivePlayer                    *_livePlayer;
}
@end


@implementation VideoPreviewViewController


- (instancetype)initWithCoverImage:(UIImage *)coverImage videoPath:(NSString *)videoPath
{
    if (self = [super init])
    {
        _coverImage   = coverImage;
        _previewing   = NO;
        _startPlay    = NO;
        _videoPath =  videoPath;
        
        _livePlayer = [[TXLivePlayer alloc] init];
        _livePlayer.delegate = self;
        [_livePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initPreviewUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.translucent = YES;
    
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.hidden = _navigationBarHidden;

    
    [self stopVideoPreview:NO];
}

-(void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)dealloc{
    [_livePlayer removeVideoWidget];
    [_livePlayer stopPlay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onAppDidEnterBackGround:(UIApplication*)app
{
    [self stopVideoPreview:NO];
}

- (void)onAppWillEnterForeground:(UIApplication*)app
{
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

- (void)onAudioSessionEvent:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_previewing) {
            [self onBtnPreviewStartClicked];
        }
    }
}

-(void)startVideoPreview:(BOOL) startPlay
{
    if(startPlay == YES){
        [_livePlayer setupVideoWidget:CGRectZero containView:_videoPreview insertIndex:0];
        [_livePlayer startPlay:_videoPath type:PLAY_TYPE_LOCAL_VIDEO];
        
    }else{
        [_livePlayer resume];
    }
    
}

-(void)stopVideoPreview:(BOOL) stopPlay
{

    if(stopPlay == YES)
        [_livePlayer stopPlay];
    else
        [_livePlayer pause];

}

#pragma mark ---- Video Preview ----
-(void)initPreviewUI
{
    //[_livePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    self.title = @"视频回放";
    self.navigationItem.hidesBackButton = YES;
    

    UIImageView * coverImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    coverImageView.backgroundColor = UIColor.blackColor;
    coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    coverImageView.image = _coverImage;
    [self.view addSubview:coverImageView];
    
    _videoPreview = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview: _videoPreview];
    
    _btnStartPreview = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_PREVIEW_SIZE, BUTTON_PREVIEW_SIZE)];
    _btnStartPreview.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    [_btnStartPreview addTarget:self action:@selector(onBtnPreviewStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartPreview];
    
    UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDelete.center = CGPointMake(self.view.frame.size.width / 4, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
    [btnDelete setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [btnDelete setImage:[UIImage imageNamed:@"delete_press"] forState:UIControlStateSelected];
    [btnDelete addTarget:self action:@selector(onBtnDeleteClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDelete];
    
    UIButton *btnDownload = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDownload.center = CGPointMake(self.view.frame.size.width * 3 / 4, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
    [btnDownload setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    [btnDownload setImage:[UIImage imageNamed:@"download_press"] forState:UIControlStateSelected];
    [btnDownload addTarget:self action:@selector(onBtnDownloadClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDownload];
    
//    UIButton *btnShare = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
//    btnShare.center = CGPointMake(self.view.frame.size.width * 3 / 4, self.view.frame.size.height - BUTTON_CONTROL_SIZE - 5);
//    [btnShare setImage:[UIImage imageNamed:@"shareex"] forState:UIControlStateNormal];
//    [btnShare setImage:[UIImage imageNamed:@"shareex_press"] forState:UIControlStateSelected];
//    [btnShare addTarget:self action:@selector(onBtnShareClicked) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btnShare];
    
    _sdPreviewSlider = [[UISlider alloc] init];
    _sdPreviewSlider.frame = CGRectMake(0, 0, self.view.frame.size.width - 40, 60);
    _sdPreviewSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 80);
    [_sdPreviewSlider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdPreviewSlider addTarget:self action:@selector(onDragEnd:) forControlEvents:UIControlEventTouchUpInside];
    [_sdPreviewSlider addTarget:self action:@selector(onDragStart:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:_sdPreviewSlider];
}

-(void)onBtnPreviewStartClicked
{
    if (!_startPlay) {
        [self startVideoPreview:YES];
        _startPlay = YES;
    }
    _previewing = !_previewing;
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview_press"] forState:UIControlStateSelected];
    }
    else
    {
        [self stopVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    }
}

-(void)onBtnDownloadClicked
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:_videoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error != nil) {
            NSLog(@"save video fail:%@", error);
        }
    }];
    

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)onBtnDeleteClicked
{
    [[NSFileManager defaultManager] removeItemAtPath:_videoPath error:nil];

    //[self.navigationController popViewControllerAnimated:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)onBtnShareClicked
{
//    TCVideoPublishController *vc = [[TCVideoPublishController alloc] init:[TXUGCRecord shareInstance] recordType:_recordType RecordResult:_recordResult TCLiveInfo:_liveInfo];
//    [self.navigationController pushViewController:vc animated:YES];
    
//    TCVideoEditViewController *vc = [[TCVideoEditViewController alloc] init];
//    [vc setVideoPath:_recordResult.videoPath];
//    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onDragStart:(UISlider*)sender
{
    NSLog(@"onDragStart:%f", sender.value);

    if (_livePlayer.isPlaying)
        [_livePlayer pause];
}

- (void)onDragEnd:(UISlider*)sender
{
    NSLog(@"onDragEnd:%f", sender.value);
    if (_sdPreviewSlider.maximumValue > 5.0) {
        [_livePlayer seek:sender.value];
    }
    if (!_livePlayer.isPlaying) {
        [_livePlayer resume];

    }
}

#pragma mark - TXVideoPreviewListener
-(void) onPlayEvent:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    dispatch_async(dispatch_get_main_queue(), ^{
       if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            [_sdPreviewSlider setValue:progress];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            if (duration > 0 && _sdPreviewSlider.maximumValue != duration) {
                _sdPreviewSlider.minimumValue = 0;
                _sdPreviewSlider.maximumValue = duration;
            }
            return ;
       } else if(EvtID == PLAY_EVT_PLAY_END) {
           [_sdPreviewSlider setValue:0];
           [self stopVideoPreview:YES];
           [self startVideoPreview:YES];
       }
    });
}

-(void) onNetStatus:(NSDictionary*) param
{
    return;
}

@end
