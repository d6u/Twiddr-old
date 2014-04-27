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
    
    [_account registerSyncDelegate:self];
    
    [_account syncAccountWithFinishBlock:^(NSError *error) {
        NSLog(@"TDAccountTableViewController syncAccountWithFinishBlock %@", error);
    }];
    
    _authors = [NSMutableArray arrayWithArray:[_account.following allObjects]];
    
    for (TDUser *author in _authors) {
        [author loadProfileImageWithCompletionBlock:^(UIImage *image) {
            [self.tableView reloadData];
        }];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [self sortAuthorByUnreadTweetsCount];
    [self.tableView reloadData];
}


#pragma mark - TDAccountSyncDelegate

- (void)syncedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers
                                      newUsers:(NSArray *)newUsers
                                  deletedUsers:(NSArray *)deletedUsers
                                unchangedUsers:(NSArray *)unchangedUsers
{
    NSLog(@"Author View syncedFollowingFromApiWithUpdatedUsers");
    [self.tableView reloadData];
}


- (void)syncedTimelineFromApiWithNewTweets:(NSArray *)newTweets
                             affectedUsers:(NSArray *)affectedUsers
                          unassignedTweets:(NSArray *)unassignedTweets
{
    NSLog(@"Author View syncedTimelineFromApiWithNewTweets");
    [self sortAuthorByUnreadTweetsCount];
    [self.tableView reloadData];
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


@end
