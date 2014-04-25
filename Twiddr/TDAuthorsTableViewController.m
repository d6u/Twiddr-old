//
//  TDAuthorsTableViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAuthorsTableViewController.h"
#import <STTwitter/STTwitter.h>
#import "TDTweetsTableViewController.h"
#import "TDAppDelegate.h"
#import "TDUser.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TDTweet.h"
#import "TDSingletonCoreDataManager.h"
#import "TDAccount.h"


@interface TDAuthorsTableViewController ()

@end


@implementation TDAuthorsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _authors = [NSMutableArray arrayWithArray:[_account.following allObjects]];
    for (TDUser *author in _authors) {
        [author loadProfileImageWithCompletionBlock:^(UIImage *image) {
            [self.tableView reloadData];
        }];
    }
    
    [self.tableView reloadData];
    
    [self loadMoreAuthor:nil];
    [self loadTimeline];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_authors count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    TDUser *author = self.authors[indexPath.row];
    
    cell.textLabel.text = author.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", author.screen_name];
    cell.imageView.image = author.profileImage;
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showTweets"]) {
        TDTweetsTableViewController *tweetsViewController = [segue destinationViewController];
        tweetsViewController.managedObjectContext = self.managedObjectContext;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TDUser *author = self.authors[indexPath.row];
        
        tweetsViewController.author = author;
        tweetsViewController.account = _account;
        tweetsViewController.tweets = [NSMutableArray arrayWithArray:[author.statuses allObjects]];
    }
}


# pragma mark - Helpers

- (void)loadMoreAuthor:(NSString *)nextCursor
{
    [_account.twitterApi getFriendsListForUserID:nil
                                    orScreenName:_account.screen_name
                                          cursor:nextCursor
                                           count:@"200"
                                      skipStatus:@(YES)
                             includeUserEntities:@(NO)
                                    successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor)
    {
        if ([users count] != 0) {
            [self cacheAuthors:users];
        }
        if ([users count] == 200) {
            [self loadMoreAuthor:nextCursor];
        }
        if ([users count] < 200) {
            [self.tableView reloadData];
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"--- Error: %@", error);
    }];
}


- (void)cacheAuthors:(NSArray *)authors
{
    NSMutableArray *newAuthors = [[NSMutableArray alloc] init];
    
    for (NSDictionary *author in authors)
    {
        TDUser *oldUser = [self findAuthorById:author[@"id_str"]];
        
        if (oldUser == nil) {
            TDUser *newUser = [TDUser userWithRawDictionary:author];
            [_account addFollowingObject:newUser];
            
            [TDSingletonCoreDataManager saveContext];
            
            [newUser loadProfileImageWithCompletionBlock:^(UIImage *image) {
                [[self tableView] reloadData];
            }];
            
            [newAuthors addObject:newUser];
        } else {
            BOOL profileImageUpdated = NO;
            
            if (![oldUser.profile_image_url isEqualToString:author[@"profile_image_url"]]) {
                profileImageUpdated = YES;
            }
            
            [oldUser setValuesForKeysWithRawDictionary:author];
            
            if (profileImageUpdated) {
                if ([oldUser isDownloadingProfileImage]) {
                    [oldUser cancelProfileImageDownloadOperation];
                }
                [oldUser loadProfileImageWithCompletionBlock:^(UIImage *image) {
                    [[self tableView] reloadData];
                }];
            }
            
            [TDSingletonCoreDataManager saveContext];
        }
    }
    
    [_authors addObjectsFromArray:newAuthors];
    [[self tableView] reloadData];
}


- (void)loadTimeline
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastSinceId = [defaults objectForKey:@"lastSinceId"];
    
    [self loadTimelineSinceID:lastSinceId maxID:nil recursive:YES successBlock:^(NSArray *statuses)
    {
        if (statuses) {
            
            NSDictionary *status = [statuses firstObject];
            if (status) {
                [defaults setObject:status[@"id_str"] forKey:@"lastSinceId"];
                [defaults synchronize];
            }
            
            for (NSDictionary *tweet in statuses) {
                
                TDTweet *newTweet = [TDTweet tweetWithRawDictionary:tweet];
                
                for (TDUser *user in self.authors) {
                    if ([user.id_str isEqualToString:tweet[@"user"][@"id_str"]]) {
                        [user addStatusesObject:newTweet];
                        break;
                    }
                }
            }
            
            [TDSingletonCoreDataManager saveContext];
        }
        
        [self sortAuthorByUnreadTweetsCount];
        
        [self.tableView reloadData];
    }];
}


- (void)loadTimelineSinceID:(NSString *)sinceID maxID:(NSString *)maxID recursive:(BOOL)recursive
               successBlock:(void (^)(NSArray *statuses))successBlock
{
    __block NSMutableArray *allStatuses;
    __block NSString *maxIdStr = maxID;
    
    static void(^next)();
    next = ^void() {
        [_account.twitterApi getStatusesHomeTimelineWithCount:@"200"
                                                      sinceID:sinceID
                                                        maxID:maxID
                                                     trimUser:@(NO)
                                               excludeReplies:@(NO)
                                           contributorDetails:@(NO)
                                              includeEntities:@(YES)
                                                 successBlock:^(NSArray *statuses)
        {
            if (allStatuses == nil) {
                allStatuses = [[NSMutableArray alloc] init];
            }
            
            [allStatuses addObjectsFromArray:statuses];
            
            if (recursive && sinceID != nil && [statuses count] != 0) {
                NSDictionary *lastStatus = [statuses lastObject];
                maxIdStr = [self idStrMinusOne:lastStatus[@"id_str"]];
                next();
            } else {
                successBlock(allStatuses);
            }
        } errorBlock:^(NSError *error) {
            NSLog(@"--- Error: %@", error);
            successBlock(allStatuses);
        }];
    };
    
    next();
}


- (NSString *)idStrMinusOne:(NSString *)idStr
{
    unsigned long long idNum = [idStr longLongValue];
    idNum--;
    return [NSString stringWithFormat:@"%llu", idNum];
}


- (void)sortAuthorByUnreadTweetsCount
{
    NSArray *sortedArray;
    
    sortedArray = [_authors sortedArrayUsingComparator:^NSComparisonResult(TDUser *a, TDUser *b) {
        unsigned long first = [[a statuses] count];
        unsigned long second = [[b statuses] count];
        if (first > second) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    _authors = [NSMutableArray arrayWithArray:sortedArray];
}


- (TDUser *)findAuthorById:(NSString *)idStr
{
    TDUser *target;
    for (TDUser *user in _authors) {
        if ([user.id_str isEqual:idStr]) {
            target = user;
            break;
        }
    }
    return target;
}


@end
