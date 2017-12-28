#import <Foundation/Foundation.h>
#import "LinkMicPlayItem.h"

@interface LinkMicPlayItem()
{
    UIView*                 _loadingBackground;
    UIImageView *           _loadingImageView;

    UIView*                 _logView;
    UITextView*         	_statusView;
    UITextView*         	_eventView;
    
    UIButton*               _btnStop;
    
    NSString*       		_eventMsg;
    NSString*               _playUrl;
    TXLivePlayer*           _txLivePlayer;
}
@end

@implementation LinkMicPlayItem
- (instancetype)init
{
    if (self = [super init])
    {
        _txLivePlayer = [[TXLivePlayer alloc] init];
        _txLivePlayer.enableHWAcceleration = YES;
        _txLivePlayer.delegate = self;
    }
    return self;
}

-(void)setVideoView:(UIView *)videoView {
    _videoView = videoView;
    CGRect rect = _videoView.frame;
    
    if (_loadingBackground == nil) {
        _loadingBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect))];
        _loadingBackground.hidden = YES;
        _loadingBackground.backgroundColor = [UIColor blackColor];
        _loadingBackground.alpha  = 0.5;
        [_videoView addSubview:_loadingBackground];
    }
    
    if (_loadingImageView == nil) {
        float width = 30;
        float height = 30;
        NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:[UIImage imageNamed:@"loading_image0.png"],
                                 [UIImage imageNamed:@"loading_image0.png"],
                                 [UIImage imageNamed:@"loading_image1.png"],
                                 [UIImage imageNamed:@"loading_image2.png"],
                                 [UIImage imageNamed:@"loading_image3.png"],
                                 [UIImage imageNamed:@"loading_image4.png"],
                                 [UIImage imageNamed:@"loading_image5.png"],
                                 [UIImage imageNamed:@"loading_image6.png"],
                                 [UIImage imageNamed:@"loading_image7.png"],
                                 nil];
        _loadingImageView = [[UIImageView alloc] init];
        _loadingImageView.bounds = CGRectMake(0, 0, width, height);
        _loadingImageView.center = CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect) / 2);;
        _loadingImageView.animationImages = array;
        _loadingImageView.animationDuration = 1;
        _loadingImageView.hidden = YES;
        [_videoView addSubview:_loadingImageView];
    }

    if (_logView == nil) {
        _logView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_videoView.frame),  CGRectGetHeight(_videoView.frame))];
        _logView.hidden = YES;
        _logView.backgroundColor = [UIColor whiteColor];
        _logView.alpha  = 0.5;
        [_videoView addSubview:_logView];
        
        CGRect rect = _logView.frame;
        int logheadH = CGRectGetHeight(rect) / 2 - 5;
        
        _statusView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(rect),  logheadH)];
        _statusView.backgroundColor = [UIColor clearColor];
        _statusView.alpha = 1;
        _statusView.textColor = [UIColor blackColor];
        _statusView.editable = NO;
        _statusView.hidden = NO;
        [_logView addSubview:_statusView];
        
        _eventView = [[UITextView alloc] initWithFrame:CGRectMake(0, logheadH, CGRectGetWidth(rect), CGRectGetHeight(rect) - logheadH)];
        _eventView.backgroundColor = [UIColor clearColor];
        _eventView.alpha = 1;
        _eventView.textColor = [UIColor blackColor];
        _eventView.editable = NO;
        _eventView.hidden = NO;
        [_logView addSubview:_eventView];
    }
    
    if (_btnStop == nil)
    {
        int ICON_SIZE = 15;
        _btnStop = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnStop.frame = CGRectMake(CGRectGetWidth(_videoView.frame) - ICON_SIZE - 2, 2, ICON_SIZE, ICON_SIZE);
        [_btnStop setImage:[UIImage imageNamed:@"stopplay"] forState:UIControlStateNormal];
        _btnStop.hidden = YES;
        [_btnStop addTarget:self action:@selector(clickStopBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_videoView addSubview:_btnStop];
    }
}

-(void) clickStopBtn:(UIButton*) btn
{
    [self stopPlay];
}

-(BOOL)startPlay:(NSString*)playUrl
{
    if (playUrl != nil && [self checkPlayUrl:playUrl] != -1)
    {
        int playType = [self checkPlayUrl:playUrl];
        if (playType != -1) {
            _playUrl = playUrl;
            _running = YES;
            _btnStop.hidden = YES;
            _eventMsg = @"";
            
            [self startLoading];
            
            [_txLivePlayer setupVideoWidget:CGRectMake(0, 0, 0, 0) containView:_videoView insertIndex:0];
            [_txLivePlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
            if ([self getParamsFromStreamUrl:@"bizid" streamUrl:playUrl] == nil ||
                [self getParamsFromStreamUrl:@"txSecret" streamUrl:playUrl] == nil ||
                [self getParamsFromStreamUrl:@"txTime" streamUrl:playUrl] == nil) {
                [_txLivePlayer startPlay:playUrl type:playType];
            }
            else {
                [_txLivePlayer startPlay:playUrl type:PLAY_TYPE_LIVE_RTMP_ACC];
            }
        }

        return YES;
    }
    
    return NO;
}

-(void)stopPlay
{
    [_txLivePlayer stopPlay];
    [_txLivePlayer removeVideoWidget];
    
    _playUrl = @"";
    _running = NO;
    _btnStop.hidden = YES;
    
    [self stopLoading];
}

-(void)startLoading {
    if (_loadingBackground) {
        _loadingBackground.hidden = NO;
    }
    
    if (_loadingImageView) {
        _loadingImageView.hidden = NO;
        [_loadingImageView startAnimating];
    }
}

-(void)stopLoading {
    if (_loadingBackground) {
        _loadingBackground.hidden = YES;
    }
    
    if (_loadingImageView) {
        _loadingImageView.hidden = YES;
        [_loadingImageView stopAnimating];
    }
}

-(void) showLog:(BOOL)show
{
    if (_running) {
        if (_logView) {
            _logView.hidden = !show;
        }
    }
    else {
        _logView.hidden = YES;
    }
}

-(void) onPlayEvent:(int)evtID withParam:(NSDictionary*)param {
    long long time = [(NSNumber*)[param valueForKey:EVT_TIME] longLongValue];
    int mil = time % 1000;
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:time/1000];
    NSString* Msg = (NSString*)[param valueForKey:EVT_MSG];
    
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString* timeStr = [format stringFromDate:date];
    NSString* log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", timeStr, mil, Msg];
    if (_eventMsg == nil || _eventMsg.length == 0) {
        _eventMsg = log;
    }
    else {
        _eventMsg = [NSString stringWithFormat:@"%@\n%@", _eventMsg, log];
    }
    
    [_eventView setText:_eventMsg];
    
    
    if (evtID == PLAY_EVT_PLAY_BEGIN)
    {
        _btnStop.hidden = NO;
        [self stopLoading];
    }
    else if (evtID == PLAY_ERR_NET_DISCONNECT || evtID == PLAY_EVT_PLAY_END || evtID == PLAY_ERR_GET_RTMP_ACC_URL_FAIL)
    {
        [self stopPlay];
    }
}

-(void) onNetStatus:(NSDictionary*) param {
    int netspeed  = [(NSNumber*)[param valueForKey:NET_STATUS_NET_SPEED] intValue];
    int vbitrate  = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
    int abitrate  = [(NSNumber*)[param valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
    int cachesize = [(NSNumber*)[param valueForKey:NET_STATUS_CACHE_SIZE] intValue];
    int dropsize  = [(NSNumber*)[param valueForKey:NET_STATUS_DROP_SIZE] intValue];
    int jitter    = [(NSNumber*)[param valueForKey:NET_STATUS_NET_JITTER] intValue];
    int fps       = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_FPS] intValue];
    int width     = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
    int height    = [(NSNumber*)[param valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
    float cpu_usage = [(NSNumber*)[param valueForKey:NET_STATUS_CPU_USAGE] floatValue];
    NSString *serverIP = [param valueForKey:NET_STATUS_SERVER_IP];
    int codecCacheSize = [(NSNumber*)[param valueForKey:NET_STATUS_CODEC_CACHE] intValue];
    int nCodecDropCnt = [(NSNumber*)[param valueForKey:NET_STATUS_CODEC_DROP_CNT] intValue];
    
    NSString* statusMsg = [NSString stringWithFormat:@"CPU:%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t",
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
    
    [_statusView setText:statusMsg];
}

-(int)checkPlayUrl:(NSString*)playUrl {
    if (!([playUrl hasPrefix:@"http:"] || [playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"rtmp:"] )) {
        return -1;
    }
    
    if ([playUrl hasPrefix:@"rtmp:"]) {
        return PLAY_TYPE_LIVE_RTMP;
    } else if (([playUrl hasPrefix:@"https:"] || [playUrl hasPrefix:@"http:"]) && [playUrl rangeOfString:@".flv"].length > 0) {
        return PLAY_TYPE_LIVE_FLV;
    } else{
        return -1;
    }
}

-(NSString*) getParamsFromStreamUrl: (NSString*)paramName streamUrl:(NSString*)streamUrl {
    if (paramName == nil || paramName.length == 0 || streamUrl == nil || streamUrl.length == 0) {
        return nil;
    }
    
    paramName = [paramName lowercaseString];
    NSArray* strArrays = [streamUrl componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?&"]];
    for (NSString* strItem in strArrays) {
        if ([strItem rangeOfString:@"="].location != NSNotFound) {
            NSArray* array =  [strItem componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
            if ([array count] == 2) {
                NSString* name = [array objectAtIndex:0];
                NSString* value = [array objectAtIndex:1];
                if (name != nil) {
                    name = [name lowercaseString];
                    if ([name isEqualToString:paramName]) {
                        return value;
                    }
                }
            }
        }
    }
    
    return nil;
}
@end

