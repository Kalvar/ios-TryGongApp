//
//  KRMixCameraViewController.h
//  V1.4 
//
//  Created by Kalvar on 13/5/5.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>

//裁圖模式
typedef enum KRMixCameraImageCutModes
{
    //不裁
    KRMixCameraImageCutModesForNone = 0,
    //從中間裁
    KRMixCameraImageCutModesForCenter,
    //左上
	KRMixCameraImageCutModesForLeftTop,
    //左下
    KRMixCameraImageCutModesForLeftBottom,
    //右上
    KRMixCameraImageCutModesForRightTop,
    //右下
    KRMixCameraImageCutModesForRightBottom
} KRMixCameraImageCutModes;

@protocol KRMixCameraDelegate;

@interface KRMixCameraViewController : UIViewController<UIScrollViewDelegate, UITextFieldDelegate>
{
    __weak id<KRMixCameraDelegate> delegate;
    NSString *subtitle;
    
}

@property (nonatomic, weak) id<KRMixCameraDelegate> delegate;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, weak) IBOutlet UIView *outCameraView;
@property (nonatomic, weak) IBOutlet UIView *outControlView;
@property (nonatomic, weak) IBOutlet UIView *outCameraToolView;
@property (nonatomic, weak) IBOutlet UIView *outShareToolView;
@property (nonatomic, weak) IBOutlet UIScrollView *outScrollView;
@property (nonatomic, weak) IBOutlet UIPageControl *outPageControl;
@property (nonatomic, weak) IBOutlet UIImageView *outPhotoImageView;
@property (nonatomic, weak) IBOutlet UIView *outShareView;
@property (nonatomic, weak) IBOutlet UIButton *outFBLoginButton;
@property (nonatomic, weak) IBOutlet UIButton *outSwitchCameraButton;
@property (nonatomic, weak) IBOutlet UIButton *outSwitchFlashButton;
@property (nonatomic, weak) IBOutlet UITextField *outWordsTextField;


-(id)initWithDelegate:(id<KRMixCameraDelegate>)_krMixCameraDelegate;
-(void)startCamera;
-(void)dismiss;
-(void)clearMemory;

-(IBAction)takePicture:(id)sender;
-(IBAction)choosePicture:(id)sender;
-(IBAction)changeCamera:(id)sender;
-(IBAction)changeFlash:(id)sender;
-(IBAction)showMenu:(id)sender;
-(IBAction)dismissCamera:(id)sender;
-(IBAction)changePage:(id)sender;
-(IBAction)turnToCameraMode:(id)sender;
-(IBAction)shareToFacebook:(id)sender;
-(IBAction)cancelShare:(id)sender;
-(IBAction)loginFacebook:(id)sender;
-(IBAction)saveInAlbum:(id)sender;

@end

@protocol KRMixCameraDelegate <NSObject>

@optional
-(void)krMixCameraWantToSharePhoto:(UIImage *)_shareImage;

@end