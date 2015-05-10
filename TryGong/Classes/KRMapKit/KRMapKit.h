//
//  KRMapKit.h
//  
//
//  Created by Kalvar on 12/12/14.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^AddressConversionCompleted)(NSDictionary *addresses, NSError *error);
typedef void (^LocationConversionCompleted)(CLLocationCoordinate2D convertedLocation);

@protocol KRMapKitDelegate;

@interface KRMapKit : NSObject<CLLocationManagerDelegate>
{
    //GPS Controller
    CLLocationManager *locationManager;
    //
    __weak id<KRMapKitDelegate> delegate;
    //民生路 195號
    NSString *street;
    //台中市
    NSString *subArea;
    //民生路
    NSString *thoroughfare;
    //403
    NSString *zip;
    //民生路 195號
    NSString *name;
    //台中市
    NSString *city;
    //台灣
    NSString *country;
    //台中市
    NSString *state;
    //西區
    NSString *subLocality;
    //195號
    NSString *subThoroughfare;
    //TW
    NSString *countryCode;
    
    
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) id<KRMapKitDelegate> delegate;
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *subArea;
@property (nonatomic, strong) NSString *thoroughfare;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *subLocality;
@property (nonatomic, strong) NSString *subThoroughfare;
@property (nonatomic, strong) NSString *countryCode;


-(id)initWithDelegate:(id<KRMapKitDelegate>)_krDelegate;
/*
 * 開始 / 結束定位
 */
-(void)startLocation;
-(void)stopLocation;
-(void)startLocationToConvertAddress:(AddressConversionCompleted)_addressHandler;
/*
 * 取得當前緯 / 經度
 */
-(CLLocationDegrees)currentLatitude;
-(CLLocationDegrees)currentLongitude;
/*
 * 將地址轉換成經緯度座標
 */
-(CLLocationCoordinate2D)reverseLocationFromAddress:(NSString *)_address;
-(void)reverseLocationFromAddress:(NSString *)_address completionHandler:(LocationConversionCompleted)_locationHandler;

@end

@protocol KRMapKitDelegate <NSObject>

@optional
/*
 * 已將經緯度轉換為地址資料
 */
-(void)krMapKit:(KRMapKit *)_theKRMapKit didReverseGeocodeLocation:(NSArray *)_placemarks;
/*
 * 已離開該區域
 */
-(void)krMapKitLocationManager:(CLLocationManager *)_locationManager didExitRegion:(CLRegion *)region;
/*
 * 已更新定位區域
 */
-(void)krMapKitLocationManager:(CLLocationManager *)_locationManager didUpdateLocations:(NSArray *)locations;
/*
 *
 */
-(void)krMapKitLocationManager:(CLLocationManager *)_locationManager didUpdateHeading:(CLHeading *)newHeading;


@end

