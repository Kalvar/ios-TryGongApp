//
//  KRCountDown.h
//  V0.5
//
//  Created by Kalvar on 2014/5/2.
//  Copyright (c) 2014年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FireCompletion)(void);

@interface KRCountDown : NSObject

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, copy) FireCompletion fireCompletion;

+(instancetype)sharedInstance;
-(instancetype)init;
-(void)start;
-(void)restart;
-(void)pause;
-(void)stop;

#pragma --mark Blocks
-(void)setFireCompletion:(FireCompletion)_theBlock;

@end
