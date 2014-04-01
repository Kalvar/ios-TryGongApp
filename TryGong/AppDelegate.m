//
//  AppDelegate.m
//  TryGong
//
//  Created by Kalvar on 13/3/28.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "AppDelegate.h"
#import "KRMixCameraViewController.h"
#import "VarDefines+HTTP.h"

@interface AppDelegate (fixPrivate)

-(BOOL)_isIphone5;

@end

@implementation AppDelegate (fixPrivate)

-(BOOL)_isIphone5
{
    CGRect _screenBounds = [[UIScreen mainScreen] bounds];
    if( _screenBounds.size.width > 480.0f && _screenBounds.size.width <= 568.0f )
    {
        return YES;
    }
    if( _screenBounds.size.height > 480.0f && _screenBounds.size.width <= 568.0f )
    {
        return YES;
    }
    return NO;
}

@end

@implementation AppDelegate

@synthesize session = _session;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *_viewControllerXibName = [self _isIphone5] ? @"KRMixCameraViewController_iPhone5" : @"KRMixCameraViewController";
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[KRMixCameraViewController alloc] initWithNibName:_viewControllerXibName bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

#pragma Facebook SDK 3.1.1 處理流程
// FBSample logic
// The native facebook application transitions back to an authenticating application when the user
// chooses to either log in, or cancel. The url passed to this method contains the token in the
// case of a successful login. By passing the url to the handleOpenURL method of a session object
// the session object can parse the URL, and capture the token for use by the rest of the authenticating
// application; the return value of handleOpenURL indicates whether or not the URL was handled by the
// session object, and does not reflect whether or not the login was successful; the session object's
// state, as well as its arguments passed to the state completion handler indicate whether the login
// was successful; note that if the session is nil or closed when handleOpenURL is called, the expression
// will be boolean NO, meaning the URL was not handled by the authenticating application
/*
 * @ 當離開 App 進行登入的動作時，跳回來時的處理動作在這裡執行
 */
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // attempt to extract a token from the url
    return [self.session handleOpenURL:url];
}

// FBSample logic
// Whether it is in applicationWillTerminate, in applicationDidEnterBackground, or in some other part
// of your application, it is important that you close an active session when it is no longer useful
// to your application; if a session is not properly closed, a retain cycle may occur between the block
// and an object that holds a reference to the session object; close releases the handler, breaking any
// inadvertant retain cycles
- (void)applicationWillTerminate:(UIApplication *)application
{
    // FBSample logic
    // if the app is going away, we close the session if it is open
    // this is a good idea because things may be hanging off the session, that need
    // releasing (completion block, etc.) and other components in the app may be awaiting
    // close notification in order to do cleanup
    [self.session close];
}

// FBSample logic
// It is possible for the user to switch back to your application, from the native Facebook application,
// when the user is part-way through a login; You can check for the FBSessionStateCreatedOpenening
// state in applicationDidBecomeActive, to identify this situation and close the session; a more sophisticated
// application may choose to notify the user that they switched away from the Facebook application without
// completely logging in
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // FBSample logic
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}


@end
