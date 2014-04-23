//
//  TDAuthorsTableViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAuthorsTableViewController.h"
#import "TDTwitterAccount.h"
#import <STTwitter/STTwitter.h>
#import "TDTweetsTableViewController.h"
#import "TDAppDelegate.h"
#import "TDUser.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TDTweet.h"
#import "TDSingletonCoreDataManager.h"


@interface TDAuthorsTableViewController ()

@end


@implementation TDAuthorsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.authors = [NSMutableArray arrayWithArray:[self fetchCachedAuthors]];
    self.authorTweets = [[NSMutableDictionary alloc] init];
    
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
    return [self.authors count];
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
        tweetsViewController.account = self.account;
        NSLog(@"status cound %lu", [author.statuses count]);
        tweetsViewController.tweets = [NSMutableArray arrayWithArray:[author.statuses allObjects]];
    }
}


# pragma mark - Helpers

- (NSArray *)fetchCachedAuthors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObject = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"-- ERROR: %@", error);
    }
    
    for (TDUser *author in fetchedObject) {
        [author loadProfileImageWithCompletionBlock:^(UIImage *image) {
            [[self tableView] reloadData];
        }];
    }
    
    return [NSArray arrayWithArray:fetchedObject];
}


- (void)loadMoreAuthor:(NSString *)nextCursor
{
    [self.account.twitterApi getFriendsListForUserID:nil
                                        orScreenName:self.account.screenName
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
    
    [self.authors addObjectsFromArray:newAuthors];
    [[self tableView] reloadData];
}


- (void)loadTimeline
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastSinceId = [defaults objectForKey:@"lastSinceId"];
    NSLog(@"lastSinceId %@", lastSinceId);
    
    [self loadTimelineSinceID:lastSinceId maxID:nil recursive:YES successBlock:^(NSArray *statuses)
    {
        NSLog(@"statuses %lu", [statuses count]);
        
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
        [self.account.twitterApi getStatusesHomeTimelineWithCount:@"200"
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
    
    sortedArray = [self.authors sortedArrayUsingComparator:^NSComparisonResult(TDUser *a, TDUser *b) {
        unsigned long first = [[a statuses] count];
        unsigned long second = [[b statuses] count];
        if (first > second) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    self.authors = [NSMutableArray arrayWithArray:sortedArray];
}


- (TDUser *)findAuthorById:(NSString *)idStr
{
    TDUser *target;
    for (TDUser *user in self.authors) {
        if ([user.id_str isEqual:idStr]) {
            target = user;
            break;
        }
    }
    return target;
}


@end
