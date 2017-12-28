#ifndef LinkMicPlayItem_h
#define LinkMicPlayItem_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TXLivePlayer.h"

@interface LinkMicPlayItem : NSObject<TXLivePlayListener>
@property (nonatomic, strong) UIView*      videoView;
@property (nonatomic, assign) BOOL         running;

-(BOOL)startPlay:(NSString*)playUrl;
-(void)stopPlay;
-(void)showLog:(BOOL)show;
@end



#endif /* MicLinkPlayItem_h */
