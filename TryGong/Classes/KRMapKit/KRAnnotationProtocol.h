//
//  SelfMKAnnotationProtocol.h
//  KRMapKit
//
//  ilovekalvar@gmail.com
//
//  Created by Kuo-Ming Lin on 12/11/25.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//自訂義 MKAnnotatioin Protocol 協定
@interface KRAnnotationProtocol : NSObject <MKAnnotation>
{
    //原生的設定
    CLLocationCoordinate2D coordinate;
    //如果要客製化 leftCallout 的話，這裡不能有文字的設定
    NSString *title;
    NSString *subtitle;
    //改設定這裡
    NSString *customTitle;
    NSString *customSubtitle;
    //
    NSString *barId;
    NSString *imageURL;
    NSString *categoryId;
    BOOL isPromotions;
}

//宣告 coordinate
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
//
@property (nonatomic, strong) NSString *customTitle;
@property (nonatomic, strong) NSString *customSubtitle;
@property (nonatomic, strong) NSString *barId;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *categoryId;
@property (nonatomic, assign) BOOL isPromotions;

-(id)initWithCoordinate:(CLLocationCoordinate2D)_theCoordinate customTitle:(NSString *)_theTitle customSubtitle:(NSString *)_theSubtitle;


@end

