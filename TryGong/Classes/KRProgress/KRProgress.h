//
//  KRProgress.h
//  
//
//  Created by Kalvar on 13/2/2.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KRProgress : NSObject{
    UIView *view;
    UIActivityIndicatorViewStyle activityStyle;
    NSString *tip;
}

@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityStyle;
@property (nonatomic, strong) NSString *tip;

//
-(BOOL)isActivityOnView:(UIView *)_targetView;
-(void)startOnAlertViewWithTitle:(NSString *)_title;
-(void)startOnImageView:(UIImageView *)_targetImageView;
-(void)startOnImageView:(UIImageView *)_targetImageView withColor:(UIColor *)_iconColor;
-(void)stopFromImageView:(UIImageView *)_targetImageView;
-(void)startBackgroundOnView:(UIView *)_targetView;
-(void)startOnView:(UIView *)_targetView withColor:(UIColor *)_iconColor;
-(void)startBackgroundOnTranslucentView:(UIView *)_targetView;
-(void)startBackgroundOnTranslucentView:(UIView *)_targetView tipTitle:(NSString *)_tipTitle;
-(void)startOnTranslucentView:(UIView *)_targetView;
-(void)startOnTranslucentView:(UIView *)_targetView tipTitle:(NSString *)_tipTitle;
//
-(void)changeAlertViewTitle:(NSString *)_title;
-(void)changeTip:(NSString *)_tipTitle withView:(UIView *)_targetView;
//
-(void)stopAlertView;
-(void)stopFromView:(UIView *)_targetView;
-(void)stopBackgroundFromTranslucentView:(UIView *)_targetView;
-(void)stopBackgroundFromTranslucentViewAndRemoveTipTitle:(UIView *)_targetView;
-(void)stopFromTranslucentView:(UIView *)_targetView;
-(void)stopFromTranslucentViewAndRemoveTipTitle:(UIView *)_targetView;
//
-(void)startOnView:(UIView *)_targetView withColor:(UIColor *)_iconColor withPoints:(CGPoint)_iconPoints;
//
-(void)startTopStyleOnView:(UIView *)_targetView;
-(void)stopTopStyleFromView:(UIView *)_targetView;

@end
