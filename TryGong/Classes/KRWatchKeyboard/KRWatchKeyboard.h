//
//  KRWatchKeyboard.h
//  
//
//  Created by Kalvar on 13/3/17.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KRWatchKeyboardDelegate;

@interface KRWatchKeyboard : NSObject
{
    __weak id<KRWatchKeyboardDelegate> delegate;
}

@property (nonatomic, weak) id<KRWatchKeyboardDelegate> delegate;

-(id)initWithDelegate:(id<KRWatchKeyboardDelegate>)_krWatchKeyboardDelegate;
-(void)startWatch;
-(void)stopWatch;

@end


@protocol KRWatchKeyboardDelegate <NSObject>

@optional
-(void)krWatchKeyboardWillShow:(CGRect)_foundKeyboardFrame;
-(void)krWatchKeyboardWillHide;

@end
