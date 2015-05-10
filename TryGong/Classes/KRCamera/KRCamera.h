//
//  KRCamera.h
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 2012/08/01.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

//相機運作模式
typedef enum _KRCameraModes {
    //相機模式
    KRCameraModesForCamera       = 0,
    //選取相簿模式
	KRCameraModesForSelectAlbum  = 1,
    //直接呈現全部的照片
    KRCameraModesForAllPhotos    = 2
} KRCameraModes;

@protocol KRCameraDelegate;

//截取影片示意圖用,需加入MediaPlayer.framework
//#import <MediaPlayer/MediaPlayer.h>

@interface KRCamera : UIImagePickerController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    __weak id parentTarget;
    __weak id<KRCameraDelegate> KRCameraDelegate;
    //選擇使用"拍照"或"檔案選取"方式
    KRCameraModes sourceMode;
    /*
     * @ 開啟或關閉影片(鏡頭)功能
     *
     * @ self.isOpenVideo 使用時機
     *
     *   - 1. 當需要照相時
     *   - 2. 當需要錄影時
     *   - 3. 當需要從相簿選擇影片時
     */
    BOOL isOpenVideo;
    //是否儲存圖片或影片
    BOOL allowsSaveFile;
    //錄影品質
    UIImagePickerControllerQualityType videoQuality;
    //錄影最大秒數
    NSUInteger videoMaxSeconds;
    //是否允許編輯
    BOOL isAllowEditing;
    //取出幾秒的影片
    int videoMaxDuration;
    //是否只開啟錄影功能
    BOOL isOnlyVideo;
    //是否自動縮下
    BOOL autoDismissPresent;
    //是否自動關閉
    BOOL autoRemoveFromSuperview;
    /*
     * @ 是否使用自訂義的 Toolbar 控制列 ?
     *   - 也就是原先官方的拍照按鈕會消失，而能改放自已客製化的按鈕上去，
     *     之後，使用自訂義的拍照按鈕時，就會直接進行拍照的 Delegate 和動作，
     *     而不會再進入「Preview」的確認畫面了。
     */
    BOOL displaysCameraControls;
    //如果要在 iPad 上顯示相機，就要用這個
    UIPopoverController *cameraPopoverController;
    //Device 是否支援相機
    BOOL supportCamera;
    //是否保持全螢幕
    BOOL keepFullScreen;
    //是否自適應 Camera 顯示
    BOOL sizeToCustomFit;
}

@property (nonatomic, weak) id parentTarget;
@property (nonatomic, weak) id<KRCameraDelegate> KRCameraDelegate;
@property (nonatomic, assign) KRCameraModes sourceMode;
@property (nonatomic, assign) BOOL isOpenVideo;
@property (nonatomic, assign, getter = isAllowsSaveFile) BOOL allowsSaveFile;
@property (nonatomic, assign) UIImagePickerControllerQualityType videoQuality;
@property (nonatomic, assign) NSUInteger videoMaxSeconeds;
@property (nonatomic, assign) BOOL isAllowEditing;
@property (nonatomic, assign) int videoMaxDuration;
@property (nonatomic, assign) BOOL isOnlyVideo;
@property (nonatomic, assign) BOOL autoDismissPresent;
@property (nonatomic, assign) BOOL autoRemoveFromSuperview;
@property (nonatomic, assign) BOOL displaysCameraControls;
@property (nonatomic, strong) UIPopoverController *cameraPopoverController;
@property (nonatomic, assign, getter = isSupportCamera) BOOL supportCamera;
@property (nonatomic, assign) BOOL keepFullScreen;
@property (nonatomic, assign) BOOL sizeToFitIphone5;

-(id)initWithDelete:(id<KRCameraDelegate>)_krCameraDelegate pickerMode:(KRCameraModes)_pickerMode;
-(id)initWithDelegate:(id<KRCameraDelegate>)_krCameraDelegate;
//
-(void)startChoose;
-(void)startCamera;
-(void)wantToFullScreen;
-(void)cancelFullScreen;
-(void)remove;
-(void)removeAndInitializeAllSettings;
-(void)cancel;
-(void)takeOnePicture;
//
-(void)hideStatusBar;
-(void)showStatusBar;
/*
 * iPad Using
 */
-(void)displayPopoverFromView:(UIView *)_fromTargetView inView:(UIView *)_showInView;
-(void)dismissPopover;
/*
 * 
 */
-(BOOL)isIpadDevice;
-(BOOL)isIphone5;
-(BOOL)isIOS7;
/*
 * @ 偵測 Device 支援項目
 */
-(BOOL)isDeviceSupportsCamera;
/*
 * @ 寫入相簿
 */
-(void)saveToAlbum:(UIImage *)_image completion:(void(^)(NSURL *assetURL, NSError *error))_completion;

@end

@protocol KRCameraDelegate <NSObject>

@optional
/*
 * @ 原始選取圖片、影片完成時，或拍完照、錄完影後
 *   - 要在這裡進行檔案的轉換、處理與儲存
 */
-(void)krCameraDidFinishPickingMediaWithInfo:(NSDictionary *)_infos imagePickerController:(UIImagePickerController *)_imagePicker;
/*
 * @ 對象是圖片
 */
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker;
/*
 * @ 對象是修改後的圖片
 */
-(void)krCameraDidFinishEditedImage:(UIImage *)_image imagePath:(NSString *)_imagePath imagePickerController:(UIImagePickerController *)_imagePicker;
/*
 * @ 對象是圖片並包含 EXIF / TIFF 等 MetaData 資訊
 */
-(void)krCameraDidFinishPickingImage:(UIImage *)_image imagePath:(NSString *)_imagePath metadata:(NSDictionary *)_metadatas imagePickerController:(UIImagePickerController *)_imagePicker;
/*
 * @ 對象是影片
 */
-(void)krCameraDidFinishPickingVideoPath:(NSString *)_videoPath imagePickerController:(UIImagePickerController *)_imagePicker;
/*
 * @ 按下取消時
 */
-(void)krCameraDidCancel:(UIImagePickerController *)_imagePicker;


@end
