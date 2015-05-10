//
//  KRMixTemplateView.m
//  V1.4
//
//  Created by Kalvar on 13/5/7.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRMixTemplateView.h"
#import <QuartzCore/QuartzCore.h>

@interface KRMixTemplateView ()

@end

@interface KRMixTemplateView (fixPrivate)

-(void)_makeTitleLabel;

@end

@implementation KRMixTemplateView (fixPrivate)

-(void)_makeTitleLabel
{
    [self.titleLabel setHidden:NO];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    switch ( self.krMixTemplateTitleLabelMode )
    {
        case KRMixTemplateTitleLabelMode1:
            //模式 1
            [self.titleLabel setFrame:CGRectMake(14.0f, 278.0f, 306.0f, 42.0f)];
            [self.titleLabel setFont:[UIFont systemFontOfSize:30.0f]];
            [self.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [self.titleLabel setTextColor:[UIColor whiteColor]];
            break;
        case KRMixTemplateTitleLabelMode2:
            //模式 2
            [self.titleLabel setFrame:CGRectMake(14.0f, 232.0f, 306.0f, 34.0f)];
            [self.titleLabel setFont:[UIFont systemFontOfSize:24.0f]];
            [self.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [self.titleLabel setTextColor:[UIColor whiteColor]];
            break;
        case KRMixTemplateTitleLabelMode8:
            //模式 8
            [self.titleLabel setFrame:CGRectMake(8.0f, 259.0f, 306.0f, 53.0f)];
            [self.titleLabel setFont:[UIFont systemFontOfSize:62.0f]];
            [self.titleLabel setTextAlignment:NSTextAlignmentLeft];
            [self.titleLabel setTextColor:[UIColor whiteColor]];
            break;
        case KRMixTemplateTitleLabelMode9:
            //模式 9
            [self.titleLabel setFrame:CGRectMake(4.0f, 263.0f, 313.0f, 53.0f)];
            [self.titleLabel setFont:[UIFont systemFontOfSize:54.0f]];
            [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [self.titleLabel setTextColor:[UIColor whiteColor]];
            break;
        case KRMixTemplateTitleLabelMode10:
            //模式 10
            [self.titleLabel setFrame:CGRectMake(0.0f, 270.0f, 320.0f, 58.0f)];
            [self.titleLabel setFont:[UIFont systemFontOfSize:32.0f]];
            [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
            [self.titleLabel setTextColor:[UIColor whiteColor]];
            [self.titleLabel setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f]];
            break;
        default:
            //Nothing
            [self.titleLabel setHidden:YES];
            break;
    }
}

@end

@implementation KRMixTemplateView

@synthesize imageId;
@synthesize imageView;
@synthesize titleLabel;
@synthesize krMixTemplateTitleLabelMode = _krMixTemplateTitleLabelMode;
@synthesize displayImage                = _displayImage;


-(id)init
{
    NSArray *_loadedNibs = [[NSBundle mainBundle] loadNibNamed:@"KRMixTemplateView" owner:self options:nil];
    if( !_loadedNibs || _loadedNibs.count < 1 )
    {
        return nil;
    }
    self = [_loadedNibs objectAtIndex:0];
    if (self)
    {
        self.krMixTemplateTitleLabelMode = KRMixTemplateTitleLabelModeNothing;
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [self init];
    if (self)
    {
        [self setFrame:frame];
        //self.krMixTemplateTitleLabelMode = KRMixTemplateTitleLabelModeNothing;
    }
    return self;
}

/*
 * @ 將指定的 UIView 整個螢幕截圖存成 UIImage
 */
-(UIImage *)captureImageFromView
{    
    UIView *theView = self;
    /*
     * @ 指定繪圖區域
     *   - 如果有 UIGraphicsBeginImageContextWithOptions() 函式的存在，就使用該函式開始製作繪圖區域
     */
    if( NULL != UIGraphicsBeginImageContextWithOptions )
    {
        //設定邊界大小和影像透明度與縮放倍數
        UIGraphicsBeginImageContextWithOptions(theView.bounds.size, NO, 2.0f);
        //UIGraphicsBeginImageContextWithOptions(theView.bounds.size, theView.opaque, 2.0f);
    }
    else
    {
        //iOS 4.0 以下版本使用
        UIGraphicsBeginImageContext(theView.frame.size);
    }
    [theView.layer renderInContext:UIGraphicsGetCurrentContext()];
    //取得影像
    UIImage *captureImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return captureImage;
}

/*
 * @ 取得當前顯示的圖
 */
-(UIImage *)displayImage
{
    return [imageView image];
}

-(void)display
{
    [self _makeTitleLabel];
}


@end
