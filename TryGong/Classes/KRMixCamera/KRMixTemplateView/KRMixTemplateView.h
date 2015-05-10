//
//  KRMixTemplateView.h
//  V1.4
//
//  Created by Kalvar on 13/5/7.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * @ 文字區塊的呈現模式
 */
typedef enum _KRMixTemplateTitleLabelModes
{
    KRMixTemplateTitleLabelModeNothing = 0,
    KRMixTemplateTitleLabelMode1,
	KRMixTemplateTitleLabelMode2,
    KRMixTemplateTitleLabelMode3,
    KRMixTemplateTitleLabelMode4,
    KRMixTemplateTitleLabelMode5,
    KRMixTemplateTitleLabelMode6,
    KRMixTemplateTitleLabelMode7,
    KRMixTemplateTitleLabelMode8,
    KRMixTemplateTitleLabelMode9,
    KRMixTemplateTitleLabelMode10
} KRMixTemplateTitleLabelModes;

@interface KRMixTemplateView : UIView
{
    //圖片 ID
    NSString *imageId;
    //圖片
    __weak UIImageView *imageView;
    //標題文字
    __weak UILabel *titleLabel;
    //文字區塊的呈現模式
    KRMixTemplateTitleLabelModes krMixTemplateTitleLabelMode;
    //當前顯示的圖片
    UIImage *displayImage;
}

@property (nonatomic, strong) NSString *imageId;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) KRMixTemplateTitleLabelModes krMixTemplateTitleLabelMode;
@property (nonatomic, strong) UIImage *displayImage;

-(UIImage *)captureImageFromView;
-(void)display;

@end
