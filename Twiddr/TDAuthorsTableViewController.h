//
//  TDAuthorsTableViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAccountChangeDelegate.h"

@class TDAccount;
@class TDUser;


@interface TDAuthorsTableViewController : UITableViewController <UITableViewDataSource, TDAccountChangeDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) TDAccount *account;
@property (strong, nonatomic) NSMutableArray *authors;
@property (strong, nonatomic) NSMutableDictionary *authorTweets;

- (void)syncedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers newUsers:(NSArray *)newUsers deletedUsers:(NSArray *)deletedUsers unchangedUsers:(NSArray *)unchangedUsers;
- (void)syncedTimelineFromApiWithNewTweets:(NSArray *)newTweets affectedUsers:(NSArray *)affectedUsers unassignedTweets:(NSArray *)unassignedTweets;

@end
