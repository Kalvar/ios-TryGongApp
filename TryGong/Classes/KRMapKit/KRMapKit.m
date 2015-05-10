//
//  KRMapKit.m
//  
//
//  Created by Kalvar on 12/12/14.
//  Copyright (c) 2012年 Kuo-Ming Lin. All rights reserved.
//

#import "KRMapKit.h"

@interface KRMapKit (fixPrivate)

-(void)_locationCurrent:(CLLocation *)_locations;

@end

@implementation KRMapKit (fixPrivate)

//取出現在的定位「地區」，例如西區、東區
-(void)_locationCurrent:(CLLocation *)_locations
{
    CLGeocoder *_gecoder = [[CLGeocoder alloc] init];
    
    [_gecoder reverseGeocodeLocation:_locations
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       /*
                        * @place.addressDictionary 的地址轉換 Key / Value
                        *
                        * @台中市西區 Sample
                        *
                        *   Street                : 民生路 195號
                        *   SubAdministrativeArea : 台中市
                        *   Thoroughfare          : 民生路
                        *   ZIP                   : 403
                        *   Name                  : 民生路 195號
                        *   City                  : 台中市
                        *   Country               : 台灣
                        *   State                 : 台中市
                        *   SubLocality           : 西區
                        *   SubThoroughfare       : 195號
                        *   CountryCode           : TW
                        *
                        * @台中市大里區 Sample
                        *
                        *   Street                : 東榮路412巷 1號
                        *   SubAdministrativeArea : 台中市
                        *   Thoroughfare          : 東榮路412巷
                        *   ZIP                   : 412
                        *   Name                  : 東榮路412巷 1號
                        *   City                  : 大里區
                        *   Country               : 台灣
                        *   State                 : 台中市
                        *   SubLocality           : null
                        *   SubThoroughfare       : 1號
                        *   CountryCode           : TW
                        *
                        */                       
                       for( CLPlacemark *_placemark in placemarks ){
                           self.street          = [_placemark.addressDictionary objectForKey:@"Street"];
                           //副行政區
                           self.subArea         = [_placemark.addressDictionary objectForKey:@"SubAdministrativeArea"];
                           //路名
                           self.thoroughfare    = [_placemark.addressDictionary objectForKey:@"Thoroughfare"];
                           self.zip             = [_placemark.addressDictionary objectForKey:@"ZIP"];
                           self.name            = [_placemark.addressDictionary objectForKey:@"Name"];
                           self.city            = [_placemark.addressDictionary objectForKey:@"City"];
                           self.country         = [_placemark.addressDictionary objectForKey:@"Country"];
                           //洲
                           self.state           = [_placemark.addressDictionary objectForKey:@"State"];
                           //行政區
                           self.subLocality     = [_placemark.addressDictionary objectForKey:@"SubLocality"];
                           //門牌號碼
                           self.subThoroughfare = [_placemark.addressDictionary objectForKey:@"SubThoroughfare"];
                           self.countryCode     = [_placemark.addressDictionary objectForKey:@"CountryCode"];
                           //format
                           if( !self.subLocality ){
                               self.subLocality = self.city;
                           }
                           /*
                           for( NSString *_key in _placemark.addressDictionary ){
                               NSLog(@"%@ : %@", _key, [_placemark.addressDictionary objectForKey:_key]);
                           }
                            */
                           break;
                       }
                       if( [self.delegate respondsToSelector:@selector(krMapKit:didReverseGeocodeLocation:)] ){
                           [self.delegate krMapKit:self didReverseGeocodeLocation:placemarks];
                       }
                   }];
    
}


@end

@implementation KRMapKit

@synthesize locationManager;
@synthesize delegate;
@synthesize street;
@synthesize subArea;
@synthesize thoroughfare;
@synthesize zip;
@synthesize name;
@synthesize city;
@synthesize country;
@synthesize state;
@synthesize subLocality;
@synthesize subThoroughfare;
@synthesize countryCode;


-(id)initWithDelegate:(id<KRMapKitDelegate>)_krDelegate{
    self = [super init];
    if( self ){
        self.delegate   = _krDelegate;
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
    }
    return self;
}

-(void)startLocation{
    //先停止定位
    [self.locationManager stopUpdatingLocation];
    //再開始定位
    [self.locationManager startUpdatingLocation];
    //設定當使用者的位置超出 X 公尺後才呼叫其他定位方法 :: 預設為 kCLDistanceFilterNone
    self.locationManager.distanceFilter = 10.0f;
    //顯示目前地區
    [self _locationCurrent:self.locationManager.location];
}

-(void)stopLocation
{
    [self.locationManager stopUpdatingLocation];
}

-(void)startLocationToConvertAddress:(AddressConversionCompleted)_addressHandler
{
    [self startLocation];
    CLGeocoder *_gecoder = [[CLGeocoder alloc] init];
    [_gecoder reverseGeocodeLocation:self.locationManager.location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       _addressHandler( [(CLPlacemark *)[placemarks lastObject] addressDictionary], error );
                   }];
}

-(CLLocationDegrees)currentLatitude
{
    return self.locationManager.location.coordinate.latitude;
    //return [NSString stringWithFormat:@"%lf", self.locationManager.location.coordinate.latitude];
}

-(CLLocationDegrees)currentLongitude
{
    return self.locationManager.location.coordinate.longitude;
    //return [NSString stringWithFormat:@"%lf", self.locationManager.location.coordinate.longitude];
}

/*
 * @ 由地址解析經緯度
 */
-(CLLocationCoordinate2D)reverseLocationFromAddress:(NSString *)_address
{
    /*
     * @ 設定 URL 並執行 Escape 的動作
     *   - 回傳 CSV 字串 ( 也能改成 JSON : output=json )
     */
    NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%@&output=csv",
                           [_address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //送出 URL 並同時解析回字串
    NSString *locationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString]
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    //切割字串
    NSArray *responseArray = [locationString componentsSeparatedByString:@","];
    //取出經緯度
    CLLocationCoordinate2D _convertedLocation;
    //回應值 >= 4 組 && 回應的 HTTP Code 為 200 為正確
    if( [responseArray count] >= 4 && [[responseArray objectAtIndex:0] isEqualToString:@"200"] )
    {
        //緯度
        _convertedLocation.latitude  = [[responseArray objectAtIndex:2] doubleValue];
        //經度
        _convertedLocation.longitude = [[responseArray objectAtIndex:3] doubleValue];
    }
    else
    {
        _convertedLocation.latitude  = -1.0f;
        _convertedLocation.longitude = -1.0f;
    }
    return _convertedLocation;
}

-(void)reverseLocationFromAddress:(NSString *)_address completionHandler:(LocationConversionCompleted)_locationHandler
{
    _locationHandler( [self reverseLocationFromAddress:_address] );
}

#pragma CLLocationManagerDelegate
/*
 * 當使用者進入指定的區域時觸發
 */
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    //NSLog(@"1");
}

/*
 * 當使用者離開指定的區域時觸發。
 */
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    //[self _locationHereCorn:manager.location];
    if( [self.delegate respondsToSelector:@selector(krMapKitLocationManager:didExitRegion:)] ){
        [self.delegate krMapKitLocationManager:manager didExitRegion:region];
    }
    //NSLog(@"2");
}

/*
 * 每次定位，這裡都一定會先被執行個 2 次，
 * 之後會再依照「GPS」定位的改變，會再執行這裡，
 * 而每次實機靜止不動時，其實 GPS 還是會不斷的變更定位的位置，
 * 有時 10 秒、20 秒、30 秒 ... 或更多秒不等，
 * 就會執行這裡一次，總之，只要 Location 更新了( 經緯度改變 ; 附近 Wifi / 3G 的定位在實際上很常變動 )，這裡就會跑。
 */
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //[self _locationHereCorn:manager.location];
    if( [self.delegate respondsToSelector:@selector(krMapKitLocationManager:didUpdateLocations:)] ){
        [self.delegate krMapKitLocationManager:manager didUpdateLocations:locations];
    }
    //NSLog(@"3");
}

/*
 * 取得 GPS 羅盤方向 (以角度為單位，以順時針計算) : 正北方 0 度 / 正東方 90 度 / 正南方 180 度 / 正西方 270 度
 */
//當 CLLocationManager 取得更新後的方向資訊時觸發
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
    if( [self.delegate respondsToSelector:@selector(krMapKitLocationManager:didUpdateHeading:)] ){
        [self.delegate krMapKitLocationManager:manager didUpdateHeading:newHeading];
    }
//    //取得與「磁北」方向的夾角角度
//    NSString *magneticHeading = [NSString stringWithFormat:@"%g degrees", newHeading.magneticHeading];
//    
//    //取得與「真北」方向的夾角角度
//    NSString *trueHeading = [NSString stringWithFormat:@"%g degrees", newHeading.trueHeading];
//    
//    //取得度量方向的精確度數值 : 正值為真實方向與磁北方向的誤差值，負值為方向不準確
//    NSString *missDegrees = [NSString stringWithFormat:@"%g degrees", newHeading.headingAccuracy];
//    
//    NSLog(@"與真北的角度 : %@ \n 與磁北的角度 : %@ \n 與磁北的誤差角度為 : %@ \n", magneticHeading, trueHeading, missDegrees);
//    
//    double locationSpeed = manager.location.speed;
//    NSLog(@"目前行進方向的瞬時速度 : %lf \n", locationSpeed);
    
    //NSLog(@"4");
}

/* 
 * 當無法取得地理位置資訊時觸發(定位錯誤)
 */
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error : %@ \n", [error description]);
}

/* 
 * 當 CLLocationManager 無法監控使用者是否進入或離開某區域時觸發
 */
-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    
    NSLog(@"Error : %@ \n", [error description]);
}

/* 
 * 告知系統是否可以顯示狀態列上的方向指標
 */
-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
}


@end
