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

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) TDTwitterAccount *account;
@property (strong, nonatomic) NSMutableArray *authors;
@property (strong, nonatomic) NSMutableDictionary *authorImages;
@property (strong, nonatomic) NSMutableDictionary *authorTweets;

- (void)fetchCachedAuthors;
- (void)loadMoreAuthor:(NSString *) nextCursor;
- (void)cacheAuthors:(NSArray *) authors;
- (void)downloadImageFromUrlString:(NSString *)urlString forScreenName:(NSString *)screenName;
- (NSDictionary *)transformAuthorDictToUserDict:(NSDictionary *) author;

@end
