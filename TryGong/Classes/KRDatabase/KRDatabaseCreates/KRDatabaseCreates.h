//
//  KRDatabaseCreates.h
//  
//
//  Created by Kalvar on 13/1/5.
//  Copyright (c) 2013年 Kuo-Ming Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KRDatabase;

@interface KRDatabaseCreates : NSObject

@property (nonatomic, strong) KRDatabase *krDatabase;

-(void)createWithDefaultTables;

@end
