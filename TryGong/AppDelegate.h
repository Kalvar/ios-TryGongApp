//
//  AppDelegate.h
//  TryGong V1.4
//
//  Created by Kalvar on 13/3/28.
//  Copyright (c) 2013 - 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class KRMixCameraViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) KRMixCameraViewController *viewController;
//Facebook
@property (strong, nonatomic) FBSession *session;

@end
