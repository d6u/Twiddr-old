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


@interface TDAccountTableViewController () {}

@end


@implementation TDAccountTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _accounts = [NSMutableArray arrayWithArray:[TDAccount allAccounts]];
    
    for (TDAccount *account in _accounts) {
        [account initTwitterApi];
        [account validateTwitterAccountAuthorizationWithFinishBlock:^(BOOL valid) {
            if (!valid) {
                // TODO: add notifications
                NSLog(@"--- Twitter account is not valid: %@", account.screen_name);
            }
        }];
        
        [account getFollowingAndTimelineWithFollowingFinishBlock:^(NSArray *following) {
            NSLog(@"following cound %lu", [following count]);
        } timelineFinishBlock:^(NSArray *tweets) {
            NSLog(@"timeline cound %lu", [tweets count]);
        } allFinishBlock:^(NSError *error, NSArray *following) {
            NSLog(@"Finished syncing %@", error);
        }];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated
{
    if ([_accounts count] == 0 && _firstLoadSinceAppLaunch == YES) {
        [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
    }
    _firstLoadSinceAppLaunch = NO;
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
