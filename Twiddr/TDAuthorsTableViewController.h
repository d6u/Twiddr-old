//
//  TDAuthorsTableViewController.h
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDTwitterAccount;


@interface TDAuthorsTableViewController : UITableViewController <UITableViewDataSource>

@property (strong, nonatomic) TDTwitterAccount *account;
@property (strong, nonatomic) NSMutableArray *authors;
@property (strong, nonatomic) NSMutableDictionary *authorImages;
@property (strong, nonatomic) NSMutableDictionary *authorTweets;

- (void)loadMoreAuthor:(NSString *)nextCursor;

@end
