//
//  TDAuthorsTableViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDAccount;
@class TDUser;


@interface TDAuthorsTableViewController : UITableViewController <UITableViewDataSource>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) TDAccount *account;
@property (strong, nonatomic) NSMutableArray *authors;
@property (strong, nonatomic) NSMutableDictionary *authorTweets;

- (void)loadMoreAuthor:(NSString *) nextCursor;
- (void)cacheAuthors:(NSArray *) authors;
- (void)loadTimeline;
- (TDUser *)findAuthorById:(NSString *)idStr;

@end
