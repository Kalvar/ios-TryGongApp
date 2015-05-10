//
//  Database.m
//
//  Version 1.1
//
//  Created by Kuo-Ming Lin ( Kalvar ; ilovekalvar@gmail.com ) on 2012/06/01.
//  Copyright 2011 Kuo-Ming Lin. All rights reserved.
//
#import "KRDatabase.h"

@interface KRDatabase ()
{
    NSMutableArray *_failureCaches;
}

@property (nonatomic, strong) NSMutableArray *_failureCaches;

@end

@interface KRDatabase (Private)

-(void)_allocFailureCaches;
-(NSString *)_trimString:(NSString *)_string;
-(BOOL)_stringIsEmpty:(NSString *)_checkString;

@end

@implementation KRDatabase (Private)

-(void)_allocFailureCaches
{
    if( !_failureCaches )
    {
        _failureCaches = [[NSMutableArray alloc] initWithCapacity:0];
    }
}

-(BOOL)_stringIsEmpty:(NSString *)_checkString
{
    NSString *_string = [self _trimString:[NSString stringWithFormat:@"%@", _checkString]];
    return ( [_string isEqualToString:@""] || [_string length] < 1 ) ? YES : NO;
}

-(NSString *)_trimString:(NSString *)_string
{
    return [_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


@implementation KRDatabase

@synthesize isConnecting;
//
@synthesize _failureCaches;

+(KRDatabase *)sharedManager
{
    return [[self alloc] init];
}

/*
 * @ 會自動連線資料庫
 */
-(id)init
{
    self = [super init];
    if (self)
    {
        self.isConnecting = ( [self connectDatabase] == SQLITE_OK );
        [self _allocFailureCaches];
    }
    return self;
}

/*
 * @ 不自動連線資料庫
 *  
 *   - 等待手動連線 : [self connectDatabase];
 */
-(id)initWaitingForConnection
{
    self = [super init];
    if (self)
    {
        self.isConnecting = NO;
        [self _allocFailureCaches];
    }
    return self;
}

/*
 * @ 取得資料庫檔案存放完整路徑名稱
 *   - 會存放於 Document 底下
 */
-(NSString *)getDatabaseSavedPath
{
    //取得根目錄路徑集合陣列
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //取得根目錄
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //結合 DB 檔案全名
    NSString *fullDbName = [NSString stringWithFormat:@"%@%@", DBNAME, DBEXT];
    //組合成資料庫檔案完整路徑回傳
    return [documentsDirectory stringByAppendingPathComponent:fullDbName];    
}

/*
 * @ 取得資料庫檔案存放完整路徑名稱
 */
+(NSString *)databaseFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [(NSString *)[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", DBNAME, DBEXT]];
}

/*
 * @ 檢查資料庫檔案是否存在
 */
-(BOOL)databaseExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self getDatabaseSavedPath]];
}

/*
 * @ 檢查資料庫檔案是否存在
 */
+(BOOL)databaseExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self databaseFilePath]];
}

/*
 * @ 準備資料庫
 */
-(void)readyDatabase
{
    if( ![self databaseExists] )
    {
        //複製預備資料庫
        [self copyWithoutDatabase];
    }    
}

/*
 * @ 複製預設資料庫
 *
 *   - 如果資料庫不存在，才 Copy mainBundle 底下的預備資料庫，至 Document 底下。
 */
+(void)copyDefaultToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType
{
    if( ![self databaseExists] )
    {
        NSLog(@"資料庫不存在，故須 Copy 預設資料庫至 %@", [self databaseFilePath]);
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:_mainBundleDbName ofType:_mainBundleDbType]
                                                toPath:[self databaseFilePath]
                                                 error:&error];
    }
}

/*
 * @ 說明
 *   - 如果資料庫不存在，才 Copy mainBundle 底下的預備資料庫，至 Document 底下。
 */
-(void)copyDefaultToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType
{
    if( ![self databaseExists] )
    {
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:_mainBundleDbName ofType:_mainBundleDbType]
                                                toPath:[self getDatabaseSavedPath]
                                                 error:&error];
    }
}

/*
 * @ 說明
 *
 *   - 直接複製 App 指定在 mainBundle 路徑底下的資料庫，覆蓋到 App 的 Document 文件路徑底下。
 *
 */
-(void)copyMainBundleDatabaseToDocumentWithName:(NSString *)_mainBundleDbName ofType:(NSString *)_mainBundleDbType
{
    NSString *_dbMainBundlePath = [[NSBundle mainBundle] pathForResource:_mainBundleDbName ofType:_mainBundleDbType];
    //NSString *_dbMainBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", _mainBundleDbName, _mainBundleDbType]];
    //NSLog(@"_dbMainBundlePath : %@", _dbMainBundlePath);
    //Copy to Document 的位置
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *_dbDocumentPath  = [self getDatabaseSavedPath];
    //資料庫存在就先刪除
    if( [fileManager fileExistsAtPath:_dbDocumentPath] )
    {
        [self dropDatabase];
    }
    [fileManager copyItemAtPath:_dbMainBundlePath
                         toPath:_dbDocumentPath
                          error:&error];
}

/*
 * @ 當資料庫不存在時複製 mainBundle 裡的預備資料庫
 *
 *   當 DB 於 Document 裡不存在時，執行此 copyWithoutDatabase 函式，
 *   會自動在 mainBundle 裡搜尋預設的 DB 名稱( DBNAME 與 DBEXT )，
 *   並 Copy 該 DB File 到 Document 底下。
 */
-(void)copyWithoutDatabase
{
    NSError *error;
    //啟動檔案管理員
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath           = [self getDatabaseSavedPath];
    //檢查資料庫是否存在
    BOOL success               = [fileManager fileExistsAtPath:dbPath]; 
	//資料庫檔案不存在
    if( !success )
    {
		//取出存在 APP 裡的預備 DB ( 表單欄位都建好的 DB )
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] 
                                   stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", DBNAME, DBEXT]];
        //將預備 DB 複製到原先設定的 DB 路徑
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        //NSLog(@"已複製預備 DB 到 : %@ \n", dbPath);
		//複製失敗
        if (!success)
        {
            NSAssert1(0, @"複製預備 DB 失敗，Error : %@ \n", [error localizedDescription]);
        }
        error = nil;
    }
    else
    {
        //資料庫存在
        //NSLog(@"找到原先的 DB 在 : %@ \n", dbPath);
    }
}

/*
 * @ 連結資料庫
 *   - DB 不存在時，會重建一個
 */ 
-(int)connectDatabase
{
    if( self.isConnecting == YES )
    {
        return SQLITE_OK;
    }
    /* 
     * @ 連接資料庫並回傳狀態( INT 型態 )
     *   - sqlite3_open 會「同時新建一個資料庫」
     */
    int connectStatus = sqlite3_open([[self getDatabaseSavedPath] UTF8String], &database);
    //資料庫開啟失敗
    if( connectStatus != SQLITE_OK )
    {
        [self closeDatabase];
    }
    else
    {
        //NSLog(@"資料庫連線中 \n");
    }
    return connectStatus;
}

//關閉資料庫
-(void)closeDatabase
{
    sqlite3_close(database);
    self.isConnecting = NO;
}

//刪除資料庫
-(void)dropDatabase
{
    //先檢查 DB 檔案是否存在
    if( [self databaseExists] )
    {
        //宣告檔案管理員
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //刪除檔案
        [fileManager removeItemAtPath:[self getDatabaseSavedPath] error:nil];
    }
    else
    {
        //NSLog(@"無法刪除不存在的 Database \n");
    }
    self.isConnecting = NO;
}

/*
 * @ 執行自帶參數的 SQL 語句
 *
 *   - 新增
 *   - 刪除
 *   - 修改
 *
 * # Sample :
 *
 *   //新增
 *   NSArray *_params     = [NSArray arrayWithObjects:@"Miles", @"28", @"69", nil];
 *   NSString *_sqlString = [NSString stringWithString:@"INSERT INTO t_test (name, age, score) VALUES (?, ?, ?)"];
 *
 *   //刪除
 *   NSArray *_params     = [NSArray arrayWithObjects:@"2", nil];
 *   NSString *_sqlString = [NSString stringWithString:@"DELETE FROM t_test WHERE id=?"];
 *
 *   //修改
 *   NSArray *_params     = [NSArray arrayWithObjects:@"Miles", @"30", @"2", nil];
 *   NSString *_sqlString = [NSString stringWithString:@"UPDATE t_test SET name=?, age=? WHERE id=?"];
 *
 *   [self execQuery:_sqlString sqlParams:params];
 *
 * # 注意事項 :
 *    用 SQLite 來存放中文或其他非英數字串 , 使用 sqlite3_column_text() 取出後是亂碼，解決方法：
 *    取得字串後( 字串不可為空值 )，要用 stringWithUTF8String 的方法轉換成 NSString，
 *    NSString *tmp = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, iCol)];
 */
-(BOOL)execQuery:(NSString *)_sqlString
       sqlParams:(NSArray *)_params
{
    BOOL _done = YES;
    if ( [self connectDatabase] == SQLITE_OK )
    {
        //針對 sqlite3_stmt 建立並記錄要執行的 SQL 語句之物件，以便後續使用
        sqlite3_stmt *statement = nil;
        int success = sqlite3_prepare_v2(database, [_sqlString UTF8String], -1, &statement, NULL);
		if (success != SQLITE_OK)
        {
			//NSLog(@"Error: execQuery 轉換成位元組碼失敗 : %s \n", [_sqlString UTF8String]);
			return NO;
		}
		//绑定参数
		NSInteger max = [_params count];
		for (int i=0; i<max; i++)
        {
			NSString *temp = [_params objectAtIndex:i];
            //如為空字串
            if( [self _stringIsEmpty:temp] )
            {
                //將字串設定預設值後再寫入 DB
                temp = DEFAULT_STRING;
            }
			sqlite3_bind_text(statement, i+1, [temp UTF8String], -1, SQLITE_TRANSIENT);
		}
        //執行經由 sqlite3_prepare_v2() 方法編成位元組碼的 SQL 語句
		success = sqlite3_step(statement);
        sqlite3_finalize(statement);
		[self closeDatabase];
        if (success == SQLITE_ERROR)
        {
			_done = NO;
		}
    }
	return _done;
    
}


/*
 * @ 直接執行 INSERT, UPDATE, DELETE 等等非查詢動作的語法。
 */
-(BOOL)execQuery:(NSString *)_sqlString
{
    BOOL _done = NO;
    if( [self connectDatabase] == SQLITE_OK )
    {
        char *error;
        if ( sqlite3_exec(database, [_sqlString UTF8String], NULL, NULL, &error) == SQLITE_OK)
        {
            /*
             * @ 取得剛才新增資料的 SQL ID
             *   - 跟 PHP 的 insert_id() 一樣
             */
            //int _insertId = sqlite3_last_insert_rowid(database);
            //NSLog(@"insertId : %i", _insertId);
            _done = YES;
        }
        else
        {
            NSLog(@"execQuery error : %s", error);
            _done = NO;
        }
        sqlite3_free(error);
    }
    [self closeDatabase];
    return _done;
}

/*
 * @ 執行 SQL 語句
 *   - _sqlString         : SQL 語句
 *   - _whenFailedToCache : 是否在執行失敗時，存入 Caches 裡
 *     -> 之後可使用 [self stopAndCheckCaches] 進行解析
 *     -> 也可使用 [self getFailedCaches] 取出所有執行失敗的 SQL 語句
 */
-(BOOL)execQuery:(NSString *)_sqlString failedToCache:(BOOL)_whenFailedToCache
{
    BOOL _done = NO;
    if( [self connectDatabase] == SQLITE_OK )
    {
        char *error;
        if ( sqlite3_exec(database, [_sqlString UTF8String], NULL, NULL, &error) == SQLITE_OK)
        {
            _done = YES;
        }
        else
        {
            NSLog(@"execQuery error : %s", error);
            _done = NO;
            if( _whenFailedToCache )
            {
                /*
                 * @ 要在這裡啟動 Cache 模式，把寫入失敗的句子都存至 _failureCaches ( NSMutableArray ) 裡等待處理。
                 */
                if( [[NSString stringWithFormat:@"%s", error] isEqualToString:@"database is locked"] )
                {
                    if( self._failureCaches )
                    {
                        [self._failureCaches addObject:_sqlString];
                    }
                }
            }  
        }
        sqlite3_free(error);
    }
    [self closeDatabase];
    return _done;
}

-(void)rerunFailedCaches
{
    if( [self._failureCaches count] > 0 )
    {
        dispatch_queue_t queue = dispatch_queue_create("_stopAndCheckCachesQueue", NULL);
        dispatch_async(queue, ^(void)
        {
            for( NSString *_sqlQuery in self._failureCaches )
            {
                [self execQuery:_sqlQuery];
            }
            //dispatch_async(dispatch_get_main_queue(), ^(void) {});
        });
    }


//    接續上方的新函式，之後在這裡寫一個 NSTimer，以每秒 50 件的模式，處理 _failureCaches 裡的 SQL 語句，
//    如果處理不成功，又遇到了死結，那就再寫一個 NSTimer，並設定 1 秒後再繼續執行 （ 暫停 1 秒鐘等解鎖 ），
//    而其他情況則以此類推。
    
}

-(NSMutableArray *)getFailedCaches
{
    return self._failureCaches;
}

/*
 * 直接執行 INSERT 後，會回傳 INSERT 的 ID
 */
-(NSString *)execInsertQueryThenReturnId:(NSString *)_sqlString
{
    NSString *_done = nil;
    if( [self connectDatabase] == SQLITE_OK )
    {
        char *error;
        if ( sqlite3_exec(database, [_sqlString UTF8String], NULL, NULL, &error) == SQLITE_OK)
        {
            _done = [NSString stringWithFormat:@"%lld", sqlite3_last_insert_rowid(database)];
        }
        else
        {
            NSLog(@"execInsertQueryThenReturnId error : %s", error);
            _done = nil;
        }
        //[self closeDatabase];
        sqlite3_free(error);
    }
    [self closeDatabase];
    return _done;
}

/*
 * @ 查詢
 *
 * # 參數
 *   _sqlString : SQL 語句
 *   _cols : 限定查詢結果要取得表單裡哪幾個欄位的值
 *
 * # 查詢 Sample : 
 *   1). sqlString = @"SELECT * FROM t_test WHERE score > 0";
 *       [self execSelect:sql resultColumns:4];
 * 
 * # 回傳的陣列裡，第二層陣列為 Dictionary，以欄位名為 Key，欄位值為 Value
 *
 */
-(NSMutableArray *)execSelect:(NSString *)_sqlString 
                resultColumns:(int)_cols
{
	NSMutableArray *_selectResults = [[NSMutableArray alloc] initWithCapacity:0];
    //成功開啟資料庫連線
    if( [self connectDatabase] == SQLITE_OK )
    {
        //SQL 查詢結果存在 sqlite3_stmt 類型裡
        sqlite3_stmt *statement = nil;
        /*
         * @ 準備資料庫
         */
        if ( sqlite3_prepare_v2(database, [_sqlString UTF8String], -1, &statement, NULL) == SQLITE_OK )
        {
            //開始取出資料 : 使用 sqlite3_step( *sqlite3_stmt ) 一次取一筆
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                /*
                 * @ 依 SQL 欄位存放每一筆記錄
                 */
				NSMutableDictionary *_eachRows = [NSMutableDictionary dictionaryWithCapacity:0];
                int _columnCount = _cols;
                //改取得 SQL 欄位總數
                if( _columnCount <= 0 )
                {
                    //以下兩種方法皆可
                    _columnCount = sqlite3_column_count(statement);
                    //_columnCount = sqlite3_data_count(statement);
                }
				//限定取出表單裡的哪幾個欄位的值 ( _cols )
                for( int i=0; i<_columnCount; i++ )
                {
                    //使用目前的 SQL 欄位名稱為 KEY
                    NSString *rowName   = [NSString stringWithFormat:@"%s", sqlite3_column_name(statement, i)];
                    NSString *rowValue  = @"";
                    char *_charRowValue = (char *)sqlite3_column_text(statement, i);
                    if( _charRowValue )
                    {
                        rowValue = [NSString stringWithUTF8String:_charRowValue];
                    }
                    //存入字典陣列
                    [_eachRows setValue:rowValue forKey:rowName];
                }
                //存入回傳陣列
				[_selectResults addObject:_eachRows];
            }
        }
        else
        {
			NSLog(@"Error: failed to prepare");
            _selectResults = nil;
		}
        //釋放記憶體
        sqlite3_finalize(statement);    
    }
    else
    {
        //連線失敗
        //NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));        
    }
    [self closeDatabase];
	return _selectResults;
}

/*
 * @ 直接查詢 ( 推薦使用 )
 */
-(NSMutableArray *)execSelect:(NSString *)_sqlString
{
    return [self execSelect:_sqlString resultColumns:0];
}

/*
 * @ 取得指定查詢的 SQL 語句資料總筆數
 *
 * @ Sample (使用一般查詢語句進行資料筆數的計算) : 
 *
 *   1). _sqlString = @"SELECT * FROM journal";
 *   2). _sqlString = @"SELECT * FROM journal WHERE journal_title LIKE '%Trips%'";
 *   3). _sqlString = @"SELECT * FROm journal WHERE journal_id IN ( SELECT journal_id FROM matchs LIMIT 0, 10 )";
 *
 *   [self getRowsNumbersOfExecSQL:_sqlString];
 */
-(int)getRowsNumbersOfExecSQL:(NSString *)_sqlString
{
    NSMutableArray *_selectResults = [self execSelect:_sqlString resultColumns:1];
    int dataCount = [_selectResults count];
    return ( dataCount > 0 ) ? dataCount : 0;   
}

/*
 * @ 取得指定資料表的資料總筆數
 *
 * @ Sample (使用 Count(*) 函式進行資料筆數的計算) : 
 *
 *   1). _tableName = @"journal";
 *   2). _tableName = @"journal WHERE journal_id > 10";
 *   3). _tableName = @"journal WHERE journal_id IN ( SELECT journal_id FROM matchs LIMIT 0, 10 )";
 *
 *   [self getRowsNumbersOfExecTable:_tableName];
 */
-(int)getRowsNumbersOfExecTable:(NSString *)_tableName
{
    NSString *_sqlString = [NSString stringWithFormat:@"SELECT count(*) AS rows_number FROM %@", _tableName];
    NSMutableArray *_selectResults = [self execSelect:_sqlString resultColumns:1];
    return ( [_selectResults count] > 0 ) ? [[[_selectResults objectAtIndex:0] objectForKey:@"rows_number"] intValue] : 0;
}

/*
 * # 範例 ( 回傳 Dictionary ): 
 *   1). 傳入總筆數 + 現在的分頁數 + ( 預設取 10 筆 ) :
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:0 
 *                                                  andLimitEnd:0];
 *
 *   2). 傳入總筆數 + 現在分頁數 + 取出 8 筆 : 
 *
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:0 
 *                                                  andLimitEnd:8];
 *
 *   3). 傳入總筆數 + 現在分頁數 + 從第 10 筆開始取 + 取出 8 筆: 
 *
 *      NSDictionary *pageDicts = [self calculatePagesWithTotal:100 
 *                                                   andNowPage:1 
 *                                                andLimitStart:10 
 *                                                  andLimitEnd:8];
 *
 * # 參數 : 
 *   _totalPages : 資料總筆數
 *   _nowPage    : 現在分頁數 ( INT )
 *   _start      : SQL 資料開始筆數 ( 從第幾筆開始取, LIMIT_START )
 *   _end        : SQL 資料結束筆數 ( 要取出幾筆, LIMIT_END )
 *
 * # 使用計算後的分頁 Sample : 
 *
 *   。第一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"first"];
 *   。上一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"first"];
 *   。下一頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"next"];
 *   。最後頁 : @"www.test.com/index.php?ls=%@", [pageDicts objectForKey:@"last"];
 *   。跳轉頁 : 
 *      NSDictionary *jumpDicts = [pageDicts objectForKey:@"jumps"];
 *      foreach( NSString *jumpPage in jumpDicts ){
 *        //第 jumpPage 頁 : @"www.test.com/index.php?ls=%@", [jumpDicts objectForKey:jumpPage];
 *      }
 *   。現在頁 : [pageDicts objectForKey:@"nowPage"];
 *
 */
//直接計算分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTotal:(int)_totalPages 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end
{    
    //到第幾筆結束 ?
    int limitEnd    = ( _end < 1 ) ? DEFAULT_LIMIT_END : _end;
    //當前頁數
    int currentPage = ( _nowPage - 1 > 0 ) ? _nowPage - 1 : 0;
    //從第幾筆開始 ?
    int limitStart  = ( _start > 0 ) ? _start : currentPage * limitEnd;
    //總共有幾筆
    int total       = _totalPages;
    //第一頁
    int first       = 0;
    //下一頁
    int next        = ( (limitStart + limitEnd) >= total ) ? limitStart : limitStart + limitEnd;
    //上一頁
    int previous    = ( (limitStart - limitEnd) >= 0 ) ? limitStart - limitEnd : 0;
    //最後一頁
    int last        = ( (floor( (total - 1) / limitEnd ) * limitEnd) >= 0 ) ? floor( (total - 1) / limitEnd ) * limitEnd : 0;
    //現在頁數
    int nowPage     = ceil( limitStart / limitEnd ) + 1;
    //總頁數
    int totalPages  = ceil( total / limitEnd );
    //下一頁的頁數
    int nextPage    = ( nowPage >= totalPages )? totalPages : nowPage + 1;
    //是否還有下一頁 ?
    NSString *hasNext = ( nowPage < totalPages )? @"YES" : @"NO";
    //跳頁 - 陣列型態 : jumpDicts[第幾頁] = 從第幾筆開始
    NSMutableDictionary *jumpDicts = [[NSMutableDictionary alloc] init];
    for( int i=0; i<totalPages; i++ ){
        int jumpStart = ( i == 0 ) ? 0 : i * limitEnd;
        [jumpDicts setValue:[NSString stringWithFormat:@"%i", jumpStart] 
                     forKey:[NSString stringWithFormat:@"%i", (i + 1)]];
    }
    //現在是呈現到第幾筆結束 ?
    int currentEnd  = ( nowPage * limitEnd > total ) ? total : nowPage * limitEnd;
    //現在是從第幾筆開始 ?
    int startNumber = ( limitStart > 0 ) ? limitStart : 0;
    //製作回傳字典陣列
    NSDictionary *pageDicts = [NSDictionary dictionaryWithObjectsAndKeys:
                               //第一頁筆數
                               [NSString stringWithFormat:@"%i", first],       @"first",
                               //下一頁筆數
                               [NSString stringWithFormat:@"%i", next],        @"next", 
                               //上一頁筆數
                               [NSString stringWithFormat:@"%i", previous],    @"previous",
                               //最後一頁筆數
                               [NSString stringWithFormat:@"%i", last],        @"last", 
                               //開始筆數
                               [NSString stringWithFormat:@"%i", startNumber], @"start", 
                               //結束筆數
                               [NSString stringWithFormat:@"%i", limitEnd],    @"end", 
                               //本次是取到第幾筆資料而結束的
                               [NSString stringWithFormat:@"%i", currentEnd],  @"currentEnd", 
                               //現在的分頁數
                               [NSString stringWithFormat:@"%i", nowPage],     @"nowPage", 
                               //下一個分頁數
                               [NSString stringWithFormat:@"%i", nextPage],    @"nextPage", 
                               //總分頁數
                               [NSString stringWithFormat:@"%i", totalPages],  @"totalPages", 
                               //是否還有下一頁 ( STRING : YES : NO )
                               hasNext,   @"hasNext", 
                               //跳頁陣列 : [分頁數] = LIMIT_START
                               jumpDicts, @"jumps", 
                               nil];
    return pageDicts;
}

/*
 * #使用範例同上述 calculatePagesWithTotal:::: 函式，唯一不同處 _tableName 的寫法可為: 
 *
 *   1). 直接傳入資料表名稱 : @"journal";
 *
 *   2). 加入 WHERE 條件式或子查詢 ( 其他緊跟在 FROM 後的 SQL 寫法都行 ) : @"journal WHERE journal_id < 10";
 *
 */
//指定計算資料表分頁 : 總頁數 / 現在頁數 / Limit Start / Limit End
-(NSDictionary *)calculatePagesWithTable:(NSString *)_tableName 
                              andNowPage:(int)_nowPage 
                           andLimitStart:(int)_start 
                             andLimitEnd:(int)_end
{    
    return [self calculatePagesWithTotal:(int)[self getRowsNumbersOfExecTable:_tableName]
                              andNowPage:_nowPage 
                           andLimitStart:_start 
                             andLimitEnd:_end];
}

/*
 * @ 直接執行 SQL 語句
 */
-(void)directExecSQL:(NSString *)_sqlString
{
    char *createErrors;
    if( [self connectDatabase] == SQLITE_OK )
    {
        //如果執行 SQL 失敗
        if( sqlite3_exec(database, [_sqlString UTF8String], NULL, NULL, &createErrors) != SQLITE_OK )
        {
            //[self closeDatabase];
            sqlite3_free(createErrors);
        }
    }
    [self closeDatabase];
}

/*
 * @ 新建資料表
 *
 *   - _tableName : 資料表名稱
 *   - _params    : 欄位與參數
 *
 * @ Sample
 *
 * NSDictionary *_tableParams = [NSDictionary dictionaryWithObjectsAndKeys:
 *                               @"INTEGER PRIMARY KEY AUTOINCREMENT", @"id",
 *                               @"INT(4)", @"bar",
 *                               @"INT(12)", @"comment",
 *                               @"INT(10)", @"user",
 *                               @"INT(8)", @"feeling1",
 *                               @"INT(8)", @"feeling2",
 *                               @"INT(8)", @"feeling3",
 *                               @"FLOAT(8)", @"beauty",
 *                               @"DATETIME DEFAULT CURRENT_TIMESTAMP", @"updatetime",
 *                               nil];
 * //建立資料表
 * [self createTablesWithName:@"evaluation" andParams:_tableParams];
 */
-(void)createTablesWithName:(NSString *)_tableName
                  andParams:(NSDictionary *)_params
{
    char *createErrors;
    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(", _tableName];
    /*
     * @ 取出 _params 裡的
     *   - 欄位名  ( KEY )
     *   - 欄位參數 ( VALUE )
     */
    int i = 0;
    for( NSString *sqlRowName in _params )
    {
        if( i < 1 )
        {
            sqlString = [sqlString stringByAppendingFormat:@"%@ %@", sqlRowName, [_params objectForKey:sqlRowName]];
        }
        else
        {
            sqlString = [sqlString stringByAppendingFormat:@", %@ %@", sqlRowName, [_params objectForKey:sqlRowName]];
        }
        ++i;
    }
    sqlString = [sqlString stringByAppendingString:@" );"];
    //NSLog(@"createTables sqlString : %@ \n", sqlString);
    if( [self connectDatabase] == SQLITE_OK )
    {
        //執行 SQL 語法 : 如果執行失敗
        if( sqlite3_exec(database, [sqlString UTF8String], NULL, NULL, &createErrors) != SQLITE_OK )
        {
            //[self closeDatabase];
            //sqlite3_free(createErrors);
        }
        else
        {
            //NSLog(@"建立 %@ 資料表成功\n", _tableName);
        }
        sqlite3_free(createErrors);
    }
    else
    {
        //NSLog(@"連結資料庫失敗 \n");
    }
    [self closeDatabase];
}

//刪除資料表
-(void)dropTableWithName:(NSString *)_tableName
{
    char *dropErrors;
    //連結資料庫成功
    if( [self connectDatabase] == SQLITE_OK )
    {
        NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", _tableName];
        if( sqlite3_exec(database, [sqlString UTF8String], NULL, NULL, &dropErrors) != SQLITE_OK )
        {
            [self closeDatabase];
            sqlite3_free(dropErrors);
        }
    }
    [self closeDatabase];
}

/*
 * @ 重新命名資料表名稱
 *   - _oldTableName : 舊資料表名稱
 *   - _newTableName : 新資料表名稱
 */
-(void)alterTableWithName:(NSString *)_oldTableName renameTo:(NSString *)_newTableName
{
    char *renameErrors;
    NSString *renameSql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", _oldTableName, _newTableName];
    //連結資料庫成功
    if( [self connectDatabase] == SQLITE_OK )
    {
        if( sqlite3_exec(database, [renameSql UTF8String], NULL, NULL, &renameErrors) != SQLITE_OK )
        {
            //[self closeDatabase];
            sqlite3_free(renameErrors);
        }
    }
    [self closeDatabase];
}

/*
 * @ 增加資料表欄位
 *   - _tableName : 資料表名稱
 *   - _params    : 欄位與參數
 */
-(void)alterTableWithName:(NSString *)_tableName addColumns:(NSDictionary *)_params
{
    //連結資料庫成功
    if( [self connectDatabase] == SQLITE_OK )
    {
        for( NSString *sqlRowName in _params )
        {
            NSString *alterSql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", 
                                  _tableName, 
                                  sqlRowName, 
                                  [_params objectForKey:sqlRowName]];
            //執行 SQL
            sqlite3_exec(database, [alterSql UTF8String], NULL, NULL, NULL);
        }
    }
    //關閉連線
    [self closeDatabase];
}


@end

