//
//  TDTimelineGap.h
//  Twiddr
//
//  Created by Daiwei Lu on 4/28/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TDAccount;


@interface TDTimelineGap : NSManagedObject

@property (nonatomic, retain) NSString * max_id_str;
@property (nonatomic, retain) NSString * since_id_str;

@property (nonatomic, retain) TDAccount *account;

@end
