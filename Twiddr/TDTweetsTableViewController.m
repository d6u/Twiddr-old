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
#import "TDTweetCell.h"


@interface TDTweetsTableViewController ()

@end


@implementation TDTweetsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"TDTweetCell" bundle:nil]
         forCellReuseIdentifier:@"Cell"];

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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDTweet *tweet = self.tweets[indexPath.row];
    return [TDTweetCell heightForTweetText:tweet];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    TDTweetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    TDTweet *tweet = self.tweets[indexPath.row];

    if (tweet.retweeted_status != nil) {
        cell.tweetText.text = tweet.retweeted_status[@"text"];
    } else {
        cell.tweetText.text = tweet.text;
    }

//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", tweet.created_at];

    return cell;
}


//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    CGSize maxSize = CGSizeMake(280, MAXFLOAT);
//    TDTweet *tweet = _tweets[indexPath.row];
//    
//    NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:17]
//                                                                 forKey:NSFontAttributeName];
//    
//    CGRect labelRect = [tweet.text boundingRectWithSize:maxSize
//                                                options:NSStringDrawingUsesLineFragmentOrigin
//                                             attributes:stringAttributes
//                                                context:nil];
//    
//    NSLog(@"size %@", NSStringFromCGSize(labelRect.size));
//    
//    return labelRect.size.height + 25;
//}


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
