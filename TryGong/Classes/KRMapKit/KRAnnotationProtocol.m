//
//  SelfMKAnnotationProtocol.m
//  KRMapKit
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 12/11/25.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//
#import "KRAnnotationProtocol.h"

@implementation KRAnnotationProtocol

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
//
@synthesize customTitle, customSubtitle;
@synthesize barId;
@synthesize imageURL;
@synthesize categoryId;
@synthesize isPromotions;

-(id)initWithCoordinate:(CLLocationCoordinate2D)_theCoordinate
            customTitle:(NSString *)_theTitle
         customSubtitle:(NSString *)_theSubtitle
{
    self = [super init];
    if( self )
    {
        self.title          = @" ";
        self.subtitle       = @" ";
        self.customTitle    = _theTitle;
        self.customSubtitle = _theSubtitle;
        self.coordinate     = _theCoordinate;
        self.isPromotions   = NO;
    }
    return self;
}

-(void)delloc
{    
    self.title    = nil;
    self.subtitle = nil;
    //
    self.customTitle = nil;
    self.customSubtitle = nil;
    self.barId    = nil;
    self.imageURL = nil;
    self.categoryId = nil;
}



@end
