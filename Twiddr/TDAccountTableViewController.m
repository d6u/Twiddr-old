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
#import "TDAccountsTVDelegate.h"


@interface TDAccountTableViewController ()

@property (nonatomic, strong) TDAccountsTVDelegate *tableViewDelegate;

@end


@implementation TDAccountTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];

    _tableViewDelegate = [[TDAccountsTVDelegate alloc] initWithTableView:self.tableView
                                                         cellConfigBlock:^(TDAccount *account, UITableViewCell *cell)
    {
        cell.textLabel.text = [NSString stringWithFormat:@"@%@", account.screen_name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[account.timeline_tweets count]];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([_tableViewDelegate countFetchedObject] == 0 && _firstLoadSinceAppLaunch == YES) {
        [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
    }
    _firstLoadSinceAppLaunch = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


#pragma mark - UIRefreshControl

- (void)pullToRefresh:(id)sender
{
    [_tableViewDelegate fetchAccountsFollowingAndTimeline:^{
        [(UIRefreshControl *)sender endRefreshing];
    }];
}


#pragma mark - TDAccountChangeDelegate

- (void)mergedTimelineFromApiWithNewTweets:(NSArray *)newTweets
{
    [self.tableView reloadData];
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
        authorViewController.account = [_tableViewDelegate accountAtIndexPath:[self.tableView indexPathForSelectedRow]];
    }
}


#pragma mark - IBActions

- (IBAction)addAccount:(id)sender
{
    [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
}


@end
