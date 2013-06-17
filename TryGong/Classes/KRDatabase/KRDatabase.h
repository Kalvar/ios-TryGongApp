//
//  Database.h
//
//  Version 1.1
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2012/06/01.
//  Copyright 2011 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>

#define DBNAME              @"i98_db"
#define DBEXT               @".sqlite3"
#define DEFAULT_STRING      @"NO"
#define DEFAULT_LIMIT_START 0
#define DEFAULT_LIMIT_END   10

@interface KRDatabase : NSObject{

@public
    BOOL isConnecting;
    
@protected
    sqlite3 *database;
    
}

@property (nonatomic, assign) BOOL isConnecting;


+(KRDatabase *)sharedManager;
/*
 * @ 不自動連線資料庫
 */
-(id)initWaitingForConnection;
/*
 * @ 取得資料庫檔案存放完整路徑名稱
 */
-(NSString *)getDatabaseSavedPath;
/*
 * @ 取得資料庫檔案存放完整路徑名稱
 */
+(NSString *)databaseFilePath;
/*
 * @ 檢查資料庫檔案是否存在
 */
-(BOOL)databaseExists;
/*
 * @ 檢查資料庫檔案是否存在
 */
+(BOOL)databaseExists;
/*
 * @ 準備資料庫
 */
-(void)readyDatabase;
/*
 * @ 如果資料庫不存在，才 Copy mainBundle 底下的預備資料庫，至 Document 底下
 */
+(void)copyDefaultToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType;
-(void)copyDefaultToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType;
/*
 * @ 直接複製 App 指定在 mainBundle 路徑底下的資料庫，覆蓋到 App 的 Document 文件路徑底下
 */
-(void)copyMainBundleDatabaseToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType;
/*
 * @ 當資料庫不存在時複製 mainBundle 裡的預備資料庫
 */
-(void)copyWithoutDatabase;
/*
 * @ 連結資料庫
 */
-(int)connectDatabase;
/*
 * @ 關閉資料庫
 */
-(void)closeDatabase;
/*
 * @ 刪除資料庫
 */
-(void)dropDatabase;
/*
 * @ 查詢(可限定查詢結果要取得表單裡哪幾個欄位的值)
 */
-(NSMutableArray *)execSelect:(NSString *)_sqlString 
                resultColumns:(int)_cols;
/*
 * @ 直接查詢
 */
-(NSMutableArray *)execSelect:(NSString *)_sqlString;
/*
 * @ 執行自帶參數的
 *   - 新增
 *   - 刪除
 *   - 修改
 */
-(BOOL)execQuery:(NSString *)_sqlString sqlParams:(NSArray *)_params;
/*
 * @ 直接執行 INSERT, UPDATE, DELETE 等等非查詢動作的語法
 */
-(BOOL)execQuery:(NSString *)_sqlString;
-(BOOL)execQuery:(NSString *)_sqlString failedToCache:(BOOL)_whenFailedToCache;
/*
 * @ 重新執行失敗的 SQL 語句快取記錄
 */
-(void)rerunFailedCaches;
/*
 * @ 取得執行失敗的 SQL 語句歴史快取記錄
 */
-(NSMutableArray *)getFailedCaches;
/*
 * @ 直接執行 INSERT 後，會回傳 INSERT 的 ID
 */
-(NSString *)execInsertQueryThenReturnId:(NSString *)_sqlString;
/*
 * @ 取得指定查詢的 SQL 語句資料總筆數
 */
-(int)getRowsNumbersOfExecSQL:(NSString *)_sqlString;
/*
 * @ 取得指定資料表的資料總筆數
 */
-(int)getRowsNumbersOfExecTable:(NSString *)_tableName;
/*
 * @ 直接計算分頁
 *   - 總頁數
 *   - 現在頁數
 *   - Limit Start
 *   - Limit End
 */
-(NSDictionary *)calculatePagesWithTotal:(int)_totalPages
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end;
/*
 * @ 指定資料表計算分頁
 *   - 總頁數
 *   - 現在頁數
 *   - Limit Start
 *   - Limit End
 */
-(NSDictionary *)calculatePagesWithTable:(NSString *)_tableName 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end;
/*
 * @ 直接執行 SQL 語句
 */
-(void)directExecSQL:(NSString *)_sqlString;
/*
 * @ 新建資料表
 */
-(void)createTablesWithName:(NSString *)_tableName
                  andParams:(NSDictionary *)_params;
/*
 * @ 刪除資料表
 */
-(void)dropTableWithName:(NSString *)_tableName;
/*
 * @ 重新命名資料表名稱
 */
-(void)alterTableWithName:(NSString *)_oldTableName renameTo:(NSString *)_newTableName;
/*
 * @ 增加資料表欄位
 */
-(void)alterTableWithName:(NSString *)_tableName addColumns:(NSDictionary *)_params;

@end
