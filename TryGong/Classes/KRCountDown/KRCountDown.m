//
//  KRCountDown.m
//  V0.5
//
//  Created by Kalvar on 2014/5/2.
//  Copyright (c) 2014年 Kuo-Ming Lin. All rights reserved.
//

#import "KRCountDown.h"

@interface KRCountDown ()

@property (nonatomic, strong) NSTimer *_timer;

@end

@implementation KRCountDown (fixTimers)

-(void)_firedEvent
{
    if( self.fireCompletion )
    {
        self.fireCompletion();
    }
}

-(void)_startTimerWithFireCompletion:(FireCompletion)_fireCompletion
{
    [self _stopTimer];
    if( !self._timer )
    {
        self.fireCompletion = _fireCompletion;
        self._timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                       target:self
                                                     selector:@selector(_firedEvent)
                                                     userInfo:nil
                                                      repeats:YES];
        [self._timer fire];
    }
}

-(void)_startTimer
{
    [self _startTimerWithFireCompletion:nil];
}

-(void)_stopTimer
{
    if( self._timer )
    {
        [self._timer invalidate];
        self._timer = nil;
    }
}

@end

@implementation KRCountDown

@synthesize view           = _view;
@synthesize backgroundView = _backgroundView;
@synthesize textLabel      = _textLabel;

@synthesize fireCompletion = _fireCompletion;

+(instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static KRCountDown *_object = nil;
    dispatch_once(&pred, ^{
        _object = [[KRCountDown alloc] init];
    });
    return _object;
}

-(instancetype)init
{
    self = [super init];
    if( self )
    {
        _view                 = nil;
        _backgroundView       = nil;
        _textLabel            = nil;
        _fireCompletion       = nil;
        
    }
    return self;
}

-(void)start
{
    if( !self.view )
    {
        return;
    }
    
    if( !self.backgroundView )
    {
        CGRect _frame = CGRectMake(0.0f, 0.0f, _view.frame.size.width, _view.frame.size.height);
        
        _backgroundView = [[UIView alloc] initWithFrame:_frame];
        [_backgroundView setTag:900];
        [_backgroundView setBackgroundColor:[UIColor blackColor]];
        [_backgroundView setAlpha:1.0];
        
        _textLabel = [[UILabel alloc] initWithFrame:_frame];
        [_textLabel setText:@""];
        [_textLabel setTextColor:[UIColor whiteColor]];
        [_textLabel setFont:[UIFont boldSystemFontOfSize:0.0f]];
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        [_textLabel setAlpha:0.0f];
        [_backgroundView addSubview:_textLabel];
    }
    
    if( _backgroundView.superview != _view )
    {
        [_view addSubview:_backgroundView];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_textLabel setText:@"0"];
        [_backgroundView setHidden:NO];
    });
    
    dispatch_queue_t queue = dispatch_queue_create("_countDownQueue", NULL);
    dispatch_async(queue, ^(void){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _startTimerWithFireCompletion:^
             {
                 NSInteger _number = [_textLabel.text integerValue] + 1;
                 [_textLabel setText:[NSString stringWithFormat:@"%i", _number]];
                 
                 [UIView animateWithDuration:0.8f animations:^{
                     [_textLabel setAlpha:1.0f];
                     [_textLabel setFont:[UIFont boldSystemFontOfSize:90.0f]];
                 } completion:^(BOOL finished) {
                     if( self._timer.isValid )
                     {
                         [UIView animateWithDuration:0.1f animations:^{
                             [_textLabel setAlpha:0.0f];
                             [_textLabel setFont:[UIFont boldSystemFontOfSize:0.0f]];
                         }];
                     }
                     else
                     {
                         [_textLabel setAlpha:0.0f];
                         [_textLabel setFont:[UIFont boldSystemFontOfSize:0.0f]];
                     }
                 }];
             }];
        });
    });
}

-(void)restart
{
    [self _startTimerWithFireCompletion:_fireCompletion];
}

-(void)pause
{
    [self _stopTimer];
}

-(void)stop
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self _stopTimer];
        [_textLabel setText:@""];
        [_textLabel setAlpha:0.0f];
        [_textLabel setFont:[UIFont boldSystemFontOfSize:0.0f]];
        [_backgroundView setHidden:YES];
    });
}

#pragma --mark Blocks
-(void)setFireCompletion:(FireCompletion)_theBlock
{
    _fireCompletion = _theBlock;
}


@end
