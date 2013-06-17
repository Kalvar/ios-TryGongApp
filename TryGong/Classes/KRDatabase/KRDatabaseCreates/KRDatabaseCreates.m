//
//  KRDatabaseCreates.m
//  
//
//  Created by Kalvar on 13/1/5.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import "KRDatabaseCreates.h"
#import "KRDatabase.h"
#import "VarDefines+HTTP.h"

@interface KRDatabaseCreates (fixPrivate)

-(void)_loadEvaulationData;
-(void)_createFavorites;
-(void)_createBrowses;
-(void)_createEvaluation;
-(void)_createCheckin;

@end

@implementation KRDatabaseCreates (fixPrivate)

-(void)_loadEvaulationData
{
    
}

-(void)_createFavorites
{
    /*
     * @ 建立儲存「我的最愛」資料表
     */
    NSDictionary *_tableParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"INTEGER PRIMARY KEY AUTOINCREMENT", @"favorite_id",
                                  @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"favorite_date",
                                  @"INT(10)", @"bar_id",
                                  @"INT(10)", @"user_id",
                                  nil];
    //建立資料表
    [self.krDatabase createTablesWithName:@"favorites" andParams:_tableParams];
}

-(void)_createBrowses
{
    /*
     * @ 建立儲存「瀏覽記錄」資料表
     */
    NSDictionary *_tableParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"INTEGER PRIMARY KEY AUTOINCREMENT", @"browse_id",
                                  @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"browse_date",
                                  @"INT(10)", @"bar_id",
                                  @"INT(10)", @"user_id",
                                  nil];
    //建立資料表
    [self.krDatabase createTablesWithName:@"browses" andParams:_tableParams];
}

-(void)_createEvaluation
{
    //建立「喜好評分」資料表 : 設定欄位型態 ( Copy「阿河」做的 Database Design )
    NSDictionary *_tableParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"INTEGER PRIMARY KEY AUTOINCREMENT", @"id",
                                  @"INT(4)", @"bar",
                                  @"INT(12)", @"comment",
                                  @"INT(10)", @"user",
                                  @"INT(8)", @"feeling1",
                                  @"INT(8)", @"feeling2",
                                  @"INT(8)", @"feeling3",
                                  @"FLOAT(8)", @"beauty",
                                  @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"updatetime",
                                  nil];
    //建立資料表
    [self.krDatabase createTablesWithName:@"evaluation" andParams:_tableParams];
}

-(void)_createCheckin
{
    /*
     * @ 建立儲存「打卡記錄」資料表
     */
    NSDictionary *_tableParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"INTEGER PRIMARY KEY AUTOINCREMENT", @"checkin_id",
                                  @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"checkin_date",
                                  @"INT(10)", @"bar_id",
                                  @"INT(10)", @"user_id",
                                  nil];
    //建立資料表
    [self.krDatabase createTablesWithName:@"checkins" andParams:_tableParams];
}

@end

@implementation KRDatabaseCreates

@synthesize krDatabase;

+(KRDatabaseCreates *)sharedManager{
    return [[self alloc] init];
}

-(id)init{
    self = [super init];
    if( self ){
        krDatabase = [[KRDatabase alloc] init];
    }
    return self;
}

//建立預設的資料表
-(void)createWithDefaultTables
{
    if( [self.krDatabase databaseExists] )
    {
        [self _createFavorites];
        [self _createBrowses];
        [self _createCheckin];
        //[self _createEvaluation];
    }
}



@end
