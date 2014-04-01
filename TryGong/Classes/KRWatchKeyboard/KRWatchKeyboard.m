//
//  KRWatchKeyboard.m
//  
//
//  Created by Kalvar on 13/3/17.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "KRWatchKeyboard.h"

@interface KRWatchKeyboard ()

@end

@interface KRWatchKeyboard (fixPrivate)

@end

@implementation KRWatchKeyboard (fixPrivate)

/*
 * Keyboard 監聽事件專用
 */
//先經由這裡呼叫下一支 Code，Keyboard 的控制會更精確( 否則有時會出現操作失敗的情形 )
-(void)_keyboardWillShowOnDelay:(NSNotification *)notification
{
    [self performSelector:@selector(_keyboardWillShow:) withObject:notification afterDelay:0];
}

//實際 Run 的 Function
-(void)_keyboardWillShow:(NSNotification *)notification
{
    UIView *foundKeyboard    = nil;
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]){
        if (![[testWindow class] isEqual:[UIWindow class]]){
            keyboardWindow = testWindow;
            break;
        }
    }
    if (!keyboardWindow) return;
    for ( __weak UIView *possibleKeyboard in [keyboardWindow subviews])
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
    
    if (foundKeyboard)
    {
        if( self.delegate )
        {
            if( [self.delegate respondsToSelector:@selector(krWatchKeyboardWillShow:)] )
            {
                [self.delegate krWatchKeyboardWillShow:foundKeyboard.frame];
            }
        }
    }
}

-(void)_keyboardWillHide:(NSNotification *)notification
{
    if( self.delegate )
    {
        if( [self.delegate respondsToSelector:@selector(krWatchKeyboardWillHide)] )
        {
            [self.delegate krWatchKeyboardWillHide];
        }
    }
}

-(void)_removeNotification
{
    /* 栘除監聽事件 No longer listen for keyboard */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

@end

@implementation KRWatchKeyboard

@synthesize delegate;

-(id)initWithDelegate:(id<KRWatchKeyboardDelegate>)_krWatchKeyboardDelegate
{
    self = [super init];
    if( self )
    {
        self.delegate = _krWatchKeyboardDelegate;
    }
    return self;
}

-(void)startWatch
{
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

-(void)stopWatch
{
    [self _removeNotification];
}

@end
