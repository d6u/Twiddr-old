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
#import "TDTwitterAccount.h"
#import "TDAuthorsTableViewController.h"
#import <SSKeychain/SSKeychain.h>
#import "Constants.h"


@interface TDAccountTableViewController () {}

@end


@implementation TDAccountTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.twitterAccounts = [[NSMutableArray alloc] init];
    
    NSArray *accounts = [SSKeychain accountsForService:@"TwiddrOauthTokenService"];
    if (accounts) {
        for (NSDictionary *account in accounts) {
            NSString *screenName = account[@"acct"];
            NSString *oauthToken = [SSKeychain passwordForService:@"TwiddrOauthTokenService" account:screenName];
            NSString *oauthTokenSecret = [SSKeychain passwordForService:@"TwiddrTokenSecretService" account:screenName];
            
            if (oauthToken && oauthTokenSecret) {
                STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWAPIKey
                                                                      consumerSecret:TWAPISecret
                                                                          oauthToken:oauthToken
                                                                    oauthTokenSecret:oauthTokenSecret];
                [twitter getAccountSettingsWithSuccessBlock:^(NSDictionary *settings) {
                    TDTwitterAccount *twitterAccount = [TDTwitterAccount accountWithTwitter:twitter];
                    twitterAccount.accountSetting = settings;
                    twitterAccount.screenName = settings[@"screen_name"];
                    [self.twitterAccounts addObject:twitterAccount];
                    [self.tableView reloadData];
                } errorBlock:^(NSError *error) {
                    NSLog(@"-- error: %@", error);
                }];
            }
        }
    } else {
        if ([self.twitterAccounts count] == 0) {
            [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
        }
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.twitterAccounts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TDTwitterAccount *twitterAccount = self.twitterAccounts[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"@%@", twitterAccount.screenName];
    return cell;
}


#pragma mark - Table View delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showTwitterAuth"]) {
        TDTwitterAuthViewController *authViewController = segue.destinationViewController;
        authViewController.accountTableViewController = self;
    }
    else if ([segue.identifier isEqualToString:@"showAuthors"]) {
        TDAuthorsTableViewController *authorViewController = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        authorViewController.account = self.twitterAccounts[indexPath.row];
    }
}





#pragma mark - IBActions

- (IBAction)addAccount:(id)sender
{
    [self performSegueWithIdentifier:@"showTwitterAuth" sender:self];
}


@end
