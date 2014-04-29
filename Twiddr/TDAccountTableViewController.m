//
//  TDMasterViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDAccountTableViewController.h"
#import "TDDetailViewController.h"
#import "TDTwitterAuthViewController.h"
#import <STTwitter/STTwitter.h>
#import "TDAuthorsTableViewController.h"
#import "Constants.h"
#import "TDAccount.h"
#import "TDUser.h"


@interface TDAccountTableViewController () {}

@end


@implementation TDAccountTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    
    _accounts = [NSMutableArray arrayWithArray:[TDAccount allAccounts]];
    
    for (TDAccount *account in _accounts) {
        [account initTwitterApi];
        
        [account performGetAccountSettingsWithFinishBlock:^(NSError *error, NSDictionary *settings) {
            if (error) {
                // TODO: invalidate account
            }
        }];
        
        [account pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
            
        }];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (TDAccount *account in _accounts) {
        [account registerSyncDelegate:self];
    }
    
    [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated
{
    if ([_accounts count] == 0 && _firstLoadSinceAppLaunch == YES) {
        [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
    }
    _firstLoadSinceAppLaunch = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
    for (TDAccount *account in _accounts) {
        [account deregisterSyncDelegate:self];
    }
}


#pragma mark - UIRefreshControl

- (void)pullToRefresh:(id)sender
{
    __block NSUInteger refreshFinished = 0;
    for (int i = 0; i < [_accounts count]; i++) {
        [_accounts[i] pullFollowingAndTimelineWithFinishBlock:^(NSError *error) {
            refreshFinished |= (1 << i);
            if (refreshFinished == (pow(2, [_accounts count]) - 1)) {
                [(UIRefreshControl *)sender endRefreshing];
            }
        }];
    }
}


#pragma mark - TDAccountChangeDelegate

- (void)mergedTimelineFromApiWithNewTweets:(NSArray *)newTweets
{
    [self.tableView reloadData];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_accounts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TDAccount *account = _accounts[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"@%@", account.screen_name];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", [account.timeline_tweets count]];
    
    return cell;
}


#pragma mark - Table View delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


#pragma mark - UIViewController with StoreBoard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showTwitterAuth"]) {
        TDTwitterAuthViewController *authViewController = segue.destinationViewController;
        authViewController.accountTableViewController = self;
    }
    else if ([segue.identifier isEqualToString:@"showAuthors"]) {
        TDAuthorsTableViewController *authorViewController = segue.destinationViewController;
        authorViewController.managedObjectContext = self.managedObjectContext;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        authorViewController.account = _accounts[indexPath.row];
    }
}


#pragma mark - IBActions

- (IBAction)addAccount:(id)sender
{
    [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
}


@end
