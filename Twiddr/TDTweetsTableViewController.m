//
//  TDTweetsTableViewController.m
//  Twidder-proto
//
//  Created by Daiwei Lu on 3/22/14.
//  Copyright (c) 2014 Daiwei Lu. All rights reserved.
//

#import "TDTweetsTableViewController.h"
#import "TDTwitterAccount.h"
#import "TDUser.h"


@interface TDTweetsTableViewController ()

@end


@implementation TDTweetsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = self.author.name;
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
    
    NSDictionary *tweet = self.tweets[indexPath.row];
    
    cell.textLabel.text = tweet[@"text"];
    cell.detailTextLabel.text = tweet[@"created_at"];
    
    return cell;
}


@end
