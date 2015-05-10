//
//  KRCamera.m
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 2012/08/01.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRCamera.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "AssetsLibrary/AssetsLibrary.h"
#import "ImageIO/CGImageProperties.h"
#import <CoreLocation/CoreLocation.h>

static NSInteger _krCameraCancelButtonTag = 2099;

@interface KRCamera ()<UIPopoverControllerDelegate>

@property (nonatomic, assign) BOOL _hideStatusBar;

@end

@interface KRCamera (saveToAlbum)

-(void)saveImageAndAddMetadata:(UIImage *)image;
-(NSDictionary *)getGPSDictionaryForLocation;
-(void)_writeToAlbum:(NSDictionary *)info imagePicker:(UIImagePickerController *)picker;

@end

@implementation KRCamera (saveToAlbum)

//儲存帶有 EXIF, TIFF 等資訊的圖片至相簿
-(void)saveImageAndAddMetadata:(UIImage *)image
{
    // Format the current date and time
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    NSString *now = [formatter stringFromDate:[NSDate date]];
    
    // Exif metadata dictionary
    // Includes date and time as well as image dimensions
    NSMutableDictionary *exifDictionary = [NSMutableDictionary dictionary];
    [exifDictionary setValue:now forKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
    [exifDictionary setValue:now forKey:(NSString *)kCGImagePropertyExifDateTimeDigitized];
    [exifDictionary setValue:[NSNumber numberWithFloat:image.size.width] forKey:(NSString *)kCGImagePropertyExifPixelXDimension];
    [exifDictionary setValue:[NSNumber numberWithFloat:image.size.height] forKey:(NSString *)kCGImagePropertyExifPixelYDimension];
    
    // Tiff metadata dictionary
    // Includes information about the application used to create the image
    // "Make" is the name of the app, "Model" is the version of the app
    NSMutableDictionary *tiffDictionary = [NSMutableDictionary dictionary];
    [tiffDictionary setValue:now forKey:(NSString *)kCGImagePropertyTIFFDateTime];
    [tiffDictionary setValue:@"Interlacer" forKey:(NSString *)kCGImagePropertyTIFFMake];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [tiffDictionary setValue:[NSString stringWithFormat:@"%@ (%@)", version, build] forKey:(NSString *)kCGImagePropertyTIFFModel];
    
    // Image metadata dictionary
    // Includes image dimensions, as well as the EXIF and TIFF metadata
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[NSNumber numberWithFloat:image.size.width] forKey:(NSString *)kCGImagePropertyPixelWidth];
    [dict setValue:[NSNumber numberWithFloat:image.size.height] forKey:(NSString *)kCGImagePropertyPixelHeight];
    [dict setValue:exifDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
    [dict setValue:tiffDictionary forKey:(NSString *)kCGImagePropertyTIFFDictionary];
    ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
    
    [al writeImageToSavedPhotosAlbum:[image CGImage]
                            metadata:dict
                     completionBlock:^(NSURL *assetURL, NSError *error) {
                         if (error == nil) {
                             if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:imagePickerController:)] ){
                                 [self.KRCameraDelegate krCameraDidFinishPickingImage:image
                                                                              imagePath:[NSString stringWithFormat:@"%@", assetURL]
                                                                  imagePickerController:self];
                             }
                         } else {
                             // handle error
                         }
                     }];
    
}

//取得 GPS 定位資訊
-(NSDictionary *)getGPSDictionaryForLocation
{
    //Use LocationManager to Catch the GPS locations.
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager startUpdatingLocation];
    CLLocation *location = locationManager.location;
    [locationManager stopUpdatingLocation];
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    
    // Latitude
    CGFloat latitude = location.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = location.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (location.speed >= 0){
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (location.course >= 0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}

//寫入相簿裡
-(void)_writeToAlbum:(NSDictionary *)info imagePicker:(UIImagePickerController *)picker
{
    UIImage *savedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    //儲存圖片(這樣存才能取得圖片 Path)
    [self saveToAlbum:savedImage completion:^(NSURL *assetURL, NSError *error)
    {
        if( !error )
        {
            //一般原始圖
            if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:imagePickerController:)] )
            {
                [self.KRCameraDelegate krCameraDidFinishPickingImage:savedImage
                                                           imagePath:[NSString stringWithFormat:@"%@", assetURL]
                                               imagePickerController:picker];
            }
            
            //含有完整 EXIF 等 METADATA 資訊的圖片
            if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:metadata:imagePickerController:)] )
            {
                [self.KRCameraDelegate krCameraDidFinishPickingImage:savedImage
                                                           imagePath:[NSString stringWithFormat:@"%@", assetURL]
                                                            metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                               imagePickerController:picker];
            }
        }
    }];
    
    /*
    // Get the image metadata (EXIF & TIFF)
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSMutableDictionary *_metadata = [[info objectForKey:UIImagePickerControllerMediaMetadata] mutableCopy];
    // add GPS data
    [_metadata setObject:[self getGPSDictionaryForLocation] forKey:(NSString*)kCGImagePropertyGPSDictionary];
    [library writeImageToSavedPhotosAlbum:[savedImage CGImage] metadata:_metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            //NSLog(@"error");
        }else{
            if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:imagePickerController:)] ){
                [self.KRCameraDelegate krCameraDidFinishPickingImage:savedImage
                                                             imagePath:[NSString stringWithFormat:@"%@", assetURL]
                                                 imagePickerController:picker];
            }
            if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:metadata:imagePickerController:)] ){
                [self.KRCameraDelegate krCameraDidFinishPickingImage:savedImage
                                                             imagePath:[NSString stringWithFormat:@"%@", assetURL]
                 
                                                              metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                                 imagePickerController:picker];
            }
        }
    }];
    */
}

@end

@interface KRCamera (fixPrivate)

-(void)_initWithVars;
-(void)_makeiPadCancelButtonOnPopCameraView;
-(UIImage *)_imageNameNoCache:(NSString *)_imageName;
-(BOOL)_isIphone5;
-(BOOL)_isIpadDevice;
-(BOOL)_isDeviceSupportsCamera;
-(void)_appearStatusBar:(BOOL)_isAppear;
-(NSString *)_resetVideoPath:(NSString *)_videoPath;
-(void)_setupConfigs;
//-(void)_resetTempMemories;

@end

@implementation KRCamera (fixPrivate)

-(void)_initWithVars
{
    self.parentTarget       = nil;
    self.sourceMode         = KRCameraModesForCamera;
    self.isOpenVideo        = YES;
    self.allowsSaveFile     = YES;
    self.isAllowEditing     = NO;
    self.videoQuality       = UIImagePickerControllerQualityTypeHigh;
    self.videoMaxSeconeds   = 15;
    self.videoMaxDuration   = -1;
    self.isOnlyVideo        = NO;
    self.displaysCameraControls = YES;
    autoDismissPresent      = NO;
    autoRemoveFromSuperview = NO;
    //只有 iPad 支援宣告 Popover
    if( [self _isIpadDevice] )
    {
        if( !cameraPopoverController )
        {
            cameraPopoverController = [[UIPopoverController alloc] initWithContentViewController:self];
        }
        self.cameraPopoverController.delegate = self;
    }
    else
    {
        self.cameraPopoverController = nil;
    }
    self.supportCamera    = [self _isDeviceSupportsCamera];
    self.keepFullScreen   = NO;
    self.sizeToFitIphone5 = NO;
    self._hideStatusBar   = NO;
}

-(void)_makeiPadCancelButtonOnPopCameraView
{
    if( [self.view viewWithTag:_krCameraCancelButtonTag] )
    {
        [[self.view viewWithTag:_krCameraCancelButtonTag] removeFromSuperview];
    }
    /*
     * @ 寫一個取消的按鈕在這裡
     */
    UIButton *_button = [UIButton buttonWithType:UIButtonTypeCustom];
    [_button setFrame:CGRectMake(20.0f, 20.0f, 60.0f, 28.0f)];
    [_button setTag:_krCameraCancelButtonTag];
    [_button setBackgroundColor:[UIColor clearColor]];
    [_button setBackgroundImage:[self _imageNameNoCache:@"btn_camera_done.png"] forState:UIControlStateNormal];
    [_button setTitle:@"完成" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_button.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [_button addTarget:self action:@selector(_removePopView:) forControlEvents:UIControlEventTouchUpInside];
    //
    [self.view addSubview:_button];
}

-(UIImage *)_imageNameNoCache:(NSString *)_imageName
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _imageName]];
}

-(void)_removePopView:(id)sender
{
    [self dismissPopover];
}

-(BOOL)_isIphone5
{
    CGRect _screenBounds = [[UIScreen mainScreen] bounds];
    //橫向
    if( _screenBounds.size.width > 480.0f && _screenBounds.size.width <= 568.0f )
    {
        return YES;
    }
    //直向
    if( _screenBounds.size.height > 480.0f && _screenBounds.size.width <= 568.0f )
    {
        return YES;
    }
    return NO;
}

-(BOOL)_isIpadDevice
{
    return ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) ? YES : NO;
}

-(void)_appearStatusBar:(BOOL)_isAppear
{
    /*
     * @ 2014.05.09 PM 12:20
     *   - 因應在 iOS 7.1 以上會有 StatusBar 無法恢復顯示的情況發生，
     *     就必須改變這裡的流程為先執行 setStatusBarHidden 方法，
     *     之後再呼叫 setNeedsStatusBarAppearanceUpdate 方法更新 StatusBar 即可。
     */
    [[UIApplication sharedApplication] setStatusBarHidden:!_isAppear];
    if( [self isIOS7] )
    {
        //Only supports iOS7
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        {
            //Have to use this update the status bar
            self._hideStatusBar = !_isAppear;
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        }
    }
}

-(BOOL)_isDeviceSupportsCamera
{
    //檢查是否有相機功能
    //return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

-(NSString *)_resetVideoPath:(NSString *)_videoPath
{
    //Temperatue Path of Recorded Video 
    ///private/var/mobile/Applications/F5D3F6CE-DD41-4FF1-94A4-9C0EBAC70AA3/tmp/capture-T0x232520.tmp.GL1Fg5/capturedvideo.MOV
    NSString *_rePath = @"";
    if( [_videoPath length] > 0 )
    {
        NSMutableArray *explodes = [NSMutableArray arrayWithArray:[_videoPath componentsSeparatedByString:@"/"]];
        [explodes removeObjectAtIndex:0];
        [explodes removeObjectAtIndex:[explodes count] - 2];
        for( NSString *_path in explodes )
        {
            _rePath = [_rePath stringByAppendingFormat:@"/%@", _path];
        }
    }
    return _rePath;
}

-(void)_setupConfigs
{
    //[self _resetTempMemories];
    //[self _appearStatusBar:NO];
    self.delegate      = self;
    self.allowsEditing = self.isAllowEditing;
    switch ( self.sourceMode ) {
        case KRCameraModesForCamera:
            //拍照或錄影
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                self.sourceType = UIImagePickerControllerSourceTypeCamera;
                //self.showsCameraControls = self.showCameraControls;
                //有錄影功能
                if ( self.isOpenVideo )
                {
                    //只拍影片
                    if( self.isOnlyVideo )
                    {
                        //限定相簿只能顯示影片檔
                        self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
                    }
                    else
                    {
                        //NSArray *mediaTypes    = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
                        self.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
                    }
                    //設定影片品質
                    [self setVideoQuality:self.videoQuality];
                    //設定最大錄影時間(秒)
                    [self setVideoMaximumDuration:self.videoMaxSeconeds];
                }
                else
                {
                    self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
                }
            }
            self.allowsSaveFile = YES;
            break;
        case KRCameraModesForSelectAlbum:
            //從相簿選取
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                if ( self.isOpenVideo )
                {
                    if( self.isOnlyVideo )
                    {
                        //限定相簿只能顯示影片檔
                        self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
                    }
                    else
                    {
                        //NSArray *mediaTypes    = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
                        self.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
                    }
                    //有指定取出的影片長度
                    if( self.videoMaxDuration > 0 )
                    {
                        //一定要允許編輯
                        self.allowsEditing = YES;
                        self.videoMaximumDuration = self.videoMaxDuration;
                    }
                }
                else
                {
                    self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
                }
            }
            //從本機選取就不用再重複儲存檔案
            self.allowsSaveFile = NO;
            break;
        case KRCameraModesForAllPhotos:
            //直接呈現全部的照片
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
            {
                self.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                if ( self.isOpenVideo )
                {
                    if( self.isOnlyVideo )
                    {
                        //限定相簿只能顯示影片檔
                        self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
                    }
                    else
                    {
                        //NSArray *mediaTypes    = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
                        self.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
                    }
                    if( self.videoMaxDuration > 0 )
                    {
                        self.allowsEditing = YES;
                        self.videoMaximumDuration = self.videoMaxDuration;
                    }
                }
                else
                {
                    self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
                }
            }
            self.allowsSaveFile = NO;
            break;
    }
}

@end

@implementation KRCamera

@synthesize parentTarget;
@synthesize KRCameraDelegate;
@synthesize sourceMode;
@synthesize isOpenVideo;
@synthesize allowsSaveFile;
@synthesize videoQuality,
            videoMaxSeconeds,
            videoMaxDuration;
@synthesize isAllowEditing;
@synthesize isOnlyVideo;
@synthesize autoDismissPresent      = _autoDismissPresent;
@synthesize autoRemoveFromSuperview = _autoRemoveFromSuperview;
@synthesize displaysCameraControls;
@synthesize cameraPopoverController;
@synthesize supportCamera;
@synthesize keepFullScreen;
@synthesize sizeToFitIphone5;

@synthesize _hideStatusBar;

-(id)initWithDelete:(id<KRCameraDelegate>)_krCameraDelegate pickerMode:(KRCameraModes)_pickerMode
{
    self = [super init];
    if( self ){
        [self _initWithVars];
        self.KRCameraDelegate = _krCameraDelegate;
        self.sourceMode       = _pickerMode;
    }
    return self;
}

-(id)initWithDelegate:(id<KRCameraDelegate>)_krCameraDelegate
{
    self = [super init];
    if( self ){
        [self _initWithVars];
        self.KRCameraDelegate = _krCameraDelegate;
    }
    return self;
}

-(id)init
{
    self = [super init];
    if( self ){
        [self _initWithVars];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _initWithVars];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
#pragma --mark iOS 7
//Hide / Show StatusBar
-(BOOL)prefersStatusBarHidden
{
    return self._hideStatusBar;
}

#pragma MyMethods
/*
 * @ 執行相簿選擇
 */
-(void)startChoose
{
    [self _setupConfigs];
}

/*
 * @ 執行相機
 *   - 在拍照時就會 Received memory warning. 似乎是陳年的老 Bugs 真怪了 = =
 */
-(void)startCamera
{
    [self _setupConfigs];
    //[self _appearStatusBar:!self.keepFullScreen];
    self.showsCameraControls = self.displaysCameraControls;
    CGRect _frame = self.view.frame;
    if( _frame.origin.y > 0.0f || _frame.origin.y < 0.0f )
    {
        _frame.origin.y = 0.0f;
    }
    //如果不要 Controls Bar
    if( !self.showsCameraControls )
    {
        if( self.sizeToFitIphone5 )
        {
            //又是 iPhone 5
            if( [self isIphone5] )
            {
                //且是客製化呎吋
                CGFloat _screenWidth   = 320.0f;
                CGFloat _iphone5Height = 568.0f;
                CGFloat _cameraWidth   = _frame.size.width;
                CGFloat _cameraHeight  = _frame.size.height;
                CGRect _screenBounds   = [[UIScreen mainScreen] bounds];
                //橫向
                if( _screenBounds.size.width > 480.0f && _screenBounds.size.width <= 568.0f )
                {
                    if( _cameraWidth < _iphone5Height && _cameraHeight < _screenWidth )
                    {
                        if( _cameraHeight + 96.0f <= _screenWidth )
                        {
                            _frame.size.height = _cameraHeight + 96.0f;
                        }
                    }
                    
                }
                
                //直向
                if( _screenBounds.size.height > 480.0f && _screenBounds.size.width <= 568.0f )
                {
                    if( _cameraHeight < _iphone5Height && _cameraWidth <= _screenWidth )
                    {
                        //iPhone 5 須多加 96 px 的 cameraControls Bar 的高度
                        if( _cameraHeight + 96.0f <= _iphone5Height )
                        {
                            _frame.size.height = _cameraHeight + 96.0f;
                        }
                    }
                }
            }
        }
    }
    [self.view setFrame:_frame];
    //[self.view setFrame:CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f)];
    //NSLog(@"self.view : %f, %f", self.view.frame.size.width, self.view.frame.size.height);
}

-(void)wantToFullScreen
{
    self.keepFullScreen = YES;
    [self hideStatusBar];
}

-(void)cancelFullScreen
{
    self.keepFullScreen = NO;
    [self showStatusBar];
}

/*
 * @ 移除
 */
-(void)remove
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if( self.view.superview )
        {
            [self.view removeFromSuperview];
        }
        if( self.parentTarget )
        {
            self.parentTarget = nil;
        }
    });
}

/*
 * @ 移除並狀參數恢復初始狀態
 */
-(void)removeAndInitializeAllSettings
{
    [self remove];
    [self _initWithVars];
}

/*
 * @ 向下縮
 */
-(void)cancel
{
    //如使用睡眠後，才 dissmissView 的話，會產生 10004003 的 warning.
    //[NSThread sleepForTimeInterval:0.5];
    if( self.autoRemoveFromSuperview )
    {
        [self remove];
    }
    if( self.autoDismissPresent )
    {
        [self dismissViewControllerAnimated:YES completion:^{
            if( !self.keepFullScreen )
            {
                [self showStatusBar];
            }
        }];
    }
}

/*
 * @ 拍照
 */
-(void)takeOnePicture
{
   [super takePicture];
    //NSLog(@"Picture 1 : %@", [NSDate date]);
    /*
    //@用這裡超單純的呼叫相機，拍照也還是會出現 Memory Warning XD
    //建立選取器
    imagePicker = [[UIImagePickerController alloc] init];
    //選取器的委派
    imagePicker.delegate = self;
    //選取器要進行動作的對象來源 : 手機相簿(PhotoLibrary) :: 共有 PhotoLibrary, Camera, SavedAlbum
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //選取器要進行動作的限定媒體檔類型
    //只能顯示圖片檔
    imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.image"];
    //是否允許修改操作 ? NO : 點圖就完成選取 :: YES : 點圖還會進到修改畫面
    imagePicker.allowsEditing = NO;
    //顯示選取器
    [self presentModalViewController:imagePicker animated:YES];
    return;
    */
}

/*
 * @ 隱藏狀態列
 */
-(void)hideStatusBar
{
    [self _appearStatusBar:NO];
}

/*
 * @ 顯示狀態列
 */
-(void)showStatusBar
{
    [self _appearStatusBar:YES];
}

/*
 * @ 使用 UIPopoverController ( 彈出提示窗 ) 才能在 iPad 上跑 UIImagePickerController
 */
-(void)displayPopoverFromView:(UIView *)_fromTargetView inView:(UIView *)_showInView
{
    self.cameraPopoverController.delegate = nil;
    self.cameraPopoverController          = nil;
    cameraPopoverController               = [[UIPopoverController alloc] initWithContentViewController:self];
    self.cameraPopoverController.delegate = self;
    CGRect popoverRect = [_showInView convertRect:[_fromTargetView frame]
                                         fromView:[_fromTargetView superview]];
    //NSLog(@"popoverRect %f, %f, %f, %f", popoverRect.origin.x, popoverRect.origin.y, popoverRect.size.width, popoverRect.size.height);
    CGSize _inViewSize = _showInView.frame.size;
    //popoverRect.size.height = self.view.frame.size.height;
    popoverRect.origin.y    = _inViewSize.height; //popoverRect.size.height;
    //popoverRect.size = CGSizeMake(768.0f, 800.0f);
    //popoverRect.origin = CGPointMake(0.0f, 0.0f);
    //NSLog(@"_inViewSize %f, %f\n\n", _inViewSize.width, _inViewSize.height);
    //CGRectMake(0, 0, 300, 300)
    [self.cameraPopoverController presentPopoverFromRect:popoverRect
                                                  inView:_showInView
                                permittedArrowDirections:UIPopoverArrowDirectionDown
                                                animated:YES];
    
    //設定 Pop 裡的 SubView Size.
    //[self.cameraPopoverController.contentViewController setContentSizeForViewInPopover:_inViewSize];
    [self.cameraPopoverController setPopoverContentSize:_inViewSize animated:YES];
    
    /*
     * @ 是相機就寫入「完成」按鈕
     */
    if( self.sourceMode == KRCameraModesForCamera )
    {
        [self _makeiPadCancelButtonOnPopCameraView];
    }
    else
    {
        if( [self.view viewWithTag:_krCameraCancelButtonTag] )
        {
            [[self.view viewWithTag:_krCameraCancelButtonTag] removeFromSuperview];
        }
    }
    
}

/*
 * @ 如果是使用上面的 UIPopoverController 在顯示 Picker 的，那就要用這裡的函式去 Dismiss 它。
 */
-(void)dismissPopover
{
    if( self.cameraPopoverController.isPopoverVisible )
    {
        [self.cameraPopoverController dismissPopoverAnimated:YES];
    }
}

-(BOOL)isIpadDevice
{
    return ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad );
}

-(BOOL)isIphone5
{
    return [self _isIphone5];
}

-(BOOL)isIOS7
{
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f);
}

-(BOOL)isDeviceSupportsCamera
{
    self.supportCamera = [self _isDeviceSupportsCamera];
    return self.supportCamera;
}

-(void)saveToAlbum:(UIImage *)_image completion:(void (^)(NSURL *, NSError *))_completion
{
    //儲存圖片(這樣存才能取得圖片 Path)
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:[_image CGImage]
                              orientation:(ALAssetOrientation)[_image imageOrientation]
                          completionBlock:^(NSURL *assetURL, NSError *error){
                              if( _completion )
                              {
                                  _completion(assetURL, error);
                              }
                          }];
}

#pragma Setters
-(void)setAutoDismissPresent:(BOOL)_theAutoDismissPresent
{
    _autoDismissPresent = _theAutoDismissPresent;
    //_autoRemoveFromSuperview = !_autoDismissPresent;
}

-(void)setAutoRemoveFromSuperview:(BOOL)_theAutoRemoveFromSuperview
{
    _autoRemoveFromSuperview = _theAutoRemoveFromSuperview;
    //_autoDismissPresent = !_autoRemoveFromSuperview;
}

#pragma UIImagePickerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //NSLog(@"Picture 2 : %@", [NSDate date]);
    if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingMediaWithInfo:imagePickerController:)] )
    {
        [self.KRCameraDelegate krCameraDidFinishPickingMediaWithInfo:info imagePickerController:picker];
    }
    /*
     * @ self.isOpenVideo 使用時機
     *
     *   - 1. 當需要照相時
     *   - 2. 當需要錄影時
     *   - 3. 當需要從相簿選擇影片時
     */
    if ( self.isOpenVideo )
    {
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        /*
         * @ 如果是錄影
         */
        if ([mediaType isEqualToString:@"public.movie"])
        {
            //來源為影片
            NSURL *videoUrl     = [info objectForKey:UIImagePickerControllerMediaURL];
            NSString *videoPath = videoUrl.path;
            ///*
            if (self.allowsSaveFile)
            {
                //直接存至相簿
                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, nil, nil);
            }
            //即使是儲存影片後的暫存影片路徑，iPhone 都能夠找到並對應儲存前後的實體位置 (放心的使用這方式取得路徑，但需注意下次再進入 App 時，這暫存路徑會消失)。
            if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingVideoPath:imagePickerController:)] ){
                [self.KRCameraDelegate krCameraDidFinishPickingVideoPath:videoPath
                                                     imagePickerController:picker];
            }
             //*/
            /*
            if (self.allowsSaveFile) {
                //這樣才能取到正確儲存後的 Video Path ( 但取到的 Path 必須用 Asset 解析 ...  )
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeVideoAtPathToSavedPhotosAlbum:videoUrl
                                            completionBlock:^(NSURL *assetURL, NSError *error) {
                                                if(error) {
                                                    //NSLog(@"error");
                                                }else{
                                                    if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingVideoPath:imagePickerController:)] ){
                                                        [self.KRCameraDelegate krCameraDidFinishPickingVideoPath:[NSString stringWithFormat:@"%@", assetURL]
                                                                                             imagePickerController:picker];
                                                    }
                                                }
                                            }];
                [library release];
                //儲存影片檔
                //UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.path, self, nil, nil);
            }else{
                if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingVideoPath:imagePickerController:)] ){
                    [self.KRCameraDelegate krCameraDidFinishPickingVideoPath:videoUrl.path
                                                         imagePickerController:picker];
                }
            }
             */
        }
        else if ([mediaType isEqualToString:@"public.image"])
        {
            /*
             * @ 如果來源是圖片
             */
            if (self.allowsSaveFile)
            {
                [self _writeToAlbum:info imagePicker:picker];
                //UIImageWriteToSavedPhotosAlbum(savedImage, self, nil, nil);
            }else{
                /*
                 * @ 允許修改就顯示修改圖
                 */
                if( self.allowsEditing || self.isAllowEditing )
                {
                    if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishEditedImage:imagePath:imagePickerController:)] ){
                        [self.KRCameraDelegate krCameraDidFinishEditedImage:[info objectForKey:@"UIImagePickerControllerEditedImage"]
                                                                  imagePath:[NSString stringWithFormat:@"%@", [info objectForKey:UIImagePickerControllerReferenceURL]]
                                                      imagePickerController:picker];
                    }
                }
                else
                {
                    /*
                     * @ 不允許修改就進入原始圖
                     */
                    if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:imagePickerController:)] ){
                        [self.KRCameraDelegate krCameraDidFinishPickingImage:[info objectForKey:@"UIImagePickerControllerOriginalImage"]
                                                                   imagePath:[NSString stringWithFormat:@"%@", [info objectForKey:UIImagePickerControllerReferenceURL]]
                                                       imagePickerController:picker];
                    }
                }
            }
        }
    }else {
        /*
         * @ 來源是相簿選擇的
         *   - 當關閉影片功能時
         */
        if (self.allowsSaveFile)
        {
            [self _writeToAlbum:info imagePicker:picker];
            //UIImageWriteToSavedPhotosAlbum(savedImage, self, nil, nil);
        }
        else
        {
            /*
             * @ 允許修改就顯示修改圖
             */
            if( self.allowsEditing || self.isAllowEditing )
            {
                if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishEditedImage:imagePath:imagePickerController:)] ){
                    [self.KRCameraDelegate krCameraDidFinishEditedImage:[info objectForKey:@"UIImagePickerControllerEditedImage"]
                                                              imagePath:[NSString stringWithFormat:@"%@", [info objectForKey:UIImagePickerControllerReferenceURL]]
                                                  imagePickerController:picker];
                }
            }
            else
            {
                /*
                 * @ 不允許修改就進入原始圖
                 */
                if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidFinishPickingImage:imagePath:imagePickerController:)] ){
                    [self.KRCameraDelegate krCameraDidFinishPickingImage:[info objectForKey:@"UIImagePickerControllerOriginalImage"]
                                                               imagePath:[NSString stringWithFormat:@"%@", [info objectForKey:UIImagePickerControllerReferenceURL]]
                                                   imagePickerController:picker];
                }
            }
        }

    }
    //[self remove];
    [self cancel];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self cancel];
    if( [self.KRCameraDelegate respondsToSelector:@selector(krCameraDidCancel:)] ){
        [self.KRCameraDelegate krCameraDidCancel:picker];
    }
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissPopover];
}

#pragma NavigationDelegate
-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    //...
}

-(void)navigationController:(UINavigationController *)navigationController
      didShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    //...
}

@end
