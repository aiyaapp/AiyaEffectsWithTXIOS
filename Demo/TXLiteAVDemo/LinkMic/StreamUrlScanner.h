#ifndef StreamUrlScanner_h
#define StreamUrlScanner_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol StreamUrlScannerDelegate <NSObject>

@optional
-(void) onStreamUrlScannerConfirm:(NSString*)streamUrl;

@optional
-(void) onStreamUrlScannerCancel;

@end

@interface StreamUrlScanner : UIView
@property (nonatomic, weak) id<StreamUrlScannerDelegate> delegate;
@property (nonatomic, weak) UIViewController* hostViewController;
@end


#endif /* StreamUrlScanner_h */
