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
#import "TDAuthorTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface TDAuthorsTableViewController ()

@end


@implementation TDAuthorsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TDAuthorTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"Cell"];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];

    _authors = [NSMutableArray arrayWithArray:[_account.following allObjects]];
    
    for (TDUser *author in _authors) {
        [author loadProfileImageWithCompletionBlock:^(UIImage *image) {
            [self.tableView reloadData];
        }];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self sortAuthorByUnreadTweetsCount];
    [_account registerSyncDelegate:self];
    
    [self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_account deregisterSyncDelegate:self];
}


#pragma mark - UIRefreshControl

- (void)pullToRefresh:(id)sender
{
    [_account pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
        [_account assignOrphanTweetsToAuthorWithFinishBlock:^(NSArray *unassginedTweets, NSArray *affectedUsers) {
            [(UIRefreshControl *)sender endRefreshing];
        }];
    }];
}


#pragma mark - TDAccountSyncDelegate

- (void)syncedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers
                                      newUsers:(NSArray *)newUsers
                                  deletedUsers:(NSArray *)deletedUsers
                                unchangedUsers:(NSArray *)unchangedUsers
{
    _authors = [NSMutableArray arrayWithArray:[_account.following allObjects]];
    [self.tableView reloadData];
}


- (void)syncedTimelineFromApiWithNewTweets:(NSArray *)newTweets
                             affectedUsers:(NSArray *)affectedUsers
                          unassignedTweets:(NSArray *)unassignedTweets
{
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


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showTweets" sender:self];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDAuthorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    TDUser *author = self.authors[indexPath.row];
    
    cell.imageView.image = author.profileImage;
    [cell.imageView.layer setMasksToBounds:YES];
    [cell.imageView.layer setCornerRadius:8.0];
    cell.Title.text = author.name;
    cell.Detail.text = [NSString stringWithFormat:@"@%@", author.screen_name];
    cell.count.text = [NSString stringWithFormat:@"%lu", [author.statuses count]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
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
        } else if (first < second) {
            return NSOrderedDescending;
        } else {
            return [((TDUser *)a).screen_name compare:((TDUser *)b).screen_name];
        }
    }];
    
    _authors = [NSMutableArray arrayWithArray:sortedArray];
}


@end
