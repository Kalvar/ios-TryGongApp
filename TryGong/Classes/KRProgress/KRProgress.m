//
//  KRProgress.m
//  
//
//  Created by Kalvar on 13/2/2.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRProgress.h"

#define KRP_VIEW_TAG      99995
#define KRP_TIP_LABEL_TAG 99996
static NSInteger _krpActivityBackgroundViewTag = 99997;

@interface KRProgress (){
    
}

@property (nonatomic, strong) UIView *_activeView;
@property (nonatomic, strong) UIActivityIndicatorView *_activeIcon;
@property (nonatomic, strong) UIAlertView *_activeAlertView;

@end

@interface KRProgress (fixPrivate)

-(void)_initWithVars;

@end

@implementation KRProgress (fixPrivate)

-(void)_initWithVars{
    self.view = nil;
    self.activityStyle = UIActivityIndicatorViewStyleWhite;
    self.tip  = @"Loading ...";
}

//刪除 UIView 裡的 LoadingIcon
-(void)_removeActivityIndicatorsFromView:(UIView *)_targetView{
    if( _targetView ){
        for(UIView *subview in [_targetView subviews]) {
            if([subview isKindOfClass:[UIActivityIndicatorView class]]) {
                [(UIActivityIndicatorView *)subview stopAnimating];
                [subview removeFromSuperview];
                break;
            }
        }
    }
}

//刪除 UIView 裡的 UILabel
-(void)_removeLabelsFromView:(UIView *)_targetView{
    if( _targetView ){
        for(UIView *subview in [_targetView subviews]) {
            if([subview isKindOfClass:[UILabel class]]) {
                [subview removeFromSuperview];
            }
        }
    }
}

//設定在目標 View 裡的提示小文字
-(void)_setupTipTitleInTargetView:(NSArray *)_configs{
    if( [_configs count] < 2 ) return;
    UIView *_targetView = [_configs objectAtIndex:0];
    NSString *_tipTitle = [_configs objectAtIndex:1];
    if( !_tipTitle ) _tipTitle = @"";
    [self startOnTranslucentView:_targetView];
    CGRect _frame    = _targetView.frame;
    CGFloat _width   = _frame.size.width;
    CGFloat _height  = 25.0f;
    CGFloat _offset  = 15.0f;
    //Loading Icon 是 37 x 37 (Large)
    CGFloat _x = ( _frame.size.width / 2.0f ) - ( _width / 2.0f );
    CGFloat _y = ( _frame.size.height / 2.0f ) - ( _height / 2.0f ) + 20.0f + _offset;
    UILabel *_tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(_x, _y, _width, _height)];
    [_tipLabel setText:_tipTitle];
    [_tipLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    [_tipLabel setTextAlignment:NSTextAlignmentCenter];
    [_tipLabel setBackgroundColor:[UIColor clearColor]];
    [_tipLabel setFont:[UIFont fontWithName:@"Arial" size:15.0f]];
    [_tipLabel setTag:KRP_TIP_LABEL_TAG];
    [_targetView addSubview:_tipLabel];
}

@end

@implementation KRProgress

@synthesize view = _view;
@synthesize activityStyle;
@synthesize tip = _tip;
//
@synthesize _activeView, _activeIcon, _activeAlertView;


-(id)init{
    self = [super init];
    if( self ){
        [self _initWithVars];
        _activeAlertView  = [[UIAlertView alloc] initWithTitle:self.tip
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:nil
                                             otherButtonTitles:nil];
        _activeIcon = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityStyle];
    }
    return self;
}

/*
 * 是否目標 UIView 上已有 Loading Icon ?
 */
-(BOOL)isActivityOnView:(UIView *)_targetView{
    for( UIView *subview in _targetView.subviews ){
        if( [subview isKindOfClass:[UIActivityIndicatorView class]] ){
            return YES;
            break;
        }
    }
    return NO;
}

/*
 * @ 啟動 AlertView 的 Loading 載入畫面
 *
 *   - 如果在使用上出現 Error : 10004003 的問題，
 *     就使用 [self performSelectorInBackground:@selector(loadingStartWithAlertView) withObject:nil]; 來解決。
 */
-(void)startOnAlertViewWithTitle:(NSString *)_title{
    if( !self._activeAlertView.isVisible ){
        self.tip = _title;
        dispatch_queue_t queue = dispatch_queue_create("_addUploadPhotoQueue", NULL);
        dispatch_async(queue, ^(void){
            if( _title ){
                self._activeAlertView.title = _title;
            }
            [self._activeAlertView show];
            self._activeIcon.center = CGPointMake(self._activeAlertView.bounds.size.width / 2.0f,
                                                  self._activeAlertView.bounds.size.height - 40.0f);
            [self._activeIcon startAnimating];
            [self._activeAlertView addSubview:self._activeIcon];
            //
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
                
            });
        });
    }
}

/*
 * @ 停止 AlertView 的 Loading 載入畫面
 */
-(void)stopAlertView{
    if( self._activeAlertView.isVisible ){
        [self._activeAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

/*
 * @ 動態改變 Loading AlertView 的 Title
 */
-(void)changeAlertViewTitle:(NSString *)_title{
    self.tip = _title;
    self._activeAlertView.title = self.tip;
}

/*
 * @ 動態改變 Loading View 的 Tip 提示
 */
-(void)changeTip:(NSString *)_tipTitle withView:(UIView *)_targetView{
    UILabel *_tipLabel = (UILabel *)[_targetView viewWithTag:KRP_TIP_LABEL_TAG];
    if( _tipLabel ){
        self.tip = _tipTitle;
        [_tipLabel setText:self.tip];
    }
}

/*
 * 直接在 ImageView 裡插入 LoadingIcon
 */
-(void)startOnImageView:(UIImageView *)_targetImageView{
    [self startOnView:_targetImageView];
}

/*
 * 直接在 ImageView 裡插入 LoadingIcon 並自訂顏色
 */
-(void)startOnImageView:(UIImageView *)_targetImageView withColor:(UIColor *)_iconColor{
    [self startOnView:_targetImageView withColor:_iconColor];
}

/*
 * 移除在 ImageView 裡的 LoadingIcon
 */
-(void)stopFromImageView:(UIImageView *)_targetImageView{
    [self _removeActivityIndicatorsFromView:_targetImageView];
}

/*
 * 在背景執行 ( 好像沒用 XD )
 */
-(void)startBackgroundOnView:(UIView *)_targetView{
    [self performSelectorInBackground:@selector(startOnView:) withObject:_targetView];
}

/*
 * 直接在 UIView 裡插入 / 刪除 LoadingIcon
 */
-(void)startOnView:(UIView *)_targetView{
    [self startOnView:_targetView withColor:[UIColor whiteColor]];
}

-(void)stopFromView:(UIView *)_targetView{
    [self _removeActivityIndicatorsFromView:_targetView];
}

/*
 * 直接在 UIView 裡插入 / 刪除 LoadingIcon 並自訂 Loading 顏色
 */
-(void)startOnView:(UIView *)_targetView withColor:(UIColor *)_iconColor{
    if( !_iconColor ){
        _iconColor = [UIColor whiteColor];
    }
    if( !self.activityStyle ) self.activityStyle = UIActivityIndicatorViewStyleWhiteLarge;
    UIActivityIndicatorView *_loadingIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithActivityIndicatorStyle:self.activityStyle];
    _loadingIndicator.center = CGPointMake(_targetView.bounds.size.width / 2.0f,
                                           _targetView.bounds.size.height / 2.0f);
    [_loadingIndicator setColor:_iconColor];
    [_loadingIndicator startAnimating];
    [_targetView addSubview:_loadingIndicator];
}

/*
 * @ 直接在 UIView 裡插入 / 刪除 LoadingIcon 並自訂 Loading 顏色 / 自訂位置
 */
-(void)startOnView:(UIView *)_targetView withColor:(UIColor *)_iconColor withPoints:(CGPoint)_iconPoints{
    if( !_iconColor ){
        _iconColor = [UIColor whiteColor];
    }
    if( !self.activityStyle ) self.activityStyle = UIActivityIndicatorViewStyleWhiteLarge;
    UIActivityIndicatorView *_loadingIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithActivityIndicatorStyle:self.activityStyle];
    _loadingIndicator.center = _iconPoints;
    [_loadingIndicator setColor:_iconColor];
    [_loadingIndicator startAnimating];
    [_targetView addSubview:_loadingIndicator];
}

/*
 * @ 在背景執行
 *   - 直接在目標 View 裡插入 / 刪除 View，與半透明背景
 */
-(void)startBackgroundOnTranslucentView:(UIView *)_targetView{
    if( [self isActivityOnView:_targetView] ) return;
    [self performSelectorInBackground:@selector(startOnTranslucentView:) withObject:_targetView];
}

-(void)startBackgroundOnTranslucentView:(UIView *)_targetView tipTitle:(NSString *)_tipTitle{
    if( [self isActivityOnView:_targetView] ) return;
    [self performSelectorInBackground:@selector(_setupTipTitleInTargetView:)
                           withObject:[NSArray arrayWithObjects:_targetView, _tipTitle, nil]];
}

-(void)stopBackgroundFromTranslucentView:(UIView *)_targetView{
    [self performSelectorInBackground:@selector(stopFromTranslucentView:) withObject:_targetView];
}

-(void)stopBackgroundFromTranslucentViewAndRemoveTipTitle:(UIView *)_targetView{
    [self performSelectorInBackground:@selector(stopFromTranslucentViewAndRemoveTipTitle:) withObject:_targetView];
}

/*
 * @ 
 */
-(void)startOnTranslucentView:(UIView *)_targetView{
    CGRect _frame = CGRectMake(0.0f, 0.0f, _targetView.frame.size.width, _targetView.frame.size.height);
    UIView *_backgroundView = [[UIView alloc] initWithFrame:_frame];
    [_backgroundView setTag:_krpActivityBackgroundViewTag];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    [_backgroundView setAlpha:1.0]; //2014.05.02 PM 22:13, 原先是 0.5f
    [_targetView addSubview:_backgroundView];
    [self startOnView:_targetView];
}

-(void)stopFromTranslucentView:(UIView *)_targetView{
    [self _removeActivityIndicatorsFromView:_targetView];
    if( [_targetView viewWithTag:_krpActivityBackgroundViewTag] ){
        [[_targetView viewWithTag:_krpActivityBackgroundViewTag] removeFromSuperview];
    }
}

/*
 * 直接在目標 View 裡插入 / 刪除 View，與半透明背景 + 自訂在 Loading 下方的提示小文字
 */
-(void)startOnTranslucentView:(UIView *)_targetView tipTitle:(NSString *)_tipTitle{
    self.tip = _tipTitle;
    [self _setupTipTitleInTargetView:[NSArray arrayWithObjects:_targetView, _tipTitle, nil]];
}

-(void)stopFromTranslucentViewAndRemoveTipTitle:(UIView *)_targetView{
    if( _targetView ){
        UILabel *_tipLabel = (UILabel *)[_targetView viewWithTag:KRP_TIP_LABEL_TAG];
        if( _tipLabel ){
            [_tipLabel removeFromSuperview];
        }
        [self stopFromTranslucentView:_targetView];
    }
}

/*
 * @ 提示類的 Loading 模式
 *   - 上方橫幅通知
 */
-(void)startTopStyleOnView:(UIView *)_targetView
{
    if( !self.activityStyle ) self.activityStyle = UIActivityIndicatorViewStyleWhite;
    CGRect _frame = CGRectMake(0.0f, 0.0f, _targetView.frame.size.width, 30.0f);
    UIView *_backgroundView = [[UIView alloc] initWithFrame:_frame];
    [_backgroundView setTag:_krpActivityBackgroundViewTag];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    [_backgroundView setAlpha:0.6f];
    [_targetView addSubview:_backgroundView];
    //
    UIActivityIndicatorView *_loadingIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithActivityIndicatorStyle:self.activityStyle];
    _loadingIndicator.center = CGPointMake(_frame.size.width / 2.0f,
                                           _frame.size.height / 2.0f);
    [_loadingIndicator setColor:[UIColor whiteColor]];
    [_loadingIndicator startAnimating];
    [_targetView addSubview:_loadingIndicator];
}

-(void)stopTopStyleFromView:(UIView *)_targetView
{
    [self _removeActivityIndicatorsFromView:_targetView];
    if( [_targetView viewWithTag:_krpActivityBackgroundViewTag] ){
        [[_targetView viewWithTag:_krpActivityBackgroundViewTag] removeFromSuperview];
    }
}

@end
