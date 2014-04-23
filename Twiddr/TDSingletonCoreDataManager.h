//
//  TDManagedContext.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;


@interface TDSingletonCoreDataManager : NSObject

+ (instancetype)sharedCoreDataManager;
+ (NSManagedObjectContext *)getManagedObjectContext;
+ (void)saveContext;

@end
