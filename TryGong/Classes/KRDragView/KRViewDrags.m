//
//  KRViewDrags.m
//  
//
//  Created by Kalvar on 12/10/2.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "KRViewDrags.h"

@interface KRViewDrags (){
    UIPanGestureRecognizer *_panGestureRecognizer;
    UISwipeGestureRecognizer *_leftGestureRecognizer;
    UISwipeGestureRecognizer *_rightGestureRecognizer;
}

@property (nonatomic, assign) CGPoint _orignalPoints;
@property (nonatomic, assign) CGPoint _matchPoints;
@property (nonatomic, strong) UIPanGestureRecognizer *_panGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *_leftGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *_rightGestureRecognizer;
@property (nonatomic, strong) UIView *_gestureView;
@property (nonatomic, assign) BOOL _isOpening;

@end

@interface KRViewDrags (fixDrages)

-(void)_initWithVars;
-(void)_allocPanGesture;
-(void)_addViewDragGesture;
-(void)_removeViewDrageGesture;
-(void)_moveView:(UIView *)_targetView toX:(CGFloat)_toX toY:(CGFloat)_toY;
-(void)_finalDragging:(CGPoint)_viewCenter;
-(void)_handleDrag:(UIPanGestureRecognizer*)_panGesture;
-(void)_allocSwipeGesture;
-(void)_addViewSwipeGesture;
-(void)_removeViewSwipeGesture;
-(void)_handleSwipe:(UISwipeGestureRecognizer *)_swipeGesture;
-(CGFloat)_statusBarHeight;
-(CGFloat)_caculateDiffViewCenterChanged;

@end

@implementation KRViewDrags (fixDrages)

-(void)_initWithVars
{
    if( self.view )
    {
        self._gestureView   = self.view;
        self._orignalPoints = self._gestureView.center;
        [self _resetMatchPoints];
    }
    self.sideInstance = 40.0f;
    self.durations    = 0.2f;
    self._isOpening   = NO;
}

-(void)_resetMatchPoints{
    /*
     * 因為不允許上下移動，所以 Y 軸幾乎不會動
     * 如果現在的 Y 軸與原始的 Y 軸不相等，代表畫面上的 View 有變動
     */
    //修正誤差
    CGFloat _yOffset = 0.0f;
    if( self._gestureView.center.y != self._orignalPoints.y ){
        _yOffset = self._gestureView.center.y - self._orignalPoints.y;
    }
    self._matchPoints = CGPointMake(self._orignalPoints.x,
                                    ( self._orignalPoints.y + _yOffset ));
    /*
     //因應 StatusBar 的變化所寫的
     self._matchPoints = CGPointMake(self._orignalPoints.x,
                                    ( self._orignalPoints.y - [self _caculateDiffViewCenterChanged] ));
     */
    
}

-(void)_allocPanGesture{
    //只 alloc 一次
    if( _panGestureRecognizer ) return;
    //加入拖拉手勢
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(_handleDrag:)];
}

-(void)_addViewDragGesture{
    [self._gestureView addGestureRecognizer:self._panGestureRecognizer];
}

-(void)_removeViewDrageGesture{
    [self._gestureView removeGestureRecognizer:self._panGestureRecognizer];
}

-(void)_moveView:(UIView *)_targetView
             toX:(CGFloat)_toX
             toY:(CGFloat)_toY
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:self.durations];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationBeginsFromCurrentState:YES];
    _targetView.frame = CGRectMake(_toX,
                                   _toY,
                                   _targetView.frame.size.width,
                                   _targetView.frame.size.height);
    [UIView commitAnimations];
}

-(void)_finalDragging:(CGPoint)_viewCenter
{
    CGFloat _screenWidth  = self._gestureView.frame.size.width;
    CGFloat _moveDistance = 0.0f;
    BOOL _throughCenter    = NO;
    switch (self.dragMode)
    {
        case krViewDragModeFromLeftToRight:
            _moveDistance  = _screenWidth - self.sideInstance;
            //檢查 X 是否已過中線
            _throughCenter = ( _viewCenter.x > _screenWidth / 2 );
            break;
        case krViewDragModeFromRightToLeft:
            _moveDistance  = -(_screenWidth - self.sideInstance);
            _throughCenter = ( _viewCenter.x < -( _screenWidth / 2 ) );
            break;
        case krViewDragModeBoth:
            //... Nothing else ( Waiting for add the codes. )
            //...
            self._isOpening = NO;
            break;
        default:
            break;
    }
    if( _throughCenter )
    {
        //打開
        [self _moveView:self._gestureView toX:_moveDistance toY:0.0f];
        self._isOpening = YES;
    }
    else
    {
        //回到原點
        [self _moveView:self._gestureView toX:0.0f toY:0.0f];
        self._isOpening = NO;
    }
}

/*
 * @Bugs
 *   1). 在快速移動至原點( 0, 0 )時，會出現超出原點範圍的跑版情形。
 */
-(void)_handleDrag:(UIPanGestureRecognizer*)_panGesture
{
    //目前手勢 View 的中心位置
    CGPoint center      = _panGesture.view.center;
    //手勢在目前 View 上的觸碰點
    CGPoint translation = [_panGesture translationInView:_panGesture.view];
    //當前作用 View 的位置
    CGPoint viewCenter  = self._gestureView.frame.origin;
    //判斷是否需重設原比對用的 Y 座標值
    [self _resetMatchPoints];
    
//    NSLog(@"o.x : %f", self._matchPoints.x);
//    NSLog(@"v.x : %f", viewCenter.x);
//    NSLog(@"center.y : %f", center.y);
//    NSLog(@"o.y : %f", self._matchPoints.y);
//    NSLog(@"center.x : %f", center.x);
//    NSLog(@"trans.x : %f\n\n", translation.x);
    
    switch (self.dragMode)
    {
        case krViewDragModeFromLeftToRight:
            /*
             * 只允許往右移動
             */
            if( translation.x < 0 && viewCenter.x <= 0 ) return;
            break;
        case krViewDragModeFromRightToLeft:
            /*
             * 只允許往左移動
             */
            if( translation.x > 0 && viewCenter.x >= 0 ) return;
            /*
             * 不允許上下移動
             */
            //if( translation.y != self._orignalPoints.y ) return;
            break;
        case krViewDragModeBoth:
            //... Nothing else ( Waiting for add the codes. )
            //...
            break;
        default:
            break;
    }
    //拖拉移動
    if (_panGesture.state == UIGestureRecognizerStateChanged)
    {
        if( center.y == self._matchPoints.y )
        {
            //NSLog(@"center.x : %f", center.x);
            //NSLog(@"translation.x : %f\n\n", translation.x);
            center = CGPointMake(center.x + translation.x, self._matchPoints.y);
            _panGesture.view.center = center;
            [_panGesture setTranslation:CGPointZero inView:_panGesture.view];
        }
    }
    //結束觸碰
    if(_panGesture.state == UIGestureRecognizerStateEnded)
    {
        [self _finalDragging:viewCenter];
    }
}

/*
 * @Problem
 *   這裡的 Swipe 手勢會跟 Drag ( Pan ) 的手勢互衝，而無明顯之作用 ( 僅偶有作用 )。
 *   故暫時先不使用。
 */
-(void)_allocSwipeGesture
{
    //只 alloc 一次
    if( !_leftGestureRecognizer ){
        _leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(_handleSwipe:)];
        [_leftGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    }
    if( !_rightGestureRecognizer ){
        _rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(_handleSwipe:)];
        [_rightGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    }
}

-(void)_addViewSwipeGesture
{
    //向左滑
    [self._gestureView addGestureRecognizer:self._leftGestureRecognizer];
    //向右滑
    [self._gestureView addGestureRecognizer:self._rightGestureRecognizer];
}

-(void)_removeViewSwipeGesture{
    [self._gestureView removeGestureRecognizer:self._leftGestureRecognizer];
    [self._gestureView removeGestureRecognizer:self._rightGestureRecognizer];
}

-(void)_handleSwipe:(UISwipeGestureRecognizer *)_swipeGesture{
    //確定是滑動手勢
    if( [_swipeGesture isKindOfClass:[UISwipeGestureRecognizer class]] ){
        //鎖定只允許左右滑動
        UISwipeGestureRecognizerDirection _state = [(UISwipeGestureRecognizer *)_swipeGesture direction];
        switch ( _state ) {
            case UISwipeGestureRecognizerDirectionLeft:
                [self open];
                break;
            case UISwipeGestureRecognizerDirectionRight:
                [self open];
                break;
            default:
                break;
        }
    }
}

-(CGFloat)_statusBarHeight{
    CGSize _size = [UIApplication sharedApplication].statusBarFrame.size;
    //NSLog(@"%f", _size.height);
    return _size.height;
}

-(CGFloat)_caculateDiffViewCenterChanged{
    CGFloat _height     = [self _statusBarHeight];
    CGFloat _baseHeight = 20.0f;
    //代表可能開啟了熱點之類
    if( _height > _baseHeight ){
        return ( _height - _baseHeight );
    }
    //可能是隱藏狀態列
    if( _height <= 0.0f ){
        return _baseHeight;
    }
    return 0.0f;
}

@end


@implementation KRViewDrags

@synthesize _orignalPoints;
@synthesize _matchPoints;
@synthesize _panGestureRecognizer;
@synthesize _leftGestureRecognizer;
@synthesize _rightGestureRecognizer;
@synthesize _gestureView;

@synthesize view;
@synthesize dragMode;
@synthesize sideInstance;
@synthesize durations;

-(id)init{
    self = [super init];
    if( self ){
        self.view = nil;
        [self _initWithVars];
        [self _allocPanGesture];
        //[self _allocSwipeGesture];
    }
    return self;
}

-(id)initWithView:(UIView *)_targetView dragMode:(krViewDragModes)_dragMode{
    self = [super init];
    if( self ){
        self.view     = _targetView;
        self.dragMode = _dragMode;
        [self _initWithVars];
        [self _allocPanGesture];
        //[self _allocSwipeGesture];
    }
    return self;
}


#pragma Methods
-(void)start{
    [self _addViewDragGesture];
    //[self _addViewSwipeGesture];
}

-(void)stop{
    [self _removeViewDrageGesture];
    //[self _removeViewSwipeGesture];
}

-(void)reset{
    [self _removeViewDrageGesture];
    //[self _removeViewSwipeGesture];
    [self _initWithVars];
    [self _allocPanGesture];
    //[self _allocSwipeGesture];
}

-(void)open{
    CGFloat _screenWidth  = self._gestureView.frame.size.width;
    CGFloat _moveDistance = 0.0f;
    switch (self.dragMode) {
        case krViewDragModeFromLeftToRight:
            _moveDistance = _screenWidth - self.sideInstance;
            break;
        case krViewDragModeFromRightToLeft:
            _moveDistance = -(_screenWidth - self.sideInstance);
            break;
        case krViewDragModeBoth:
            //...
            break;
        default:
            break;
    }
    if( self._isOpening ){
        [self _moveView:self._gestureView toX:0.0f toY:0.0f];
    }else{
        [self _moveView:self._gestureView toX:_moveDistance toY:0.0f];
    }
    self._isOpening = !self._isOpening;
}

@end
