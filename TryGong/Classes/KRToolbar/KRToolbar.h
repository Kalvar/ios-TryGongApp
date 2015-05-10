//
//  KRToolbar.h
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 12/10/29.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KRToolbarDelegate;

@interface KRToolbar : NSObject
{
    id<KRToolbarDelegate> __weak delegate;
    UIToolbar *toolbar;
    UIView *view;
    BOOL linkMove;
}

@property (nonatomic, weak) id<KRToolbarDelegate> delegate;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) BOOL linkMove;

-(id)init;
-(id)initWithToolbar:(UIToolbar *)_aToolbar mappingView:(UIView *)_aView;
-(void)setToolbar:(UIToolbar *)_aToolbar mappingView:(UIView *)_aView;
-(void)watchKeyboard;
-(void)leaveKeyboard;
-(void)hide;
-(void)show;

@end

@protocol KRToolbarDelegate <NSObject>

@optional
//只要是還會出現 Toolbar 的狀態，都會執行這裡
-(void)krToolbar:(KRToolbar *)_aKRToolbar slidingToPoints:(CGPoint)_toPoints;
//追路正在改變上昇高度時
-(void)krToolbar:(KRToolbar *)_aKRToolbar trackChangingSlideUpToPoints:(CGPoint)_toPoints;
//追路正在改變下降高度時
-(void)krToolbar:(KRToolbar *)_aKRToolbar trackChangingSlideDownToPoints:(CGPoint)_toPoints;
//結束並下降隱藏 Toolbar
-(void)krToolbar:(KRToolbar *)_aKRToolbar didFinishedAndHideToolbarToPoints:(CGPoint)_toPoints;

@end