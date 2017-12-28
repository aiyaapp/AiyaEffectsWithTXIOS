#import <UIKit/UIKit.h>

/**
 *  短视频预览VC
 */
@class TXRecordResult;
@interface VideoPreviewViewController : UIViewController
- (instancetype)initWithCoverImage:(UIImage *)coverImage videoPath:(NSString*)videoPath;
@end
