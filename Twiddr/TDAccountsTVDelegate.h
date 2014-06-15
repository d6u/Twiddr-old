//
//  TDAccountsTVDelegate.h
//  Twiddr
//
//  Created by Daiwei on 6/15/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDAccount;

@interface TDAccountsTVDelegate : NSObject <UITableViewDataSource>

- (void)fetchAccountsFollowingAndTimeline:(void(^)())allFinish;
- (TDAccount *)accountAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)countFetchedObject;

@end
