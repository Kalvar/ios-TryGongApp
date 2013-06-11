//
//  KRMixCameraViewController.m
//  
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 13/5/5.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "KRMixCameraViewController.h"
#import "VarDefines+HTTP.h"
#import "KRCamera.h"
#import "KRMixTemplateView.h"

//裁圖模式
typedef enum _KRMixCameraImageCutModes
{
    //從中間裁
    KRMixCameraImageCutModesForCenter = 1,
    //左上
	KRMixCameraImageCutModesForLeftTop,
    //左下
    KRMixCameraImageCutModesForLeftBottom,
    //右上
    KRMixCameraImageCutModesForRightTop,
    //右下
    KRMixCameraImageCutModesForRightBottom
} KRMixCameraImageCutModes;

//覆寫 UIPageControl
@interface UIPageControl (fixOverride)

//更新顯示所有的分頁點按鈕 : 傳入正常 / 高亮圖
-(void)updateDotsWithNormalImage:(UIImage *)_normalImage
               andHighlightImage:(UIImage *)_highlightImage;

@end

@implementation UIPageControl (fixOverride)

-(void)updateDotsWithNormalImage:(UIImage *)_normalImage
               andHighlightImage:(UIImage *)_highlightImage
{
    if( _normalImage || _highlightImage ){
        //取得所有分頁點 ImageView
        NSArray *dotSubviews = self.subviews;
        for (NSInteger i = 0; i < [dotSubviews count]; i++)
        {
            //覆寫分頁點樣式圖片
            UIImageView *dot = [dotSubviews objectAtIndex:i];
            //是當前頁面 ? 使用正常圖片 : 使用高亮圖片
            dot.image = self.currentPage == i ? _normalImage : _highlightImage;
        }
    }
    
}

@end

@interface KRMixCameraViewController ()<KRCameraDelegate, KRFacebookDelegate>
{
    NSMutableArray *_templates;
}

@property (nonatomic, strong) KRCamera *_krCamera;
@property (nonatomic, strong) KRFacebook *_krFacebook;
@property (nonatomic, strong) KRProgress *_krProgress;
@property (nonatomic, strong) NSMutableArray *_templates;
@property (nonatomic, strong) UIImage *_cameraImage;
@property (nonatomic, assign) BOOL _doShareToFacebook;

@end

@interface KRMixCameraViewController (fixPrivate)

-(void)_initWithVars;
-(BOOL)_isIphone5;
-(void)_removeCamera;
-(UIImage *)_imageNamedNoCache:(NSString *)name;
//
-(void)_initializeScrollViewSettings;
-(NSInteger)_calculateTotalPages;
-(NSInteger)_calculateCurrentPage;
-(void)_setupPageControl;
-(void)_setupDotsPageControl;
-(void)_packgeResetPageControl;
//
-(UIImage *)_mergeBaseImage:(UIImage *)_baseImage
                 underImage:(UIImage *)_underImage
         matchBaseImageSize:(BOOL)_matchBaseImageSize;
//
-(void)_addDefaultTemplates;
-(void)_turnToShareMode;
-(void)_turnToCameraMode;
-(BOOL)_isCameraMode;
//
-(UIImage *)_scaleImage:(UIImage *)_image toSize:(CGSize)_size;
-(UIImage *)_scaleCutImage:(UIImage *)_image
                   toWidth:(float)_toWidth
                  toHeight:(float)_toHeight
                   cutMode:(KRMixCameraImageCutModes)_cutMode;

@end

@implementation KRMixCameraViewController (fixPrivate)

-(void)_initWithVars
{
    _templates = [[NSMutableArray alloc] initWithObjects:
                  @"ele_fame_1.png",
                  @"ele_fame_2.png",
                  @"ele_fame_3.png",
                  @"ele_fame_4.png",
                  @"ele_fame_5.png",
                  nil];
    self._cameraImage       = nil;
    self._doShareToFacebook = NO;
    //self.subtitle     = @"";
    
}

-(BOOL)_isIphone5
{
    CGRect _screenBounds = [[UIScreen mainScreen] bounds];
    if( _screenBounds.size.width > 480.0f && _screenBounds.size.width <= 568.0f ){
        return YES;
    }
    if( _screenBounds.size.height > 480.0f && _screenBounds.size.width <= 568.0f ){
        return YES;
    }
    return NO;
}

-(void)_removeCamera
{
    if( self._krCamera.view.superview == self.outCameraView )
    {
        [self._krCamera.view removeFromSuperview];
    }
    [self._krCamera remove];
}

-(UIImage *)_imageNamedNoCache:(NSString *)name
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], name]];
}

#pragma UIScrollView

-(void)_initializeScrollViewSettings
{
    self.outScrollView.scrollEnabled                  = YES;
    self.outScrollView.pagingEnabled                  = YES;
    self.outScrollView.showsVerticalScrollIndicator   = NO;
    self.outScrollView.showsHorizontalScrollIndicator = NO;
    self.outScrollView.backgroundColor                = [UIColor clearColor];
    self.outScrollView.delegate                       = self;
}

-(NSInteger)_calculateTotalPages
{
    if( self.outScrollView.contentSize.width == 0.0f )
    {
        return 0;
    }
    CGFloat pageWidth = self.outScrollView.frame.size.width;
    /*
     * @ 公式
     *   - ( ( ScrollView 目前內容的寬度 - (分頁寬度 / 每頁幾張圖) ) / 分頁寬度 ) + 1
     */
    return floor( ( self.outScrollView.contentSize.width - ( pageWidth / 4 ) ) / pageWidth ) + 1;
}

-(NSInteger)_calculateCurrentPage
{
    //取出分頁寬
    CGFloat pageWidth = self.outScrollView.frame.size.width;
    /*
     * @ 公式
     *   - ( ( ScrollView 目前捲動到的 X 座標 - (分頁寬度 / 過半線中間 2 分) ) / 分頁寬度 ) + 1
     */
    return (( self.outScrollView.contentOffset.x - (pageWidth / 2) ) / pageWidth) + 1;
}

-(void)_setupPageControl
{
    //設定相機頁的 PageControl 的分頁數
    self.outPageControl.numberOfPages = [self _calculateTotalPages];
    self.outPageControl.currentPage   = [self _calculateCurrentPage];
    //只有 1 頁也不隱藏 Dots
    self.outPageControl.hidesForSinglePage = NO;
}

-(void)_setupDotsPageControl
{
    //設定點擊分頁點時的分頁點樣式
    [self.outPageControl updateDotsWithNormalImage:[self _imageNamedNoCache:@"ele_pageControlStateHighlighted.png"]
                                 andHighlightImage:[self _imageNamedNoCache:@"ele_pageControlStateNormal.png"]];
}

/*
 * @ 如要要讓「亮點」一直保持自訂格式的話
 *   - 就一定要在 -(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView 裡執行這裡
 */
-(void)_packgeResetPageControl
{
    [self _setupPageControl];
    [self _setupDotsPageControl];
}

#pragma Merge Images
/*
 * @ 結合圖片
 *   - _baseImage          : 要當基底的圖片
 *   - _underImage         : 要蓋上來的圖片
 *   - _matchBaseImageSize : 欲結合的圖片是否要放到跟基底的圖片一樣大
 */
-(UIImage *)_mergeBaseImage:(UIImage *)_baseImage
                 underImage:(UIImage *)_underImage
         matchBaseImageSize:(BOOL)_matchBaseImageSize
{
	/*
     * @ 設定基底的畫布內容
     *   - 以 _baseImage 為底圖
     */
    UIGraphicsBeginImageContext(_baseImage.size);
    //主要圖片
	[_baseImage drawInRect:CGRectMake(0, 0, _baseImage.size.width, _baseImage.size.height)];
    //要結合進來的 _image2 放大到跟 _image1 一樣呎吋
    /*
     * @ 是否要將蓋上來結合的圖片 ( _unserImage ) 放到跟原基底的圖 ( _baseImage ) 一樣大
     */
    if( _matchBaseImageSize )
    {
        [_underImage drawInRect:CGRectMake(0, 0, _baseImage.size.width, _baseImage.size.height)];
    }
    else
    {
        /*
         * @ _underImage 保持原呎吋
         *   - 如果之後要做「上下撥圖片」的 320 x 160 圖片，就改變這裡要結合的 Y 座標值即可，就能保持要結合的圖片座標位置。
         */
        [_underImage drawInRect:CGRectMake(0, 0, _underImage.size.width, _underImage.size.height)];
    }
    //重繪圖
	UIImage *_mergedImage = UIGraphicsGetImageFromCurrentImageContext();
    //Release
	UIGraphicsEndImageContext();
	return _mergedImage;
}

#pragma Templates
/*
 * @ 加入預設的字幕組
 */
-(void)_addDefaultTemplates
{
    CGFloat _x       = 0.0f;
    CGFloat _y       = 0.0f;
    CGFloat _width   = 320.0f;
    CGFloat _height  = 320.0f;
    CGFloat _offsetX = 0.0f;
    NSInteger _index = 0;
    for( NSString *_templateImageName in self._templates )
    {
        KRMixTemplateView *_krMixTemplateView = [[KRMixTemplateView alloc] initWithFrame:CGRectMake(_x, _y, _width, _height)];
        _krMixTemplateView.imageId            = [NSString stringWithFormat:@"%i", _index];
        _krMixTemplateView.imageView.image    = [self _imageNamedNoCache:_templateImageName];
        _krMixTemplateView.titleLabel.text    = self.subtitle;
        /*
         * @ 設計想法 ( 2013.06.01 23:50 )
         *
         *   - V1.0 先不加自訂字幕
         *   - V2.0 再加自訂字幕
         *
         */
        switch (_index)
        {
            //case 0:
                //_krMixTemplateView.krMixTemplateTitleLabelMode = KRMixTemplateTitleLabelMode1;
                //break;
            default:
                _krMixTemplateView.krMixTemplateTitleLabelMode = KRMixTemplateTitleLabelModeNothing;
                break;
        }
        [_krMixTemplateView display];
        [self.outScrollView addSubview:_krMixTemplateView];
        _x += _width + _offsetX;
        ++_index;
    }
    [self.outScrollView setContentSize:CGSizeMake(_x, self.outScrollView.frame.size.height)];
}

-(void)_turnToShareMode
{
    CGRect _screenBounds = [[UIScreen mainScreen] bounds];
    [UIView animateWithDuration:0.3f animations:^{
        CGRect _cameraFrame   = self.outCameraToolView.frame;
        _cameraFrame.origin.y = _screenBounds.size.height;
        [self.outCameraToolView setFrame:_cameraFrame];
    } completion:^(BOOL finished) {
        //[self.outShareToolView setHidden:NO];
        //[self.outCameraToolView setHidden:YES];
        [self.outSwitchCameraButton setHidden:YES];
        [self.outSwitchFlashButton setHidden:YES];
        [self.outCameraView setHidden:YES];
        if( self._cameraImage )
        {
            [self.outPhotoImageView setHidden:NO];
            [self.outPhotoImageView setImage:self._cameraImage];
        }
    }];
}

-(void)_turnToCameraMode
{
    CGRect _screenBounds = [[UIScreen mainScreen] bounds];
    [UIView animateWithDuration:0.3f animations:^{
        CGRect _cameraFrame   = self.outCameraToolView.frame;
        _cameraFrame.origin.y = _screenBounds.size.height - _cameraFrame.size.height;
        [self.outCameraToolView setFrame:_cameraFrame];
    } completion:^(BOOL finished) {
        //[self.outShareToolView setHidden:YES];
        //[self.outCameraToolView setHidden:NO];
        //[self.outPhotoImageView setHidden:YES];
        [self.outSwitchCameraButton setHidden:NO];
        [self.outSwitchFlashButton setHidden:NO];
        [self.outCameraView setHidden:NO];
        self._cameraImage = nil;
        self.outPhotoImageView.image = nil;
    }];
}

-(BOOL)_isCameraMode
{
    //return !( self.outCameraToolView.frame.origin.y <= [[UIScreen mainScreen] bounds].size.height );
    return !self.outCameraView.hidden;
    //return !self.outCameraToolView.hidden;
}

#pragma ShareView + Facebook
-(void)_presentShareView
{
    self.outShareView.hidden = NO;
    [UIView animateWithDuration:0.25f animations:^{
        CGRect _superFrame   = self.view.frame;
        CGRect _shareFrame   = self.outShareView.frame;
        _shareFrame.origin.y = _superFrame.size.height - _shareFrame.size.height;
        [self.outShareView setFrame:_shareFrame];
    }];
}

-(void)_dismissShareView
{
    [UIView animateWithDuration:0.25f animations:^{
        CGRect _shareFrame   = self.outShareView.frame;
        _shareFrame.origin.y = self.view.frame.size.height;
        [self.outShareView setFrame:_shareFrame];
    }];
}

-(void)_doSharePhotoToFacebook
{
    /*
     * @ 這裡要結合圖片後，再分享至 Facebook
     *    - 1. 先取出照相後的照片當 _baseImage
     *    - 2. 再取出當前的字幕圖片 _unserImage
     */
    NSInteger _index             = [self _calculateCurrentPage];
    KRMixTemplateView *_subview  = (KRMixTemplateView *)[[self.outScrollView subviews] objectAtIndex:_index];
    self.outPhotoImageView.image = [self _mergeBaseImage:self._cameraImage
                                              underImage:[_subview captureImageFromView]
                                      matchBaseImageSize:YES];
    [self._krFacebook uploadWithImage:self.outPhotoImageView.image andDescription:@"Please Stop Nuclear."];
    [self _dismissShareView];
    [self _showAlertWithMessage:@"Cool, You Shared!"];
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krMixCameraWantToSharePhoto:)] )
        {
            [self.delegate krMixCameraWantToSharePhoto:self.outPhotoImageView.image];
        }
    }
}

-(void)_showButtonWithFacebookLogin
{
    //[self.outFBLoginButton setImage:[self _imageNamedNoCache:@"btn_fb_login.png"] forState:UIControlStateNormal];
    [self.outFBLoginButton setTitle:@"登入" forState:UIControlStateNormal];
}

-(void)_showButtonWithFacebookLogout
{
    //[self.outFBLoginButton setImage:[self _imageNamedNoCache:@"btn_fb_logout.png"] forState:UIControlStateNormal];
    [self.outFBLoginButton setTitle:@"登出" forState:UIControlStateNormal];
}

-(void)_checkLogged
{
    if( [self._krFacebook alreadyLogged] )
    {
        [self _showButtonWithFacebookLogout];
    }
    else
    {
        [self _showButtonWithFacebookLogin];
    }
}

#pragma --mark Scale Image
/*
 * @ 直接縮放圖片不裁圖
 */
-(UIImage *)_scaleImage:(UIImage *)_image toSize:(CGSize)_size
{
    UIGraphicsBeginImageContext(_size);
    [_image drawInRect:CGRectMake(0, 0, _size.width, _size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(UIImage *)_scaleCutImage:(UIImage *)_image
                   toWidth:(float)_toWidth
                  toHeight:(float)_toHeight
                   cutMode:(KRMixCameraImageCutModes)_cutMode
{
    float _x = 0.0f;
    float _y = 0.0f;
    CGRect _frame    = CGRectMake(_x, _y, _toWidth, _toHeight);
    float _oldWidth  = _image.size.width;
    float _oldHeight = _image.size.height;
    if( !_cutMode )
    {
        _cutMode = KRMixCameraImageCutModesForCenter;
    }
    //先進行等比例縮圖
    float _scaleRatio   = MAX( (_toWidth / _oldWidth), (_toHeight / _oldHeight) );
    float _equalWidth   = (int)( _oldWidth * _scaleRatio );
    float _equalHeight  = (int)( _oldHeight * _scaleRatio );
    _image = [self _scaleImage:_image toSize:CGSizeMake(_equalWidth, _equalHeight)];
    //中心剪裁
    if( _cutMode == KRMixCameraImageCutModesForCenter )
    {
        _x = floor( (_equalWidth -  _toWidth) / 2 );
        _y = floor( (_equalHeight - _toHeight) / 2 );
    }
    else if( _cutMode == KRMixCameraImageCutModesForLeftTop )
    {
        //左上開始裁
        _x     = 0.0f;
        _y     = 0.0f;
    }
    _frame = CGRectMake(_x, _y, _toWidth, _toHeight);
    CGImageRef _smallImage = CGImageCreateWithImageInRect( [_image CGImage], _frame );
    UIImage *_doneImage    = [UIImage imageWithCGImage:_smallImage];
    CGImageRelease(_smallImage);
    return _doneImage;
}

#pragma --mark Others
-(void)_showAlertWithMessage:(NSString *)_message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:_message
                                                       delegate:nil
                                              cancelButtonTitle:@"好"
                                              otherButtonTitles:nil];
    
    [alertView show];
}

@end

@implementation KRMixCameraViewController

@synthesize delegate;
@synthesize subtitle;
@synthesize outCameraView;
@synthesize outControlView;
@synthesize outCameraToolView;
@synthesize outShareToolView;
@synthesize outScrollView;
@synthesize outPageControl;
@synthesize outPhotoImageView;
@synthesize outShareView;
@synthesize outFBLoginButton;
@synthesize outSwitchCameraButton;
@synthesize outSwitchFlashButton;
//
@synthesize _krCamera;
@synthesize _krFacebook;
@synthesize _krProgress;
@synthesize _templates;
@synthesize _cameraImage;
@synthesize _doShareToFacebook;


-(id)init
{
    NSString *_xibName = @"KRMixCameraViewController";
    if( [self _isIphone5] )
    {
        _xibName = @"KRMixCameraViewController_iPhone5";
    }
    self = [super initWithNibName:_xibName bundle:nil];
    if( self )
    {
    
    }
    return self;
}

-(id)initWithDelegate:(id<KRMixCameraDelegate>)_krMixCameraDelegate
{
    self = [self init];
    if( self )
    {
        self.delegate = _krMixCameraDelegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _krFacebook    = [[KRFacebook alloc] initWithDelegate:self];
    _krProgress    = [[KRProgress alloc] init];
    self._krCamera = nil;
    if( !_krCamera )
    {
        _krCamera = [[KRCamera alloc] initWithDelegate:self];
    }
    [self _initWithVars];
    [self _initializeScrollViewSettings];
    [self _addDefaultTemplates];
    [self _packgeResetPageControl];
    [self _dismissShareView];
    [self _checkLogged];
    [self startCamera];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self._krCamera wantToFullScreen];
    //[self startCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma My Methods
/*
 * @ 啟動相機
 */
-(void)startCamera
{
    [self _removeCamera];
    [self _turnToCameraMode];
    [self._krCamera wantToFullScreen];
    /*
     * @ 如果 Device 支援相機
     */
    if( self._krCamera.isSupportCamera )
    {
        self._krCamera.isOpenVideo             = NO;
        self._krCamera.sourceMode              = KRCameraModesForCamera;
        self._krCamera.displaysCameraControls  = NO;
        self._krCamera.isAllowEditing          = NO;
        /*
         * @ 在這裡可自訂義 Camera 的呎吋與出現位置
         */
        if( [self._krCamera isIphone5] )
        {
            [self._krCamera.view setFrame:CGRectMake(0.0f, 0.0f, 320.0f, 320.0f + 96.0f)];
        }
        else
        {
            [self._krCamera.view setFrame:CGRectMake(0.0f, 0.0f, 320.0f, 320.0f)];
        }
        [self._krCamera startCamera];
        self._krCamera.autoDismissPresent      = NO;
        self._krCamera.autoRemoveFromSuperview = NO;
        [self.outCameraView addSubview:self._krCamera.view];
    }
}

-(void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        //[self._krCamera cancelFullScreen];
        [self _removeCamera];
        [self clearMemory];
    }];
}

-(void)clearMemory
{
    self.outPhotoImageView.image = nil;
    self._cameraImage = nil;
}

#pragma IBActions
/*
 * @ 拍張照
 */
-(IBAction)takePicture:(id)sender
{
    [self._krProgress startOnTranslucentView:self.outCameraView tipTitle:@"正在處理照片"];
    [self._krCamera takeOnePicture];
}

/*
 * @ 啟動相簿選照片
 */
-(IBAction)choosePicture:(id)sender
{
    /*
     * @ 要先取消已經啟動過的 Camera
     *   - 否則會 Crash ( Lock On ; 死結 )
     */
    [self _removeCamera];
    //[self._krCamera cancel];
    self._krCamera.isOpenVideo             = NO;
    self._krCamera.sourceMode              = KRCameraModesForSelectAlbum;
    self._krCamera.isAllowEditing          = YES;
    [self._krCamera startChoose];
    self._krCamera.autoDismissPresent      = NO;
    self._krCamera.autoRemoveFromSuperview = NO;
    /*
     * @ 借用 UIView animateWithDuration 的方法
     *   - 來另開一支 Thread 等待之前的 Camera 動畫結束後，
     *     再啟動這裡，就不會出現「Unbalanced calls to begin/end appearance transitions」的問題。
     */
    [UIView animateWithDuration:0.25f animations:^{
        //...
    } completion:^(BOOL finished) {
        [self presentViewController:self._krCamera animated:YES completion:nil];
    }];
}

/*
 * @ 切換鏡頭
 */
-(IBAction)changeCamera:(id)sender
{
    if( self._krCamera.cameraDevice == UIImagePickerControllerCameraDeviceFront )
    {
        self._krCamera.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    else
    {
        self._krCamera.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
}

/*
 * @ 切換閃光
 */
-(IBAction)changeFlash:(id)sender
{
    UIButton *_button = (UIButton *)sender;
    if( self._krCamera.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn )
    {
        self._krCamera.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [_button setImage:[self _imageNamedNoCache:@"btn_flash_off.png"] forState:UIControlStateNormal];
    }
    else
    {
        self._krCamera.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [_button setImage:[self _imageNamedNoCache:@"btn_flash_on.png"] forState:UIControlStateNormal];
    }
}

/*
 * @ 展示背景 Menu
 */
-(IBAction)showMenu:(id)sender
{
    //向左移
    CGFloat _offsetX = -159.0f;
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGRect _frame = self.outControlView.frame;
        if( _frame.origin.x <= _offsetX )
        {
            //代表已經往左移過了，現在要移回來
            _frame.origin.x = 0.0f;
        }
        else
        {
            _frame.origin.x = _offsetX;
        }
        [self.outControlView setFrame:_frame];
    } completion:^(BOOL finished) {
        //...
    }];
}

-(IBAction)dismissCamera:(id)sender
{
    [self dismiss];
}

-(IBAction)changePage:(id)sender
{
    CGRect _frame   = self.outScrollView.frame;
    _frame.origin.x = _frame.size.width * self.outPageControl.currentPage;
    _frame.origin.y = 0.0f;
    [self.outScrollView scrollRectToVisible:_frame animated:YES];
    [self _setupDotsPageControl];
}

/*
 * @ 切換至相機模式
 */
-(IBAction)turnToCameraMode:(id)sender
{
    [self _turnToCameraMode];
    [self startCamera];
}

-(IBAction)sharePhoto:(id)sender
{
    [self _presentShareView];
}

-(IBAction)shareToFacebook:(id)sender
{
    if( [self._krFacebook alreadyLogged] )
    {
        [self _doSharePhotoToFacebook];
    }
    else
    {
        self._doShareToFacebook = YES;
        [self._krFacebook login];
    }
}

-(IBAction)cancelShare:(id)sender
{
    [self _dismissShareView];
}

-(IBAction)loginFacebook:(id)sender
{
    self._doShareToFacebook = NO;
    if( [self._krFacebook alreadyLogged] )
    {
        [self._krFacebook logout];
    }
    else
    {
        [self._krFacebook login];
    }
}

#pragma KRCameraDelegate
/*
 * @ 按下取消時
 */
-(void)krCameraDidCancel:(UIImagePickerController *)_imagePicker
{
    //NSLog(@"cancel");
    /*
     * @ 這裡的設計是給「相簿選擇」用的。
     *   - 使用相機照相，在這裡的設計是要用 removeFromSuperView
     */
    [_imagePicker dismissViewControllerAnimated:YES completion:^{
        if( [self _isCameraMode] )
        {
            [self startCamera];
        }
    }];
    //[_imagePicker.view removeFromSuperview];
}

/*
 * @ 原始選取圖片、影片完成時，或拍完照、錄完影後
 *   - 要在這裡進行檔案的轉換、處理與儲存
 */
-(void)krCameraDidFinishPickingMediaWithInfo:(NSDictionary *)_infos imagePickerController:(UIImagePickerController *)_imagePicker
{
    //[self._krCamera wantToFullScreen];
}

/*
 * @ 對象是圖片並包含 EXIF / TIFF 等 MetaData 資訊
 */
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath metadata:(NSDictionary *)_metadatas imagePickerController:(UIImagePickerController *)_imagePicker
{
    
    //NSLog(@"meta : %@", _metadatas);
    
}

/*
 * @ 對象是圖片
 */
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker
{
    /*
     * @ 在這裡上傳與分享剪裁選擇好的圖片
     */
    /*
     * @ 是 iPhone 5 就中間裁圖
     *   - 如果是 4 / 4S 就左上角裁圖，這是因為 Device 不同，
     *     那，原始要裁切的圖片呎吋就不同，這會造成 4S 如果也以中心點裁圖時，就會產生錯位的情況。
     */
    if( [self _isIphone5] )
    {
        self._cameraImage = [self _scaleCutImage:_image
                                         toWidth:320.0f * 2
                                        toHeight:320.0f * 2
                                         cutMode:KRMixCameraImageCutModesForCenter];
    }
    else
    {
        self._cameraImage = [self _scaleCutImage:_image
                                         toWidth:320.0f * 2
                                        toHeight:320.0f * 2
                                         cutMode:KRMixCameraImageCutModesForLeftTop];
    }
    [self._krProgress stopFromTranslucentViewAndRemoveTipTitle:self.outCameraView];
    if( self._krCamera.sourceMode == KRCameraModesForSelectAlbum )
    {
        [_imagePicker dismissViewControllerAnimated:YES completion:^{
            //切換至分享模式
            if( [self _isCameraMode] )
            {
                [self _turnToShareMode];
            }
        }];
    }
    else
    {
        [self _turnToShareMode];
    }
}

/*
 * @ 對象是修改後的圖片
 */
-(void)krCameraDidFinishEditedImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker
{
    //NSLog(@"Edited Image : %@", _imagePath);
    /*
     * @ 這裡就不需要判斷 Device 而有不同的裁切方式
     *   - 這是因為圖片會先被 User 編輯過的關係，所以中心點裁圖也會剛剛好。
     */
    self._cameraImage = [self _scaleCutImage:_image
                                     toWidth:320.0f * 2
                                    toHeight:320.0f * 2
                                     cutMode:KRMixCameraImageCutModesForCenter];
    if( self._krCamera.sourceMode == KRCameraModesForSelectAlbum )
    {
        [_imagePicker dismissViewControllerAnimated:YES completion:^{
            //切換至分享模式
            [self _turnToShareMode];
        }];
    }
    else
    {
        [self _turnToShareMode];
        //[self _removeCamera];
        //[self sharePhoto:nil];
    }
}

/*
 * @ 對象是影片
 */
-(void)krCameraDidFinishPickingVideoPath:(NSString *)_videoPath imagePickerController:(UIImagePickerController *)_imagePicker
{
    
}

#pragma UIScrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _packgeResetPageControl];
}

#pragma KRFacebook Delegate
-(void)krFacebookDidLogin
{
    [self _showButtonWithFacebookLogout];
    if( self._doShareToFacebook )
    {
        [self _doSharePhotoToFacebook];
    }
}

-(void)krFacebookDidLogout
{
    [self _showButtonWithFacebookLogin];
}

-(void)krFacebookDidFailedLogin
{
    [self _showButtonWithFacebookLogin];
}

-(void)krFacebookDidCancel
{
    [self _showButtonWithFacebookLogin];
}

-(void)krFacebook:(KRFacebook *)_krFacebook didSavedUserPrivations:(NSDictionary *)_savedDatas
{
    
}

-(void)krFacebookDidFinishAllRequests
{
    
}

@end

