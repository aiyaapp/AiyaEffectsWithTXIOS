#import <Foundation/Foundation.h>
#import "StreamUrlScanner.h"
#import "ScanQRController.h"


@interface StreamUrlScanner()<UITextFieldDelegate, ScanQRDelegate, UITextViewDelegate>
{
    UITextField *   _textField;
}
@end

@implementation StreamUrlScanner

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    UIView * backgroundView = [[UIView alloc] initWithFrame:frame];
    backgroundView.backgroundColor = [UIColor grayColor];
    backgroundView.alpha = 0.2;
    [self addSubview:backgroundView];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = screenSize.width / 10;
    
    int contentWidth = screenSize.width - 2 * 10;
    int contentHeight = 0;
    
    UIView * contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor blackColor];
    contentView.layer.cornerRadius = 8;
    contentView.layer.masksToBounds = YES;
    [self addSubview:contentView];
    
    int offsetY = 15;
    UILabel* label = [[UILabel alloc]init];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [label setText:@"添加拉流"];
    [label sizeToFit];
    [label setTextColor:[UIColor whiteColor]];
    label.frame = CGRectMake((contentWidth - CGRectGetWidth(label.frame)) / 2, offsetY, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));
    [contentView addSubview:label];
    
    offsetY = CGRectGetMaxY(label.frame) + 23;
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(10, offsetY, contentWidth - 20 - ICON_SIZE - 5, ICON_SIZE)];
    _textField.placeholder = @"请输入或扫二维码获取播放地址";
    _textField.background = [UIImage imageNamed:@"Input_box"];
    _textField.alpha = 0.5;
    _textField.autocapitalizationType = UITextAutocorrectionTypeNo;
    _textField.delegate = self;
    _textField.text = @"";
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    [contentView addSubview:_textField];
    
    UIButton* btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame = CGRectMake(contentWidth - 10 - ICON_SIZE, offsetY, ICON_SIZE, ICON_SIZE);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self action:@selector(clickScan:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:btnScan];
    
    offsetY = CGRectGetMaxY(_textField.frame) + 2;
    UITextView* noticeText = [[UITextView alloc] initWithFrame:CGRectMake(5, offsetY, contentWidth - 10, 50)];
    [contentView addSubview:noticeText];
     
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"注意：拉流地址必须添加防盗链key，请参考IOS视频连麦方案"];
    [str addAttribute: NSLinkAttributeName value:@"url" range:NSMakeRange(21, 9)];
    noticeText.attributedText = str;
    noticeText.delegate = self;
    noticeText.textColor = [UIColor whiteColor];
    noticeText.backgroundColor = [UIColor clearColor];
    noticeText.editable = NO;
    noticeText.scrollEnabled =NO;
    
    offsetY = CGRectGetMaxY(noticeText.frame) + 20;
    UIButton* btnConfirm = [UIButton buttonWithType:UIButtonTypeCustom];
    btnConfirm.frame = CGRectMake(10, offsetY, contentWidth - 20, 35);
    [btnConfirm setBackgroundImage:[UIImage imageNamed:@"button_green"] forState:UIControlStateNormal];
    [btnConfirm setBackgroundImage:[UIImage imageNamed:@"button_green_pressed"] forState:UIControlStateHighlighted];
    [btnConfirm setTitle:@"确定" forState:UIControlStateNormal];
    [btnConfirm addTarget:self action:@selector(clickConfirm:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:btnConfirm];
    
    offsetY = CGRectGetMaxY(btnConfirm.frame) + 15;
    UIButton* btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCancel.frame = CGRectMake(10, offsetY, contentWidth - 20, 35);
    [btnCancel setBackgroundImage:[UIImage imageNamed:@"button_gray"] forState:UIControlStateNormal];
    [btnCancel setBackgroundImage:[UIImage imageNamed:@"button_gray_pressed"] forState:UIControlStateHighlighted];
    [btnCancel setTitle:@"取消" forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(clickCancel:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:btnCancel];

    contentHeight = CGRectGetMaxY(btnCancel.frame) + 15;
    
    contentView.frame = CGRectMake(0, 0, contentWidth, contentHeight);
    contentView.center = CGPointMake(screenSize.width / 2, screenSize.height / 2);
    
    return self;
}

-(void) setHidden:(BOOL)hidden
{
    _textField.text = @"";
    [super setHidden:hidden];
}

-(void) clickScan:(UIButton*) btn
{
    ScanQRController* vc = [[ScanQRController alloc] init];
    vc.delegate = self;
//    vc.textField = _textField;
    [self.hostViewController.navigationController pushViewController:vc animated:NO];
}

-(void) clickConfirm:(UIButton*) btn
{
    [self.delegate onStreamUrlScannerConfirm:_textField.text];
}

-(void) clickCancel:(UIButton*) btn
{
    [self.delegate onStreamUrlScannerCancel];
}

#pragma -- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -- ScanQRDelegate
- (void)onScanResult:(NSString *)result
{
    _textField.text = result;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.qcloud.com/document/product/454/9848"]];
    return NO;
}

@end
