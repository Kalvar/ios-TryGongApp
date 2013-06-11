//
//  KRToolbar.m
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 12/10/29.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "KRToolbar.h"

@interface KRToolbar ()

@property (nonatomic, assign) BOOL _slideUpToolbar;
@property (nonatomic, assign) CGFloat _lastX;
@property (nonatomic, assign) CGFloat _lastY;
@property (nonatomic, assign) CGPoint _initPoints;


@end

@interface KRToolbar (fixPrivate)

-(void)_initWithVars;
-(void)_moveToSitesWithView:(UIView *)_targetView toX:(float)_toX toY:(float)_toY;
-(void)_moveWithView:(UIView *)_viewObj distance:(float)_distance goBack:(BOOL)_isBack;
-(void)_slideUpWithFrame:(CGRect)_keyboardFrame;
-(void)_slideDown;
-(void)_keyboardWillShowOnDelay:(NSNotification *)notification;
-(void)_keyboardWillShow:(NSNotification *)notification;
-(void)_keyboardWillHide:(NSNotification *)notification;
-(void)_removeNotification;

@end

@implementation KRToolbar (fixPrivate)

-(void)_initWithVars{
    self._slideUpToolbar = NO;
    self.toolbar         = nil;
    self.view            = nil;
    self._lastX          = 0.0f;
    self._lastY          = 0.0f;
    self._initPoints     = CGPointZero;
    self.linkMove        = YES;
}

//直接移動 UIView 至指定座標位置
-(void)_moveToSitesWithView:(UIView *)_targetView
                        toX:(float)_toX
                        toY:(float)_toY
{
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _targetView.frame = CGRectMake(_toX,
                                       _toY,
                                       _targetView.frame.size.width,
                                       _targetView.frame.size.height);
    } completion:^(BOOL finished) {
        //...
    }];
}

//動態上下移動 UIView 位置
-(void)_moveWithView:(UIView *)_viewObj
            distance:(float)_distance
              goBack:(BOOL)_isBack
{
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        float moveX      = (float) _viewObj.frame.origin.x;
        float moveY      = (float) _viewObj.frame.origin.y;
        float moveWidth  = (float) _viewObj.frame.size.width;
        float moveHeight = (float) _viewObj.frame.size.height;
        if( !_isBack ){
            moveY -= _distance;
        }else{
            moveY += _distance;
        }
        _viewObj.frame = CGRectMake( moveX, moveY, moveWidth, moveHeight );
    } completion:^(BOOL finished) {
        //...
    }];
}

/*
 * Toolbar 事件執行
 */
-(void)_slideUpWithFrame:(CGRect)_keyboardFrame
{
    self.toolbar.hidden = NO;
    CGFloat _keyboardHeight = _keyboardFrame.size.height;
    CGFloat _toolbarHeight  = 44.0f;
    CGFloat _toolbarX       = self.toolbar.frame.origin.x;
    CGFloat _superviewY     = self.view.frame.origin.y;
    CGFloat _toolbarYOfNew  = self.view.frame.size.height - _keyboardHeight - _toolbarHeight;
    if( _superviewY < 0 ){
        _toolbarYOfNew -= _superviewY - self._initPoints.y;
    }
    
    if( [self.delegate respondsToSelector:@selector(krToolbar:slidingToPoints:)] ){
        [self.delegate krToolbar:self slidingToPoints:CGPointMake(_toolbarX, _toolbarYOfNew)];
    }
    
    CGFloat _diffY = self._lastY - _toolbarYOfNew;
    //文字選取格是 36.0f 的高
    CGFloat _tipHeight = 36.0f; //fabsf(_diffY);
    
    if( self._lastY != 0.0f ){
        //上昇
        if( _diffY > 0 ){
            if( self.linkMove ){
                [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew + _tipHeight];
                [self _moveWithView:self.view distance:_tipHeight goBack:NO];
            }else{
                [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew];
            }
            //[self _moveWithView:self.toolbar distance:_tipHeight goBack:YES];
            if( [self.delegate respondsToSelector:@selector(krToolbar:trackChangingSlideUpToPoints:)] ){
                [self.delegate krToolbar:self trackChangingSlideUpToPoints:CGPointMake(_toolbarX, _toolbarYOfNew)];
            }
        }
        
        //下降
        if( _diffY < 0 ){
            if( self.linkMove ){
                [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew - _tipHeight];
                [self _moveWithView:self.view distance:_tipHeight goBack:YES];
            }else{
                [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew];
            }
            //[self _moveWithView:self.toolbar distance:_tipHeight goBack:NO];
            if( [self.delegate respondsToSelector:@selector(krToolbar:trackChangingSlideDownToPoints:)] ){
                [self.delegate krToolbar:self trackChangingSlideDownToPoints:CGPointMake(_toolbarX, _toolbarYOfNew)];
            }
        }
        
        //不變動
        if( _diffY == 0 ){
            [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew];
            //[self _moveWithView:self.view distance:_tipHeight goBack:YES];
        }
    }else{
        [self _moveToSitesWithView:self.toolbar toX:_toolbarX toY:_toolbarYOfNew];
        if( [self.delegate respondsToSelector:@selector(krToolbar:trackChangingSlideUpToPoints:)] ){
            [self.delegate krToolbar:self trackChangingSlideUpToPoints:CGPointMake(_toolbarX, _toolbarYOfNew)];
        }
    }
    
    
    //覆蓋記錄
    self._lastX = _toolbarX;
    self._lastY = _toolbarYOfNew;
    
    //NSLog(@"_toolbarYOfNew : %f", _toolbarYOfNew);
    //NSLog(@"self.view.frame.size.height : %f", self.view.frame.size.height);
}

-(void)_slideDown{
    CGFloat _x = 0.0f;
    CGFloat _y = [[UIScreen mainScreen] bounds].size.height;
    if( self.toolbar.frame.origin.y < _y ){
        //回復初始
        [self _moveToSitesWithView:self.toolbar toX:_x toY:_y];
        //[self _moveToSitesWithView:self.view toX:0.0 toY:0.0];
        self._lastX = 0.0f;
        self._lastY = 0.0f;
        if( [self.delegate respondsToSelector:@selector(krToolbar:didFinishedAndHideToolbarToPoints:)] ){
            [self.delegate krToolbar:self didFinishedAndHideToolbarToPoints:CGPointMake(_x, _y)];
        }
    }
    self.toolbar.hidden = YES;
}

/*
 * Keyboard 監聽事件專用
 */
//先經由這裡呼叫下一支 Code，Keyboard 的控制會更精確( 否則有時會出現操作失敗的情形 )
-(void)_keyboardWillShowOnDelay:(NSNotification *)notification
{
    [self performSelector:@selector(_keyboardWillShow:) withObject:notification afterDelay:0];
}

//實際 Run 的 Function
-(void)_keyboardWillShow:(NSNotification *)notification{
    UIView *foundKeyboard = nil;
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]){
        if (![[testWindow class] isEqual:[UIWindow class]]){
            keyboardWindow = testWindow;
            break;
        }
    }
    if (!keyboardWindow) return;
    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews])
    {
        //iOS3
        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]){
            foundKeyboard = possibleKeyboard;
            break;
        }else{
            //iOS 4+ sticks the UIKeyboard inside a UIPeripheralHostView.
            if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]){
                for( UIView *_findOutKeyboardView in possibleKeyboard.subviews ){
                    if( [[_findOutKeyboardView description] hasPrefix:@"<UIKeyboard"] ){
                        possibleKeyboard = _findOutKeyboardView;
                    }
                }
            }
            if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]){
                foundKeyboard = possibleKeyboard;
                break;
            }
        }
    }
    
    if (foundKeyboard){
        /*
         * @動態控制 toolbar 的升降
         */
        if( self._slideUpToolbar ){
            [self _slideUpWithFrame:foundKeyboard.frame];
        }else{
            [self _slideDown];
        }
        //NSLog(@"foundKeyboard X / Y : %f / %f", foundKeyboard.frame.origin.x, foundKeyboard.frame.origin.y);
        //NSLog(@"foundKeyboard Width / Height : %f / %f", foundKeyboard.frame.size.width, foundKeyboard.frame.size.height);
    }
}

-(void)_keyboardWillHide:(NSNotification *)notification{
    //self._slideUpToolbar = NO;
    [self _slideDown];
}

-(void)_removeNotification{
    /* 栘除監聽事件 No longer listen for keyboard */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

@end

@implementation KRToolbar

@synthesize delegate;
@synthesize toolbar;
@synthesize view;
@synthesize linkMove;

@synthesize _slideUpToolbar;
@synthesize _lastX, _lastY;
@synthesize _initPoints;

-(id)init{
    self = [super init];
    if( self ){
        [self _initWithVars];
    }
    return self;
}

-(id)initWithToolbar:(UIToolbar *)_aToolbar mappingView:(UIView *)_aView{
    self = [super init];
    if( self ){
        [self _initWithVars];
        [self setToolbar:_aToolbar mappingView:_aView];
    }
    return self;
}

-(void)dealloc{
    [self _removeNotification];
    self.toolbar = nil;;
     //, self.view = nil;
}

#pragma Methods
-(void)setToolbar:(UIToolbar *)_aToolbar mappingView:(UIView *)_aView{
    self.toolbar = _aToolbar;
    self.view    = _aView;
    self._initPoints = self.view.frame.origin;
}

-(void)watchKeyboard{
    self._slideUpToolbar = YES;
    /*
     * 在監聽 UIKeyboardWillShowNotification 事件時，其觸發時機點 :
     *   1). 如果鍵盤變換語系(即注音輸入換成英文或手寫板時)，而該語系的鍵盤呎吋(Frame)又有所改變時，就會觸發這事件。
     *   2). 任何當鍵盤要出現時。
     */
    //監聽 Keyboard 出現事件
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillShowOnDelay:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    //監聽 Keyboard 消失事件
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)leaveKeyboard{
    [self _removeNotification];
    [self hide];
}

-(void)hide{
    self._slideUpToolbar = NO;
    [self.toolbar setHidden:YES];
    [self _slideDown];
}

-(void)show{
    self._slideUpToolbar = YES;
    [self.toolbar setHidden:NO];
    [self _keyboardWillShowOnDelay:nil];
}

@end
