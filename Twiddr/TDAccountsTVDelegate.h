//
//  TDAccountsTVDelegate.h
//  Twiddr
//
//  Created by Daiwei on 6/15/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDAccount;

@interface TDAccountsTVDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithTableView:(UITableView *)tableView cellConfigBlock:(void(^)(TDAccount *, UITableViewCell*))cellConfigBlock;

- (void)fetchAccountsFollowingAndTimeline:(void(^)())allFinish;
- (TDAccount *)accountAtIndexPath:(NSIndexPath *)indexPath;
- (TDAccount *)accountAtIndex:(NSInteger)index;
- (NSUInteger)countFetchedObject;

@end
