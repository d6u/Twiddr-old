//
//  TDTweetsTableViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTweetsTableViewController.h"
#import "TDAccount.h"
#import "TDUser.h"
#import "TDTweet.h"


@interface TDTweetsTableViewController ()

@end


@implementation TDTweetsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    
    _tweets = [NSMutableArray arrayWithArray:[_author.statuses allObjects]];
    [self sortTweetsByDate];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_account registerSyncDelegate:self];
    
    self.navigationItem.title = self.author.name;
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
        [(UIRefreshControl *)sender endRefreshing];
    }];
}


#pragma mark - TDAccountSyncDelegate

- (void)syncedFollowingFromApiWithUpdatedUsers:(NSArray *)updatedUsers
                                      newUsers:(NSArray *)newUsers
                                  deletedUsers:(NSArray *)deletedUsers
                                unchangedUsers:(NSArray *)unchangedUsers
{
    [self sortTweetsByDate];
    [self.tableView reloadData];
}


- (void)syncedTimelineFromApiWithNewTweets:(NSArray *)newTweets
                             affectedUsers:(NSArray *)affectedUsers
                          unassignedTweets:(NSArray *)unassignedTweets
{
    _tweets = [NSMutableArray arrayWithArray:[_author.statuses allObjects]];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tweets count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    TDTweet *tweet = self.tweets[indexPath.row];
    
    cell.textLabel.text = tweet.text;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", tweet.created_at];
    
    return cell;
}


#pragma mark - Helper

- (void)sortTweetsByDate
{
    NSArray *sortedArray;
    
    sortedArray = [_tweets sortedArrayUsingComparator:^NSComparisonResult(TDTweet *a, TDTweet *b) {
        return [b.created_at compare:a.created_at];
    }];
    
    _tweets = [NSMutableArray arrayWithArray:sortedArray];
}


@end
