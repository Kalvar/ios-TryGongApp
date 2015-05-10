//
//  KRMixCameraViewController.m
//  V1.4
//
//  Created by Kalvar on 13/5/5.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRMixCameraViewController.h"
#import "VarDefines+HTTP.h"
#import "KRCamera.h"
#import "KRMixTemplateView.h"
#import "KRViewDrags.h"
#import "KRCountDown.h"

#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f)

//圖片縮放的倍數
static CGFloat _kKRMixImageScaleRatio = 3.0f; //2.0f; //4.0 倍太大，會 Memory Crahs

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
    //相容 iOS 6 / 7
    if( _normalImage || _highlightImage )
    {
        for (int i = 0; i < [self.subviews count]; i++)
        {
            UIView* dotView = [self.subviews objectAtIndex:i];
            UIImageView* dot = nil;
            
            for (UIView* subview in dotView.subviews)
            {
                if ([subview isKindOfClass:[UIImageView class]])
                {
                    dot = (UIImageView*)subview;
                    break;
                }
            }
            
            if (dot == nil)
            {
                dot = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, dotView.frame.size.width, dotView.frame.size.height)];
                [dotView addSubview:dot];
            }
            
            if (i == self.currentPage)
            {
                if(_normalImage)
                {
                    dot.image = _normalImage;
                }
            }
            else
            {
                if (_highlightImage)
                {
                    dot.image = _highlightImage;
                }
            }
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
@property (nonatomic, strong) KRViewDrags *_krViewDrags;
@property (nonatomic, strong) NSMutableArray *_templates;
@property (nonatomic, strong) UIImage *_cameraImage;
@property (nonatomic, assign) BOOL _doShareToFacebook;

//@property (nonatomic, strong) KRCountDown *_krCountDown;

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
    //已經沒有 3GS 不支援 @2x Retina 圖片的呎吋了，之後都直接使用 @2x 圖片即可，不用再特地製作 Non-Retina 的圖
    _templates = [[NSMutableArray alloc] initWithObjects:
                  @"ele_fame_1@2x.png",
                  @"ele_fame_2@2x.png",
                  @"ele_fame_3@2x.png",
                  @"ele_fame_4@2x.png",
                  @"ele_fame_5@2x.png",
                  @"ele_fame_blank@2x.png",
                  nil];
    self._cameraImage           = nil;
    self._doShareToFacebook     = NO;
    self.subtitle               = @"核電歸零";
    self.outWordsTextField.text = self.subtitle;
    self.outPhotoImageView.contentMode = UIViewContentModeScaleAspectFit;
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

-(BOOL)_isIos7
{
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f);
}

-(void)_removeCamera
{
    if( self._krCamera.view.superview == self.outCameraView )
    {
        [self._krCamera.view removeFromSuperview];
    }
    [self._krCamera remove];
}

/*
 * @ 2014.02.23 PM 22:50
 *
 * @ 取圖的 Sample Size
 *
 *   //640 x 640
 *   [self _image2xNamed:@"ele_fame_6"];
 *
 *   //1280 x 1280
 *   [self _image2xNamed:@"ele_fame_6@2x.png"];
 *
 *   //1280 x 1280
 *   [self _image2xNamed:@"ele_fame_6@2x"];
 *
 *   //640 x 640
 *   [self _imageNamedNoCache:@"ele_fame_6@2x.png"]; //跟 @"ele_fame_6.png" 相同
 *
 */
//用 imageWithContentsOfFile 取出的圖片都會是小張圖，@2x 的圖片並不會被取出，要使用 imageNamed 方法才會取出 @2x 大圖
-(UIImage *)_imageNamedNoCache:(NSString *)name
{
    //要顯示給 User 看的圖可以用這方法，而要合成上傳的圖則要使用 imageNamed 方法才能取到大張原始圖
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], name]];
}

//取出 @2x 的圖
-(UIImage *)_image2xNamed:(NSString *)_name
{
    return [UIImage imageNamed:_name];
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
 *
 * @ 合成圖片的要訣
 *   - 要結合的 2 張圖片可不限大小進行合成，唯要注意要蓋上來的圖片座標位置得擺對。
 *
 */
-(UIImage *)_mergeBaseImage:(UIImage *)_baseImage
                 underImage:(UIImage *)_underImage
         matchBaseImageSize:(BOOL)_matchBaseImageSize
{
	/*
     * @ 先作一張空白當基底的畫布
     *   - 因為圖片要以 AspectFit 最適呎吋的檥式呈現，故改以呈現的 UIImageView 的呎吋為底圖呎吋，而 _baseImage 是用來直接畫出的原呈現圖片。
     *   - //以 _baseImage 的呎吋為底圖
     *
     * @ 2014.02.23 PM 22:30
     *   - 將 UIScreen mainScreen].scale 改成使用自訂縮放的比例 _kKRMixImageScaleRatio，
     *     以讓合成後的圖片為 960 x 960
     */
    CGFloat _screenScale = _kKRMixImageScaleRatio; //[UIScreen mainScreen].scale;
    CGSize _drawSize     = self.outPhotoImageView.frame.size; //_baseImage.size;
    _drawSize.width     *= _screenScale;
    _drawSize.height    *= _screenScale;
    
    //製作畫布
    UIGraphicsBeginImageContext( _drawSize );
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    //填滿底色 ( 黑色 )
    UIColor *_backgroundColor = [UIColor blackColor];
    CGRect fillRect = CGRectMake(0.0f, 0.0f, _drawSize.width, _drawSize.height);
    CGContextSetFillColorWithColor(currentContext, _backgroundColor.CGColor);
    CGContextFillRect(currentContext, fillRect);
    
    //主要圖片, 並重設要作畫的 X, Y 軸，讓圖片垂直置中畫出
    CGFloat _baseX = ( _drawSize.width - _baseImage.size.width ) / 2;   //0.0f
    CGFloat _baseY = ( _drawSize.height - _baseImage.size.height ) / 2; //0.0f
	[_baseImage drawInRect:CGRectMake(_baseX, _baseY, _baseImage.size.width, _baseImage.size.height)];
    //將蓋上來結合的圖片 ( _unserImage ) 放到跟原基底的圖 ( _baseImage ) 一樣大
    if( _matchBaseImageSize )
    {
        //畫上去的區域一樣從 ( 0, 0 ) 開始畫起
        [_underImage drawInRect:CGRectMake(0.0f, 0.0f, _drawSize.width, _drawSize.height)];
    }
    else
    {
        /*
         * @ _underImage 保持原呎吋
         *   - 如果之後要做「上下撥圖片」的 320 x 160 圖片，就改變這裡要結合的 Y 座標值即可，就能保持要結合的圖片座標位置。
         */
        [_underImage drawInRect:CGRectMake(0.0f, 0.0f, _underImage.size.width, _underImage.size.height)];
    }
    //重繪圖
	UIImage *_mergedImage = UIGraphicsGetImageFromCurrentImageContext();
    //Release
	UIGraphicsEndImageContext();
	return _mergedImage;
}

/*
 * @ 結合圖片，以便於 :
 *   - 1. 準備分享至 Facebook
 *   - 2. 存入相簿
 */
-(void)_mergedImage
{
    //outPhotoImageView 是用來儲存合成圖片的
    self.outPhotoImageView.image = nil;
    NSInteger _index             = [self _calculateCurrentPage];
    KRMixTemplateView *_subview  = (KRMixTemplateView *)[[self.outScrollView subviews] objectAtIndex:_index];
    UIImage *_captureImage       = _subview.displayImage; //[_subview captureImageFromView];
    self.outPhotoImageView.image = [self _mergeBaseImage:self._cameraImage
                                              underImage:_captureImage
                                      matchBaseImageSize:YES];
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
        _krMixTemplateView.imageView.image    = [self _image2xNamed:_templateImageName];
        _krMixTemplateView.titleLabel.text    = self.subtitle;
        /*
         * @ 設計想法 ( 2013.06.01 23:50 )
         *
         *   - V1.0 不加自訂字幕
         *   - V1.2 加自訂字幕
         *
         */
        switch (_index)
        {
            //共幾張圖片型
            case 5:
                _krMixTemplateView.krMixTemplateTitleLabelMode = KRMixTemplateTitleLabelMode10;
                break;
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
    [self _mergedImage];
    [self._krFacebook uploadWithImage:self.outPhotoImageView.image andDescription:self.outWordsTextField.text];
    [self _dismissShareView];
    [self _showAlertWithMessage:@"感謝您參與反核!"];
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
    //先進行等比例縮圖
    float _scaleRatio   = MAX( (_toWidth / _oldWidth), (_toHeight / _oldHeight) ); //MIN
    float _equalWidth   = (int)( _oldWidth * _scaleRatio );
    float _equalHeight  = (int)( _oldHeight * _scaleRatio );
    _image = [self _scaleImage:_image toSize:CGSizeMake(_equalWidth, _equalHeight)];
    switch (_cutMode)
    {
        case KRMixCameraImageCutModesForCenter:
            //中心剪裁
            _x = floor( (_equalWidth -  _toWidth) / 2 );
            _y = floor( (_equalHeight - _toHeight) / 2 );
            break;
        case KRMixCameraImageCutModesForLeftTop:
            //左上開始裁
            _x     = 0.0f;
            _y     = 0.0f;
            break;
        default:
            break;
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

@implementation KRMixCameraViewController (fixResults)

-(void)_showResultImage:(UIImage *)_image withImagePickerController:(UIImagePickerController *)_imagePicker
{
    /*
     * @ 原先認為，是 iPhone 5 就中間裁圖
     *   - 如果是 4 / 4S 就左上角裁圖，這是因為 Device 不同，
     *     那，原始要裁切的圖片呎吋就不同，這會造成 4S 如果也以中心點裁圖時，就會產生錯位的情況。
     *
     * @ 2014.02.23 PM 23:12 修正上述觀念
     *   - 跟 iPhone 5 沒有關係，跟 iOS 6 與 7 之間的差異有關 :
     *     - iOS 6，iPhone 4S 才需要使用「左上角裁圖」的模式, KRMixCameraImageCutModesForLeftTop
     *     - iOS 6，iPhone 5  需要使用「中間點裁圖」的模式, KRMixCameraImageCutModesForCenter
     *     - iOS 7，iPhone 4S 直接使用「中間點裁圖」的模式, KRMixCameraImageCutModesForLeftTop
     *     - iOS 7，iPhone 5  需要使用「左上角裁圖」的模式, KRMixCameraImageCutModesForCenter
     *
     */
    if( [self _isIphone5] )
    {
        KRMixCameraImageCutModes _cutMode = KRMixCameraImageCutModesForLeftTop;
        if( ![self _isIos7] )
        {
            _cutMode = KRMixCameraImageCutModesForCenter;
        }
        self._cameraImage = [self _scaleCutImage:_image
                                         toWidth:320.0f * _kKRMixImageScaleRatio
                                        toHeight:320.0f * _kKRMixImageScaleRatio
                                         cutMode:_cutMode];
    }
    else
    {
        KRMixCameraImageCutModes _cutMode = KRMixCameraImageCutModesForCenter;
        if( ![self _isIos7] )
        {
            _cutMode = KRMixCameraImageCutModesForLeftTop;
        }
        self._cameraImage = [self _scaleCutImage:_image
                                         toWidth:320.0f * _kKRMixImageScaleRatio
                                        toHeight:320.0f * _kKRMixImageScaleRatio
                                         cutMode:_cutMode];
    }
    
    //960 x 960
    //NSLog(@"_cameraImage 1 size : %f, %f", _cameraImage.size.width, _cameraImage.size.height);
    
    //2014.05.02 PM 10:23
    //NSLog(@"here 3 : %@", [NSDate date]);
    //[self._krCountDown stop];
    //[self._krProgress stopFromTranslucentView:self.outCameraView];
    //[self._krProgress stopFromTranslucentViewAndRemoveTipTitle:self.outCameraView];
    
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
@synthesize outWordsTextField;
//
@synthesize _krCamera;
@synthesize _krFacebook;
@synthesize _krProgress;
@synthesize _krViewDrags;
@synthesize _templates;
@synthesize _cameraImage;
@synthesize _doShareToFacebook;
//@synthesize _krCountDown;

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
    //self._krCountDown = [KRCountDown sharedInstance];
    
    [self _initWithVars];
    [self _initializeScrollViewSettings];
    [self _addDefaultTemplates];
    [self _packgeResetPageControl];
    [self _dismissShareView];
    [self _checkLogged];
    [self startCamera];
    _krViewDrags = [[KRViewDrags alloc] initWithView:self.outControlView
                                            dragMode:krViewDragModeFromRightToLeft];
    self._krViewDrags.sideInstance = 161.0f;
    self._krViewDrags.durations    = 0.15f;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self._krViewDrags start];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self._krViewDrags stop];
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
        self._krCamera.autoDismissPresent      = NO; //YES;
        self._krCamera.autoRemoveFromSuperview = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self presentViewController:self._krCamera animated:YES completion:nil];
            [self.outCameraView addSubview:self._krCamera.view];
            //_krCountDown.view = self._krCamera.view;
        });
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
    //在 4S 上拍照會很容易 Memory Crash
    //2014.05.02 PM 10:23
    //[self._krProgress startOnTranslucentView:self.outCameraView tipTitle:@"正在處理照片"];
    //[self._krProgress startOnTranslucentView:self.outCameraView];
    
    //[self._krCountDown start];
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

/*
 * @ 將合成後的圖片存入相簿
 */
-(IBAction)saveInAlbum:(id)sender
{
    [self _mergedImage];
    [_krCamera saveToAlbum:self.outPhotoImageView.image completion:^(NSURL *assetURL, NSError *error)
    {
        [self _showAlertWithMessage:@"已存入相簿"];
        [self _dismissShareView];
    }];
}

#pragma KRCameraDelegate
/*
 * @ 按下取消時
 *   - Pressed cancel button.
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
 *   - Picking original image / video then running here.
 */
-(void)krCameraDidFinishPickingMediaWithInfo:(NSDictionary *)_infos imagePickerController:(UIImagePickerController *)_imagePicker
{
    //[self._krCamera wantToFullScreen];
    //NSLog(@"Picture 4 : %@", [NSDate date]);
    
    //2014.05.02 PM 22:10
    //是相機模式就執行這裡
    if( self._krCamera.sourceMode != KRCameraModesForSelectAlbum )
    {
        [self _showResultImage:[_infos objectForKey:@"UIImagePickerControllerOriginalImage"] withImagePickerController:_imagePicker];
    }
}

/*
 * @ 對象是圖片並包含 EXIF / TIFF 等 MetaData 資訊
 *   - The image includes EXIF / TIFF metadata.
 */
/*
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath metadata:(NSDictionary *)_metadatas imagePickerController:(UIImagePickerController *)_imagePicker
{
    //NSLog(@"meta : %@", _metadatas);
    
}
*/

/*
 * @ 對象是原始圖片
 *   - The target is original image.
 */
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker
{
    //2448 x 3264
    //NSLog(@"_image 1 size : %f, %f", _image.size.width, _image.size.height);
    
    //NSLog(@"Picture 8 : %@", [NSDate date]);
    
    //2014.05.02 PM 22:10
    //是相簿選擇圖片才執行這裡
    //這是因為照相模式要存照片，之後再進到這裡會太久，需要 6 ~ 9 秒，所以就把照相和相簿選圖 2 個功能分開進行
    if( self._krCamera.sourceMode == KRCameraModesForSelectAlbum )
    {
        [self _showResultImage:_image withImagePickerController:_imagePicker];
    }
}

/*
 * @ 對象是修改後的圖片
 *   - The target is edited image.
 */
-(void)krCameraDidFinishEditedImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker
{
    //NSLog(@"Edited Image : %@", _imagePath);
    /*
     * @ 這裡就不需要判斷 Device 而有不同的裁切方式
     *   - 這是因為圖片會先被 User 編輯過的關係，所以中心點裁圖也會剛剛好。
     */
    
    //NSLog(@"_image 2 size : %f, %f", _image.size.width, _image.size.height);
    
    self._cameraImage = [self _scaleCutImage:_image
                                     toWidth:320.0f * _kKRMixImageScaleRatio
                                    toHeight:320.0f * _kKRMixImageScaleRatio
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
    //_image = nil;
}

/*
 * @ 對象是影片
 *   - The target is Video.
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

#pragma UITextFieldDelegate
-(void)_reloadTemplatesWords
{
    for( KRMixTemplateView *_krMixTemplateView in self.outScrollView.subviews )
    {
        if( _krMixTemplateView.krMixTemplateTitleLabelMode != KRMixTemplateTitleLabelModeNothing )
        {
            _krMixTemplateView.titleLabel.text = self.outWordsTextField.text;
            [_krMixTemplateView display];
        }
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.returnKeyType      = UIReturnKeyDone;
    textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.subtitle = textField.text;
    [self _reloadTemplatesWords];
	return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

#pragma UIViewDelegate
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //這樣在平常點擊時，只要 TextField 沒有作用過，就不會重複觸發 resignFirstResponder 的函式，以節省不必要的效能浪費
    if( self.outWordsTextField.resignFirstResponder )
    {
        [self.outWordsTextField resignFirstResponder];
        if( self.outWordsTextField.text && [self.outWordsTextField.text length] > 0 )
        {
            [self _reloadTemplatesWords];
        }
    }
    [super touchesBegan:touches withEvent:event];
}



@end

